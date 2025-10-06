import SwiftUI
import Combine
import UIKit
import AudioToolbox

/// Fullscreen timer view that drives the timed completion experience for a `Todo`.
///
/// UX summary:
/// - The user chooses a duration from a sheet (parent view). This view is shown full-screen.
/// - The user is asked to rotate the device to landscape to start the timer.
/// - If the user rotates to portrait while the timer is running, a 15s grace period begins.
///   If they return to landscape within the grace period, the timer resumes; otherwise the timer
///   is cancelled and a light-hearted "disappointment" overlay is shown.
/// - When the countdown reaches zero, the view plays a success haptic/animation and waits for the
///   user to rotate back to portrait to confirm completion; once portrait is detected the `onComplete`
///   callback is invoked.
struct FullscreenTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    // The todo we're timing and the completion/cancellation callbacks the parent provides.
    let todo: Todo
    let onComplete: () -> Void
    let onCancel: () -> Void

    // MARK: - State
    // Track the current device orientation and various timer-related flags.
    @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation
    @State private var timerActive = false
    @State private var timerFinished = false
    @State private var disappointed = false
    @State private var remainingSeconds: Int = 0
    @State private var totalSeconds: Int = 0

    // Portrait grace handling: when the user temporarily rotates to portrait we give them
    // a short window to return to landscape before cancelling the timer.
    @State private var portraitGraceRemaining: Int = 15
    @State private var portraitGraceCancellable: AnyCancellable? = nil
    private let portraitGraceDuration: Int = 15

    // Micro interaction flags used to control small UI states/animations
    @State private var isPausedMicrostate: Bool = false
    @State private var showDoneBloom: Bool = false
    @State private var pausedDueToPortrait: Bool = false

    // Timer publishers/cancellables
    @State private var timerCancellable: AnyCancellable? = nil

    // Track that we've already signaled success haptics so they are only played once
    @State private var didPlaySuccess: Bool = false
    @State private var didComplete: Bool = false

    // Respect user preferences for haptics and sounds
    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("settings.soundEnabled") private var soundEnabled: Bool = true

    // Selected random disappointment message key for the overlay
    @State private var disappointedMessageKey: LocalizedStringKey = DisappointmentText.randomMessageKey()

    // Keep an observer token so we can unregister when the view disappears
    @State private var orientationObserverToken: NSObjectProtocol? = nil

    init(todo: Todo, totalSeconds: Int, onComplete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.todo = todo
        self.totalSeconds = totalSeconds
        self.onComplete = onComplete
        self.onCancel = onCancel
        _remainingSeconds = State(initialValue: totalSeconds)
    }

    var body: some View {
        ZStack {
            // If the user abandoned the running timer, show a dedicated 'disappointment' overlay.
            if disappointed {
                DisappointmentView(
                    title: DisappointmentText.titleKey,
                    message: disappointedMessageKey,
                    buttonTitle: DisappointmentText.okButtonKey,
                    onConfirm: {
                        onCancel()
                        dismiss()
                    }
                )
                .zIndex(3)
                .transition(.opacity)
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // Different UI states depending on the timer/orientation
                    if pausedDueToPortrait {
                        // Paused state while in portrait and the portrait-grace countdown is active
                        VStack(spacing: 12) {
                            Text(todo.title)
                                .font(.title)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            ZStack {
                                Text(timeString(from: remainingSeconds))
                                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .padding(.top, 8)
                            }

                            if remainingSeconds > 0 {
                                Text(LocalizedStringKey("timer.paused.rotate_to_resume"))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                if portraitGraceRemaining > 0 {
                                    Text(String(format: NSLocalizedString("timer.paused.resume_in_seconds", comment: "Resume in %ds"), portraitGraceRemaining))
                                        .environment(\.locale, .current)
                                        .foregroundStyle(.secondary)
                                        .font(.caption2)
                                        .monospacedDigit()
                                        .padding(.top, 2)
                                        .accessibilityLabel(Text(String(format: NSLocalizedString("accessibility.timer.resume_in_seconds", comment: "Resume timer in %d seconds"), portraitGraceRemaining)))
                                }
                            } else {
                                Text(LocalizedStringKey("timer.finished.rotate_to_confirm"))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    } else if !timerActive && !timerFinished {
                        // Initial instruction screen asking the user to rotate to landscape to start
                        VStack(spacing: 12) {
                            Text(LocalizedStringKey("timer.instructions.rotate_device"))
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(LocalizedStringKey("timer.instructions.rotate_to_landscape"))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Image(systemName: "iphone.landscape")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundStyle(.secondary)
                        }
                    } else if timerActive {
                        // Active countdown
                        VStack(spacing: 12) {
                            VStack {
                                HStack(spacing: 40) {
                                    // Left: Timer label and time
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text(todo.title)
                                            .font(.title3)
                                            .foregroundStyle(.secondary)
                                        Text(timeString(from: remainingSeconds))
                                            .font(.system(size: 80, weight: .bold, design: .monospaced))
                                            .foregroundStyle(.primary)
                                        Button(action: {
                                            // Stop timer and cancel
                                            stopTimerIfNeeded()
                                            disappointedMessageKey = DisappointmentText.randomMessageKey()
                                            disappointed = true
                                        }) {
                                            Text(LocalizedStringKey("timer.controls.stop"))
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 48)
                                                .padding(.vertical, 16)
                                                .background(Color(.systemGray3))
                                                .cornerRadius(18)
                                        }
                                        .padding(.top, 16)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    // Right: Circular progress and pause icon
                                    ZStack {
                                        // Background circle
                                        Circle()
                                            .fill(Color(.systemGray6))
                                            .frame(width: 200, height: 200)

                                        // Remaining progress ring (animates smoothly)
                                        Circle()
                                            .trim(
                                                from: 0,
                                                to: totalSeconds > 0
                                                    ? CGFloat(max(0.0, min(1.0, Double(max(0, remainingSeconds)) / Double(totalSeconds))))
                                                    : 0
                                            )
                                            .stroke(Color(.gray), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                                            .rotationEffect(.degrees(-90))
                                            .frame(width: 200, height: 200)
                                            .animation(.linear(duration: 1), value: remainingSeconds - 1)

                                        // Pause icon
                                        Circle()
                                            .fill(Color(.black))
                                            .frame(width: 90, height: 90)
                                        HStack(spacing: 16) {
                                            Image(systemName: "music.note")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 48, height: 48)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(width: 200, height: 200)
                                }
                                .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .alignmentGuide(HorizontalAlignment.center) { d in d[HorizontalAlignment.center] }

                            if remainingSeconds >= 0 {
                                if isPausedMicrostate {
                                    Text(LocalizedStringKey("timer.paused.rotate_to_resume"))
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                        .transition(.opacity)
                                    // Show the portrait-grace countdown while paused
                                    if portraitGraceRemaining > 0 {
                                        Text(String(format: NSLocalizedString("timer.paused.resume_in_seconds", comment: "Resume in %ds"), portraitGraceRemaining))
                                            .environment(\.locale, .current)
                                            .foregroundStyle(.secondary)
                                            .font(.caption2)
                                            .monospacedDigit()
                                            .transition(.opacity)
                                            .padding(.top, 2)
                                            .accessibilityLabel(Text(String(format: NSLocalizedString("accessibility.timer.resume_in_seconds", comment: "Resume timer in %d seconds"), portraitGraceRemaining)))
                                    }
                                }
                            } else {
                                    Text(LocalizedStringKey("timer.finished.rotate_to_confirm"))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    } else if timerFinished {
                        // Finished: show celebratory state while waiting for portrait rotation to confirm
                        VStack(spacing: 12) {
                            HStack(alignment: .center, spacing: 40) {
                                // Left column: Task info and confirm
                                VStack(alignment: .leading, spacing: 20) {
                                    Text(todo.title)
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                    Text(LocalizedStringKey("finished.completed"))
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundStyle(.green)
                                    Text(LocalizedStringKey("finished.rotate_or_confirm"))
                                    .foregroundStyle(.secondary)
                                    Button(action: {
                                        // Confirm completion (rotate to portrait also triggers)
                                        didComplete = true
                                        onComplete()
                                        dismiss()
                                    }) {
                                        Text(LocalizedStringKey("finished.confirm"))
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 48)
                                            .padding(.vertical, 16)
                                            .background(Color.green)
                                            .cornerRadius(18)
                                    }
                                    .padding(.top, 8)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                // Right column: Circular ring, checkmark, bloom, confetti
                                ZStack {
                                    // Background circle
                                    Circle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 200, height: 200)

                                    // Filled progress ring in green
                                    Circle()
                                        .trim(from: 0, to: 1)
                                        .stroke(Color.green, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                        .frame(width: 200, height: 200)
                                        .animation(.linear(duration: 0.8), value: timerFinished)

                                    // Centered checkmark
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 90, height: 90)
                                    Image(systemName: "checkmark")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 48, height: 48)
                                        .foregroundColor(.white)

                                    // Bloom animation
                                    if showDoneBloom {
                                        Circle()
                                            .stroke(Color.green.opacity(0.6), lineWidth: 8)
                                            .frame(width: 160, height: 160)
                                            .scaleEffect(showDoneBloom ? 1.0 : 0.4)
                                            .opacity(showDoneBloom ? 1.0 : 0.0)
                                            .animation(.easeOut(duration: 0.6), value: showDoneBloom)
                                    }
                                }
                                .frame(width: 200, height: 200)
                            }
                            .padding(.horizontal, 32)
                        }
                    }

                    Spacer()

                    // Keep bottom spacing consistent
                    Color.clear
                        .frame(height: 24)
                        .padding(.bottom, 24)
                }
                .onAppear {
                    beginObservingOrientation()
                    // If we are already in landscape, start immediately
                    startTimerIfLandscape()
                }
                .onDisappear {
                    stopObservingOrientation()
                    stopTimerIfNeeded()
                    // Do NOT call onCancel here — the dismissal/cancellation is handled explicitly
                    // from the disappointment overlay or other flows.
                }

                // Confetti overlay when finished (above content)
                if timerFinished {
                    ConfettiView(active: true)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)
                        .allowsHitTesting(false)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                appDidLeaveWhileRunning()
            }
        }
    }

    // MARK: - Orientation observation

    /// Start listening for device orientation notifications and handle the initial state.
    private func beginObservingOrientation() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        // Keep the observer token so we can remove it later.
        orientationObserverToken = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
            orientation = UIDevice.current.orientation
            handleOrientationChange()
        }
        orientation = UIDevice.current.orientation
        handleOrientationChange()
    }

    /// Stop observing device orientation notifications and clean up.
    private func stopObservingOrientation() {
        if let token = orientationObserverToken {
            NotificationCenter.default.removeObserver(token)
            orientationObserverToken = nil
        }
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    /// Core orientation handling logic. Decides when to start, pause, resume, finish or cancel the timer
    /// based on the current `orientation` and internal state.
    private func handleOrientationChange() {
        // If we're showing the disappointed fullscreen, ignore orientation changes
        if disappointed { return }
        if !timerActive && !timerFinished {
            // start when user rotates to landscape
            if orientation.isLandscape {
                // If the timer had already started and was paused, resume it instead of resetting.
                if remainingSeconds < totalSeconds && remainingSeconds > 0 {
                    // Cancel the portrait grace if it's running before resuming.
                    cancelPortraitGrace()
                    resumeTimer()
                } else {
                    startTimer()
                }
            }
        } else if timerActive {
            if !orientation.isLandscape {
                // Entered portrait while active -> start the 15s grace countdown.
                pauseTimer() // pause the main countdown
                startPortraitGrace()
            } else {
                // Returned to landscape while active -> cancel grace (if any) and resume main timer
                cancelPortraitGrace()
                resumeTimer()
            }
        } else if timerFinished {
            // when finished, wait for portrait to call completion
            if orientation.isPortrait {
                stopTimerIfNeeded()
                didComplete = true
                onComplete()
                dismiss()
            }
        }
    }

    // MARK: - Portrait grace helpers
    private func startPortraitGrace() {
        cancelPortraitGrace()
        portraitGraceRemaining = portraitGraceDuration
        // mark paused UI state
        pausedDueToPortrait = true
        // Start a simple 1s-tick publisher that decrements the remaining grace seconds.
        portraitGraceCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                portraitGraceTick()
            }
    }

    private func cancelPortraitGrace() {
        portraitGraceCancellable?.cancel()
        portraitGraceCancellable = nil
        portraitGraceRemaining = portraitGraceDuration
        // clear paused UI
        pausedDueToPortrait = false
    }

    private func portraitGraceTick() {
        guard portraitGraceRemaining > 0 else {
            portraitGraceCancellable?.cancel()
            portraitGraceCancellable = nil
            portraitGraceRemaining = 0
            handlePortraitGraceExpired()
            return
        }
        portraitGraceRemaining -= 1
        // If you have a small UI showing the countdown, update it here.
    }

    private func handlePortraitGraceExpired() {
        // The user did not return to landscape within the grace window.
        // Cancel the running timer and show disappointment.
        stopTimerIfNeeded()
        disappointed = true
        // Clear paused UI state
        pausedDueToPortrait = false
        // Optionally mark timerFinished to prevent normal completion flow.
        timerFinished = false
        timerActive = false
        // If you need to perform any onCancel callbacks, do it here.
    }

    // MARK: - Timer control

    private func startTimerIfLandscape() {
        if disappointed { return }
        if UIDevice.current.orientation.isLandscape {
            startTimer()
        }
    }

    private func startTimer() {
        guard !timerActive && !timerFinished && totalSeconds > 0 else { return }
        timerActive = true
        remainingSeconds = totalSeconds
        // Micro-interaction: play a soft haptic to confirm start
        // Haptic and vibration (respect user settings)
        if hapticsEnabled {
            let gen = UINotificationFeedbackGenerator()
            gen.prepare()
            gen.notificationOccurred(.success)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        // Accessibility announcement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let s = NSLocalizedString("accessibility.timer.started", comment: "Timer started")
            UIAccessibility.post(notification: .announcement, argument: s)
        }
        // simple timer publisher
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if remainingSeconds >= 0 {
                    remainingSeconds -= 1
                }
                if remainingSeconds < 0 {
                    timerFinished = true
                    timerActive = false
                    stopTimerIfNeeded()
                    // Play vibration once
                    if !didPlaySuccess {
                        playVibration()
                        // done bloom and announcement
                        showDoneBloom = true
                        let s = NSLocalizedString("accessibility.timer.finished", comment: "Timer finished")
                        UIAccessibility.post(notification: .announcement, argument: s)
                    }
                }
            }
    }

    // MARK: - Vibration only

    private func playVibration() {
        didPlaySuccess = true
        // Haptic feedback (friendly notification) — respect user setting
        if hapticsEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)

            // Trigger a system vibration fallback
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    private func pauseTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        timerActive = false
        // indicate that we're paused due to portrait rotation
        pausedDueToPortrait = true
        // show pause microstate
        withAnimation(.easeInOut(duration: 0.18)) {
            isPausedMicrostate = true
        }
    let s = NSLocalizedString("accessibility.timer.paused", comment: "Timer paused")
    UIAccessibility.post(notification: .announcement, argument: s)
    }

    private func resumeTimer() {
        if disappointed { return }
        guard !timerActive && !timerFinished && remainingSeconds > 0 else { return }
        // Defensive: stop any portrait-grace timer so it cannot fire after we resume.
        cancelPortraitGrace()
        timerActive = true
        // clear paused UI state
        pausedDueToPortrait = false
        // clear pause microstate
        withAnimation(.easeInOut(duration: 0.18)) {
            isPausedMicrostate = false
        }
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                }
                if remainingSeconds <= 0 {
                    timerFinished = true
                    timerActive = false
                    stopTimerIfNeeded()
                }
            }
        // announce resume
    let s = NSLocalizedString("accessibility.timer.resumed", comment: "Timer resumed")
    UIAccessibility.post(notification: .announcement, argument: s)
    }

    private func stopTimerIfNeeded() {
        timerCancellable?.cancel()
        timerCancellable = nil
        timerActive = false
    }

    // MARK: - App lifecycle / cancellation

    private func appDidLeaveWhileRunning() {
        // Cancel if the timer was started (either actively running, or already decremented at least once)
        // and it hasn't finished or been completed yet.
        let timerWasStarted = timerActive || remainingSeconds < totalSeconds
        guard timerWasStarted && !timerFinished && !didComplete else { return }

        // Stop timer work
        stopTimerIfNeeded()
        timerActive = false

    // Pick a random funny message key and show the disappointment view
    disappointedMessageKey = DisappointmentText.randomMessageKey()
    disappointed = true

        // subtle error haptic
        if hapticsEnabled {
            DispatchQueue.main.async {
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.error)
            }
        }
    }

    // MARK: - Utilities

    private func timeString(from seconds: Int) -> String {
        let s = max(0, seconds)
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }
}

