//
//  DoableApp.swift
//  Doable
//
//  Created by Kevin Tamme on 26.09.25.
//

import SwiftUI
import SwiftData

// App entry point for the Doable application.
// Responsibilities:
// - Construct the shared SwiftData ModelContainer for persisting `Todo` objects.
// - Provide the root SwiftUI view (`ContentView`) and inject the model container.
@main
struct DoableApp: App {
    // Create a shared ModelContainer once and reuse it for the entire app.
    // The container is configured with the `Todo` model so the app can store todo items.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Todo.self,
        ])
        // Persisted on disk by default (not in-memory).
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Fail fast during development if the container can't be created.
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        // The main window shows ContentView and inherits the model container so
        // child views can access the SwiftData context via @Environment(\.modelContext).
        WindowGroup {
            ContentView()
                // Inject the model container as before
                .modelContainer(sharedModelContainer)
                // Present onboarding on first launch using AppStorage flag
                .fullScreenCover(isPresented: Binding(get: {
                    !hasSeenOnboarding
                }, set: { newValue in
                    // When the cover is dismissed (set false) mark onboarding seen.
                    if !newValue {
                        hasSeenOnboarding = true
                    }
                })) {
                    OnboardingView()
                }
        }
        // modelContainer already set on the ContentView above
    }
}
