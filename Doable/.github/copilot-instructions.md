## Doable — Copilot instructions for AI coding agents

These are concise, actionable rules for editing this SwiftUI + SwiftData app so changes are consistent with the project's architecture and patterns.

- Big picture

  - Single-window SwiftUI app. Entry point: `DoableApp.swift` which creates a shared `ModelContainer` and injects it via `.modelContainer(...)` into the root view.
  - Root UI: `ContentView.swift`. It queries `Todo` objects with `@Query` and mutates them via `@Environment(.modelContext)`.
  - Model: `Models/Todo.swift` is a SwiftData `@Model` class. Persisted state is simple (title, createdAt, isCompleted, completedAt).
  - Timer flow: completion is a two-step UI flow — a sheet (`TimerSetupSheet`) then a `fullScreenCover` (`FullscreenTimerView`) driven from `ContentView` state. Preserve this sequence if you touch completion logic.

- Key patterns an agent must follow

  - Use SwiftData access patterns already in use: read via `@Query`, mutate via `@Environment(\.modelContext)` (insert/delete) and update model properties directly on bound models (`@Bindable var todo: Todo`).
  - The shared `ModelContainer` is created once in `DoableApp`. Do not replace that with ad-hoc containers in other files; instead, rely on the injected `modelContext` and `@Query` in views.
  - Localization: strings use `Localizable.strings` files (many `*.lproj/` directories). Prefer `LocalizedStringKey` in views and `NSLocalizedString` where a String is required (the code already uses both).
  - Empty-todo cleanup: `TodoView` deletes model objects when the text field loses focus and the title is empty. Maintain this UX when changing the text lifecycle.
  - Prefill suggestions: `TodoView` uses `NewTodoNames.randomNameKey()` and an unusual Mirror-based extraction to resolve `LocalizedStringKey` to a String when `AppStorage("settings.prefillSuggestions")` is enabled. If altering suggestion behaviour, keep this pattern or replace it project-wide and update `Utilities/NewTodoNames.swift` accordingly.
  - The localization files are ordered by sections. If you add new keys, place them in the appropriate section to keep the *.lproj files organized.

- Examples (copy/paste safe) you can reference

  - Create/insert a todo:
    - `let newTodo = Todo(title: ""); modelContext.insert(newTodo)` — see `ContentView.addTodo()`.
  - Query todos:
    - `@Query private var todos: [Todo]` — see `ContentView` top-level properties.
  - Model declaration:
    - `@Model final class Todo { var title: String; var isCompleted: Bool; ... }` — see `Models/Todo.swift`.

- Developer workflows and runtime notes

  - Open in Xcode to run and debug UI flows. This is a SwiftUI app reliant on SwiftData; use an Xcode version that supports SwiftData for the target platform.
  - No unit tests present in the repo. Use the running app to smoke-test UI-driven behaviors (timer flow, undo snackbar, empty-todo deletion).
  - To debug persistence, set breakpoints in `DoableApp.swift` (container creation) and `ContentView` (insert/delete/completion handlers).

- Conventions and gotchas

  - Keep localized keys intact. Changing keys requires updating all `*.lproj/Localizable.strings` files.
  - Adding new localized strings: add keys to `Utilities/NewTodoNames.swift` if they are prefill suggestions; otherwise, add them to `Localizable.strings` files in all `*.lproj/` directories.
  - The undo snackbar logic is implemented in `ContentView` with `lastDeletedTodo` / `lastCompletedTodo` and a `Combine` cancellable timer. Preserve the lastAction semantics if you refactor snackbar behavior.
  - Views are light and often mutate models directly (no heavy view-model layer yet). If you add ViewModels, place them in `ViewModels/` and keep `@Environment(\.modelContext)` usage consistent.

- Where to make changes

  - UI: `Views/` (add new SwiftUI views here). Example files: `TodoView.swift`, `FullscreenTimerView.swift`, `OnboardingView.swift`.
  - Models: `Models/` (SwiftData `@Model` classes).
  - Utilities: `Utilities/` for shared helpers like `DisappointmentStrings.swift` and `NewTodoNames.swift`.
  - Localization: `*.lproj/Localizable.strings` files for localized strings.

- If you touch data model shape
  - SwiftData migrations: changing stored properties can require migration; avoid renaming/removing model properties without understanding migration implications. If you must change models, prefer additive changes and test the app run.
  - Data loss: deleting model properties or changing types can lead to data loss. Avoid these unless you handle migration properly.