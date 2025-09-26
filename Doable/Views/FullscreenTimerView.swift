import SwiftUI
import Combine
import UIKit
import AudioToolbox

/// Fullscreen timer view that asks the user to rotate device into landscape to start the timer.
/// When the countdown completes it asks user to rotate back to portrait to confirm completion.
struct FullscreenTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let todo: Todo
    let totalSeconds: Int
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation
    @State private var remainingSeconds: Int
    @State private var timerActive: Bool = false
    @State private var timerFinished: Bool = false
    @State private var timerCancellable: AnyCancellable? = nil
    @State private var didComplete: Bool = false
    @State private var didPlaySuccess: Bool = false
    @State private var disappointed: Bool = false
    @State private var disappointedMessageKey: LocalizedStringKey = DisappointmentText.randomMessageKey()
    // micro-interaction states
    @State private var isPausedMicrostate: Bool = false
    @State private var showDoneBloom: Bool = false
    

    init(todo: Todo, totalSeconds: Int, onComplete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.todo = todo
        self.totalSeconds = totalSeconds
        self.onComplete = onComplete
        self.onCancel = onCancel
        _remainingSeconds = State(initialValue: totalSeconds)
    }

    var body: some View {
        ZStack {
            // If disappointed, show a dedicated fullscreen disappointment view and nothing else.
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

                    if !timerActive && !timerFinished {
                        VStack(spacing: 12) {
                            Text("Rotate your device")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("Please rotate into landscape to start the timer")
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
                                if isPausedMicrostate {
                                    Text("Paused — rotate to resume")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                        .transition(.opacity)
                                } else {
                                    Text("Keep in landscape to continue")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            } else {
                                Text("Timer finished — rotate back to portrait to complete the task")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    } else if timerFinished {
                        VStack(spacing: 12) {
                            Text("Done!")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                Text("Rotate back to portrait to mark the task as completed")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                            ZStack {
                                Image(systemName: "checkmark.seal")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundStyle(.green)

                                if showDoneBloom {
                                    Circle()
                                        .stroke(Color.green.opacity(0.6), lineWidth: 6)
                                        .frame(width: 160, height: 160)
                                        .scaleEffect(showDoneBloom ? 1.0 : 0.4)
                                        .opacity(showDoneBloom ? 1.0 : 0.0)
                                        .animation(.easeOut(duration: 0.6), value: showDoneBloom)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Buttons removed per request. Keep spacing at bottom.
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
                    // Do NOT call onCancel here — we want to keep the view presented so that
                    // when the user returns from background we can show the disappointment overlay.
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

    private func beginObservingOrientation() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
            orientation = UIDevice.current.orientation
            handleOrientationChange()
        }
        orientation = UIDevice.current.orientation
        handleOrientationChange()
    }

    private func stopObservingOrientation() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    private func handleOrientationChange() {
        // If we're showing the disappointed fullscreen, ignore orientation changes
        if disappointed { return }
        if !timerActive && !timerFinished {
            // start when user rotates to landscape
            if orientation.isLandscape {
                startTimer()
            }
        } else if timerActive {
            // if user rotates back to portrait while timer is active, pause or stop. Here we choose to pause the timer until landscape is regained.
            if !orientation.isLandscape {
                // pause the timer
                pauseTimer()
            } else {
                // resume
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
        // Haptic and vibration
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        // Accessibility announcement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            UIAccessibility.post(notification: .announcement, argument: "Timer started")
        }
        // simple timer publisher
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
                        // Play vibration once
                        if !didPlaySuccess {
                            playVibration()
                            // done bloom and announcement
                            showDoneBloom = true
                            UIAccessibility.post(notification: .announcement, argument: "Timer finished")
                        }
                }
            }
    }

    // MARK: - Vibration only

    private func playVibration() {
        didPlaySuccess = true
        // Haptic feedback (friendly notification)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        // Trigger a system vibration fallback
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    private func pauseTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        timerActive = false
        // show pause microstate
        withAnimation(.easeInOut(duration: 0.18)) {
            isPausedMicrostate = true
        }
        UIAccessibility.post(notification: .announcement, argument: "Timer paused")
    }

    private func resumeTimer() {
        if disappointed { return }
        guard !timerActive && !timerFinished && remainingSeconds > 0 else { return }
        timerActive = true
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
        UIAccessibility.post(notification: .announcement, argument: "Timer resumed")
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
        DispatchQueue.main.async {
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.error)
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
