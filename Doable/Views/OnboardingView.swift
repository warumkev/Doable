//
//  OnboardingView.swift
//  Doable
//
//  Created by automated assistant on 02.10.25.
//

import SwiftUI

/// A small, self-contained onboarding flow presented as a fullscreen cover on first launch.
/// - Persists a `hasSeenOnboarding` flag using `AppStorage` so the flow only appears once.
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selection: Int = 0

    private struct Page {
        let title: LocalizedStringKey
        let description: LocalizedStringKey
        let imageName: String?
    }

    // Use the images the user added to Assets.xcassets. One image was missing; for that page
    // we pass `nil` so the view will render the system placeholder illustration.
    private let pages: [Page] = [
        Page(title: "onboarding.chooseTodo.title", description: "onboarding.chooseTodo.desc", imageName: "list-view"),
        Page(title: "onboarding.setTimer.title", description: "onboarding.setTimer.desc", imageName: "set-timer"),
        Page(title: "onboarding.keepRunning.title", description: "onboarding.keepRunning.desc", imageName: "timer-running-landscape"),
    Page(title: "onboarding.final.title", description: "onboarding.final.desc", imageName: "timer-sad"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(action: { skip() }) {
                    Text("onboarding.skip")
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 20)
            }

            TabView(selection: $selection) {
                ForEach(pages.indices, id: \.self) { idx in
                    pageView(for: pages[idx])
                        .tag(idx)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .animation(.easeInOut, value: selection)

            HStack {
                Spacer()
                Button(action: nextTapped) {
                    Text(selection == pages.count - 1 ? "onboarding.letsgo" : "onboarding.next")
                        .bold()
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .padding(.top, 10)
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }

    private func pageView(for page: Page) -> some View {
        // Compute the UIImage once outside of the ViewBuilder to avoid loops/mutations inside
        // the view builder closure (which is not allowed).
        let foundUIImage: UIImage? = {
            guard let name = page.imageName else { return nil }
            if let ui = UIImage(named: name) { return ui }
            if let ui = UIImage(named: "\(name).png") { return ui }
            if let ui = UIImage(named: "\(name).PNG") { return ui }
            return nil
        }()

        return VStack(spacing: 18) {
            Spacer()

            if let ui = foundUIImage {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
            } else if let name = page.imageName {
                // Fall back to SwiftUI asset lookup by asset name
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
            } else {
                // Lightweight placeholder illustration
                Image(systemName: "sparkles")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.accentColor)
            }

            Text(page.title)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    private func nextTapped() {
        if selection < pages.count - 1 {
            selection += 1
        } else {
            finish()
        }
    }

    private func skip() {
        finish()
    }

    private func finish() {
        // Persist flag. The presenting view observes this AppStorage key and will dismiss.
        hasSeenOnboarding = true
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
#endif
