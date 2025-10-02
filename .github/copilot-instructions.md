# Copilot instructions for Doable

These instructions are for automated coding agents (Copilot/Coding agent) to be immediately productive in the Doable iOS SwiftUI app.

- Big picture

  - Doable is a small SwiftUI iOS app that uses SwiftData for local persistence. Key folders:
    - `Models/` — domain models (see `Models/Todo.swift` which uses `@Model`).
    - `Views/` — all UI and much of the app logic (e.g. `Views/FullscreenTimerView.swift`).
    - `Utilities/` — small helpers such as `DisappointmentStrings.swift` for localized messages.
    - `Ressources/` — asset catalogs and localization (`en.lproj`, `de.lproj`).

- Persistence and app entry

  - `DoableApp.swift` constructs a single shared `ModelContainer` (SwiftData) at app startup and injects it via `.modelContainer(sharedModelContainer)` into the scene.
  - Editing models changes the schema; the app currently fails fast on container creation errors. If modifying models, either keep schema-compatible changes or plan to reset persisted data / add migration logic.

- Concrete code patterns (examples to follow)

  - `@Model` for persistable types; `@Bindable` for binding model instances in views (`Models/Todo.swift`, `Views/TodoView.swift`).
  - Use `@Environment(.modelContext)` to access the SwiftData context and call `modelContext.delete(_:)` to remove objects (see `TodoView`'s delete-on-empty logic).
  - `FullscreenTimerView.swift` implements orientation-driven lifecycle and a 15s portrait "grace" period. Key helpers to preserve if changing behavior: `beginObservingOrientation`, `handleOrientationChange`, `startPortraitGrace`, `handlePortraitGraceExpired`.
  - Localization uses `LocalizedStringKey` and strings files under `en.lproj`/`de.lproj`. Helpers like `Utilities/DisappointmentStrings.swift` return `LocalizedStringKey` values for views.

- Developer workflows

  - Preferred iteration: open `Doable.xcodeproj` in Xcode and run on simulator or device. Deleting the app on the simulator resets SwiftData storage.
  - For scripted builds use `xcodebuild` with the app scheme. Most UI behaviors (orientation, haptics) require device/simulator testing.

- Conventions and style

  - PascalCase for types and components; camelCase for vars/functions; ALL_CAPS for constants.
  - The project keeps view-centric logic in SwiftUI views. If extracting business logic, prefer `Utilities/` or `ViewModels/` and keep changes minimal.

- Integration points and cautions

  - No external dependencies. Uses system frameworks: SwiftUI, SwiftData, UIKit orientation APIs, AudioToolbox (haptics/vibration).
  - Asset names in `Ressources/Assets.xcassets` are referenced by name in code and are sensitive to renames.

- Files to inspect when making changes
  - `DoableApp.swift` — app bootstrap and model container
  - `Models/Todo.swift` — model definition
  - `Views/TodoView.swift` — binding and delete-on-empty behavior
  - `Views/FullscreenTimerView.swift` — orientation and timer lifecycle
  - `Utilities/DisappointmentStrings.swift` — timer cancelation messages
