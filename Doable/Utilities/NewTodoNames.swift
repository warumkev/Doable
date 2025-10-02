import Foundation
import SwiftUI

/// Utility that provides localized keys for suggested default Todo names.
/// Mirrors the style used by `DisappointmentText` so views can use the
/// `LocalizedStringKey` values directly.
struct NewTodoNames {
    // A small collection of friendly starter todo keys.
    private static let nameKeys: [LocalizedStringKey] = [
        LocalizedStringKey("todo.default.1"),
        LocalizedStringKey("todo.default.2"),
        LocalizedStringKey("todo.default.3"),
        LocalizedStringKey("todo.default.4"),
        LocalizedStringKey("todo.default.5"),
        LocalizedStringKey("todo.default.6"),
        LocalizedStringKey("todo.default.7"),
        LocalizedStringKey("todo.default.8"),
        LocalizedStringKey("todo.default.9"),
        LocalizedStringKey("todo.default.10"),
        LocalizedStringKey("todo.default.11"),
        LocalizedStringKey("todo.default.12"),
        LocalizedStringKey("todo.default.13"),
        LocalizedStringKey("todo.default.14"),
        LocalizedStringKey("todo.default.15"),
        LocalizedStringKey("todo.default.16"),
    ]

    /// Returns a random LocalizedStringKey suitable for showing as a placeholder
    /// or suggested title when creating a new Todo.
    static func randomNameKey() -> LocalizedStringKey {
        nameKeys.randomElement() ?? nameKeys.first!
    }
}
