import Foundation

/// Centralized strings for the Disappointment / cancellation UI.
/// Uses `NSLocalizedString` so these can be localized later via `Localizable.strings` files.
struct DisappointmentText {
    static var title: String {
        NSLocalizedString("disappointment.title", value: "Timer cancelled", comment: "Title for the disappointment full screen shown when the user leaves the app during a timer")
    }

    static var okButton: String {
        NSLocalizedString("disappointment.button.ok", value: "OK", comment: "OK button title for disappointment screen")
    }

    // Funny messages - keep these in code but routed through NSLocalizedString for future localization.
    private static var rawMessages: [String] = [
        NSLocalizedString("disappointment.message.1", value: "This wasn't very Doable of you.", comment: "Funny disappointment message"),
        NSLocalizedString("disappointment.message.2", value: "You left the timer hanging. Rude.", comment: "Funny disappointment message"),
        NSLocalizedString("disappointment.message.3", value: "The timer was getting lonely.", comment: "Funny disappointment message"),
        NSLocalizedString("disappointment.message.4", value: "Come back! The timer misses you.", comment: "Funny disappointment message"),
        NSLocalizedString("disappointment.message.5", value: "That was a soft commitment.", comment: "Funny disappointment message"),
        NSLocalizedString("disappointment.message.6", value: "You ghosted the timer.", comment: "Funny disappointment message"),
        NSLocalizedString("disappointment.message.7", value: "Not your finest moment, champ.", comment: "Funny disappointment message"),
    ]

    static func randomMessage() -> String {
        rawMessages.randomElement() ?? rawMessages.first!
    }
}
