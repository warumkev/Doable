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

	@AppStorage("settings.iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = false // opt-in
	@AppStorage("settings.notificationsEnabled") private var notificationsEnabled: Bool = false
	@AppStorage("settings.hasAskedNotificationPermission") private var hasAskedNotificationPermission: Bool = false

	private let slides: [OnboardingSlide] = [
		OnboardingSlide(titleKey: "onboarding.chooseTodo.title", descKey: "onboarding.chooseTodo.desc"),
		OnboardingSlide(titleKey: "onboarding.setTimer.title", descKey: "onboarding.setTimer.desc"),
		OnboardingSlide(titleKey: "onboarding.keepRunning.title", descKey: "onboarding.keepRunning.desc"),
		OnboardingSlide(titleKey: "onboarding.final.title", descKey: "onboarding.final.desc"),
	]

	var body: some View {
		VStack {
			HStack {
                VStack {
                    ZStack {
                        Image("doableLogo")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 48)
                            .foregroundColor(.primary)
                    }
					Text(LocalizedStringKey("app.title"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    HStack(spacing: 14) {
                        // Statistics / settings buttons are currently commented out.
                    }
                    Divider()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
				}

			}

		TabView(selection: $selection) {
					ForEach(Array(slides.enumerated()), id: \.element.id) { pair in
						let index = pair.offset
						let slide = pair.element

					VStack(spacing: 20) {
						Spacer()
						Text(String(format: NSLocalizedString("onboarding.progress", comment: "Progress indicator"), index + 1, slides.count))
							.environment(\.locale, .current)
							.font(.caption)
							.foregroundStyle(.secondary)
						Text(slide.titleKey)
							.font(.title)
							.fontWeight(.semibold)
							.multilineTextAlignment(.center)
							.padding(.horizontal)

						Text(slide.descKey)
							.foregroundStyle(.secondary)
							.frame(maxWidth: .infinity, alignment: .leading)
							.lineLimit(nil)
							.fixedSize(horizontal: false, vertical: true)
							.multilineTextAlignment(.leading)
							.padding(.horizontal)

						// On last slide, show toggles for Cloud Sync and Notifications
						if index == slides.count - 1 {
							Spacer()
							VStack(spacing: 16) {
								Toggle(isOn: $iCloudSyncEnabled) {
									Text(LocalizedStringKey("settings.iCloud_sync"))
								}
								.padding(.horizontal)
								Text(LocalizedStringKey("settings.iCloud_sync_desc"))
									.font(.caption)
									.foregroundColor(.secondary)
									.frame(maxWidth: .infinity, alignment: .leading)
									.lineLimit(nil)
									.fixedSize(horizontal: false, vertical: true)
									.multilineTextAlignment(.leading)
									.padding(.horizontal)

								Toggle(isOn: $notificationsEnabled) {
									Text(LocalizedStringKey("settings.push_notifications"))
								}
								.padding(.horizontal)
								.onChange(of: notificationsEnabled) { _, newValue in
									if newValue && !hasAskedNotificationPermission {
										// Request permission only if not already asked
										UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
											DispatchQueue.main.async {
												notificationsEnabled = granted
												hasAskedNotificationPermission = true
											}
										}
									}
								}
								Text(LocalizedStringKey("settings.push_notifications_open_settings"))
									.font(.caption)
									.foregroundColor(.secondary)
									.frame(maxWidth: .infinity, alignment: .leading)
									.lineLimit(nil)
									.fixedSize(horizontal: false, vertical: true)
									.multilineTextAlignment(.leading)
									.padding(.horizontal)
							}
						}
						Spacer()
					}
					.tag(index)
				}
			}
			.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

			// Page indicator
			HStack(spacing: 8) {
				ForEach(0..<slides.count, id: \.self) { idx in
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