#Preview {
    // Create a lightweight preview with a dummy Todo
    let t = Todo(title: "Preview Task")
    FullscreenTimerView(todo: t, totalSeconds: 10, onComplete: {}, onCancel: {})
}

// MARK: - Confetti UIViewRepresentable

struct ConfettiView: UIViewRepresentable {
    var active: Bool = true

    func makeUIView(context: Context) -> UIView {
        let view = ConfettiContainerView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false

        let emitter = CAEmitterLayer()
        emitter.emitterShape = .line

        var cells: [CAEmitterCell] = []
        let colors: [UIColor] = [
            .systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemYellow
        ]

        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 6
            cell.lifetime = 6.0
            cell.lifetimeRange = 1.0
            cell.velocity = 200
            cell.velocityRange = 80
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 3
            cell.spinRange = 4
            cell.scale = 0.2
            cell.scaleRange = 0.02
            cell.color = color.cgColor
            cell.contents = makeConfettiImage(color: color)?.cgImage
            cells.append(cell)
        }

        emitter.emitterCells = cells
        emitter.beginTime = CACurrentMediaTime()
        view.emitter = emitter
        view.layer.addSublayer(emitter)

        // Stop emitting after a short burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            emitter.birthRate = 0
        }

        // Remove emitter after particles die out
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            emitter.removeFromSuperlayer()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // no-op; emitter is self-contained
    }

    private func makeConfettiImage(color: UIColor) -> UIImage? {
        let size = CGSize(width: 10, height: 14)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        ctx.setFillColor(color.cgColor)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 2)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
}

/// UIView that updates the emitter's size/position when attached to a window to avoid using UIScreen.main
private final class ConfettiContainerView: UIView {
    var emitter: CAEmitterLayer?

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard let emitter = emitter else { return }

        // Determine width from the view's window scene screen when available, otherwise use view bounds
        var width: CGFloat = bounds.width
        if let win = window {
            // Prefer the window's bounds when available
            width = win.bounds.width
        }
        if width == 0 {
            // Final safe default if we couldn't determine size yet
            width = 375.0
        }

        emitter.emitterSize = CGSize(width: width, height: 2)
        // Position emitter slightly above the top of the view
        emitter.emitterPosition = CGPoint(x: width / 2.0, y: -10)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let emitter = emitter else { return }
        let width = bounds.width
        if width > 0 {
            emitter.emitterSize = CGSize(width: width, height: 2)
            emitter.emitterPosition = CGPoint(x: width / 2.0, y: -10)
        }
    }
}
