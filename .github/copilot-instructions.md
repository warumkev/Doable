# Copilot instructions for Doable (merged & focused)

This small SwiftUI app uses SwiftData for local persistence and keeps most app logic inside views. The goal of this doc is to give an AI coding agent the minimal, actionable context required to make correct, low-risk changes.

- Big picture

  - Doable is a single-window SwiftUI iOS app. Data flows: UI views ⇄ SwiftData `ModelContainer` (shared via `.modelContainer(...)`) ⇄ `@Model` objects (see `Models/Todo.swift`).
  - Most business logic lives in views (see `Views/FullscreenTimerView.swift`); prefer small, local edits unless you extract a helper into `Utilities/` or `ViewModels/`.

- Persistence and schema cautions

  - `DoableApp.swift` creates the app-wide `ModelContainer`. Changing `@Model` types alters the schema and will fail at startup in development; either keep compatibility, add migrations, or accept resetting simulator data.

- Key patterns to preserve

  - Use `@Model` and `@Bindable` for persisted types and bindings (example: `Models/Todo.swift`, `Views/TodoView.swift`).
  - Use `@Environment(\.modelContext)` for inserts/deletes. `TodoView` removes empty todos on blur — preserve that UX if you refactor.
  - `FullscreenTimerView` is orientation-driven and relies on observers and timers. If modifying, keep helpers: `beginObservingOrientation`, `handleOrientationChange`, `startPortraitGrace`, `handlePortraitGraceExpired`.

- Localization and assets

  - Strings live under `en.lproj` and `de.lproj` and UI uses `LocalizedStringKey`. Prefer adding keys to these files when introducing text.
  - Asset names (in `Ressources/Assets.xcassets`) are referenced literally (e.g., `Image("doableLogo")`). Avoid renaming assets without updating code.

- Build & run notes (developer workflows)

  - Preferred: open `Doable.xcodeproj` in Xcode and run on Simulator/device (UI behaviors like orientation and haptics require simulator/device).
  - Scripted: `xcodebuild -scheme Doable -workspace Doable.xcworkspace` (or open Xcode project). Deleting the app from simulator resets SwiftData storage.

- Conventions

  - PascalCase for types, camelCase for vars/functions, ALL_CAPS for constants.
  - Keep view-centric logic in `Views/`. Small reusable helpers go into `Utilities/`.

- Files to inspect first (quick checklist)

  - `DoableApp.swift` — model container & onboarding presentation
  - `Models/Todo.swift` — persisted data shape
  - `Views/TodoView.swift` — text binding and delete-on-empty logic
  - `Views/FullscreenTimerView.swift` — orientation + timer lifecycle (sensitive behavior)
  - `Utilities/DisappointmentStrings.swift` — localized message helpers
  - `en.lproj/Localizable.strings` & `de.lproj/Localizable.strings` — add keys here when changing text

- Safety checklist before changing behavior
  - If you change `@Model` definitions, document migration or reset instructions; run the app in simulator and delete the app to test a fresh schema.
  - When changing timer/orientation code, test on device/simulator (portrait/landscape) and ensure the 15s portrait grace behavior remains consistent.

If anything here is unclear or you want more examples (e.g., a small change walkthrough), tell me which area to expand and I will iterate.
