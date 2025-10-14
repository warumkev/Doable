import SwiftUI
import UserNotifications

struct OnboardingSlide: Identifiable {
	let id = UUID()
	let titleKey: LocalizedStringKey
	let descKey: LocalizedStringKey
}

struct OnboardingView: View {
	@Environment(\.dismiss) private var dismiss
	@State private var selection: Int = 0

    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled: Bool = true

	@AppStorage("settings.iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = false // opt-in
	@AppStorage("settings.notificationsEnabled") private var notificationsEnabled: Bool = false
	@AppStorage("settings.hasAskedNotificationPermission") private var hasAskedNotificationPermission: Bool = false

	private let slides: [OnboardingSlide] = [
		OnboardingSlide(titleKey: "onboarding.welcome.title", descKey: "onboarding.welcome.desc"),
		OnboardingSlide(titleKey: "onboarding.setup.title", descKey: "onboarding.setup.desc"),
		OnboardingSlide(titleKey: "onboarding.notifications.title", descKey: "onboarding.notifications.desc"),
		OnboardingSlide(titleKey: "onboarding.icloud.title", descKey: "onboarding.icloud.desc"),
		OnboardingSlide(titleKey: "onboarding.ready.title", descKey: "onboarding.ready.desc")
	]

	var body: some View {
		VStack {

		TabView(selection: $selection) {
					ForEach(slides.indices, id: \ .self) { index in
						VStack(spacing: 16) {
							Spacer()

							if index == 0 {
								Image("doableLogo")
									.renderingMode(.template)
									.resizable()
									.scaledToFit()
									.frame(width: 120, height: 120)
									.foregroundColor(Color.primary)
									.padding(.bottom, 16)
							}

							Text(slides[index].titleKey)
								.font(.largeTitle)
								.fontWeight(.bold)
								.multilineTextAlignment(.center)
								.padding(.horizontal)

							Text(slides[index].descKey)
								.font(.body)
								.foregroundStyle(.secondary)
								.multilineTextAlignment(.center)
								.padding(.horizontal)

							if index == 2 {
								Toggle(isOn: $notificationsEnabled) {
									Text(LocalizedStringKey("settings.push_notifications"))
										.font(.headline)
								}
								.padding(.horizontal)
								.onChange(of: notificationsEnabled) { _, newValue in
									if newValue {
										if !hasAskedNotificationPermission {
											NotificationPermissionManager.requestNotificationPermission { granted in
												notificationsEnabled = granted
												hasAskedNotificationPermission = true
											}
										}
									} else {
										notificationsEnabled = false
									}
								}
							}

							if index == 3 {
								Toggle(isOn: $iCloudSyncEnabled) {
									Text(LocalizedStringKey("settings.iCloud_sync"))
										.font(.headline)
								}
								.padding(.horizontal)
							}

							Spacer()
						}
						.tag(index)
					}
				}
				.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

				// Page indicator
				HStack(spacing: 8) {
					ForEach(0..<slides.count, id: \ .self) { idx in
						Circle()
							.frame(width: 8, height: 8)
							.foregroundColor(idx == selection ? Color.primary : Color(UIColor.tertiaryLabel))
							.scaleEffect(idx == selection ? 1.1 : 1.0)
							.animation(.easeInOut(duration: 0.18), value: selection)
					}
				}
				.padding(.top, 8)

				// Navigation
				HStack {
					Spacer()

					if selection < slides.count - 1 {
						Button(action: {
							withAnimation {
								selection += 1
							}
							if hapticsEnabled {
								let generator = UIImpactFeedbackGenerator(style: .medium)
								generator.impactOccurred()
							}
						}) {
							Text(LocalizedStringKey("onboarding.next"))
								.frame(minWidth: 100)
						}
						.buttonStyle(.borderedProminent)
						.tint(Color.primary)
						.foregroundColor(Color(UIColor.systemBackground))
						.padding()
					} else {
						Button(action: {
							dismiss()
							if hapticsEnabled {
								let generator = UIImpactFeedbackGenerator(style: .medium)
								generator.impactOccurred()
							}
						}) {
							Text(LocalizedStringKey("onboarding.letsgo"))
								.frame(minWidth: 120)
						}
						.buttonStyle(.borderedProminent)
						.tint(Color.primary)
						.foregroundColor(Color(UIColor.systemBackground))
						.padding()
					}
				}
		}
		.background(Color(UIColor.systemBackground))
		.ignoresSafeArea(edges: .bottom)
	}
}

struct OnboardingView_Previews: PreviewProvider {
	static var previews: some View {
		OnboardingView()
	}
}

