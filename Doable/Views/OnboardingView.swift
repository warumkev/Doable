import SwiftUI

struct OnboardingSlide: Identifiable {
	let id = UUID()
	let titleKey: LocalizedStringKey
	let descKey: LocalizedStringKey
}

struct OnboardingView: View {
	@Environment(\.dismiss) private var dismiss
	@State private var selection: Int = 0

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
                    Text("Doable")
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
                        Text("\(index + 1)/\(slides.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
						Text(slide.titleKey)
							.font(.title)
							.fontWeight(.semibold)
							.multilineTextAlignment(.center)
							.padding(.horizontal)

						Text(slide.descKey)
							.foregroundStyle(.secondary)
							.multilineTextAlignment(.center)
							.padding(.horizontal)

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
						Text("onboarding.next")
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
						Text("onboarding.letsgo")
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

