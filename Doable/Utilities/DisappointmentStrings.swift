import Foundation

/// Centralized strings for the Disappointment / cancellation UI.
import SwiftUI

/// Centralized keys for the Disappointment / cancellation UI.
/// This exposes `LocalizedStringKey` values so views can use SwiftUI's localization directly.
struct DisappointmentText {
    // Use the english phrases as LocalizedStringKey so they map to existing Localizable.strings entries.
    static var titleKey: LocalizedStringKey { LocalizedStringKey("Timer cancelled") }
    static var okButtonKey: LocalizedStringKey { LocalizedStringKey("OK") }

    private static let messageKeys: [LocalizedStringKey] = [
        LocalizedStringKey("This wasn't very Doable of you."),
        LocalizedStringKey("You left the timer hanging. Rude."),
        LocalizedStringKey("The timer was getting lonely."),
        LocalizedStringKey("Come back! The timer misses you."),
        LocalizedStringKey("That was a soft commitment."),
        LocalizedStringKey("You ghosted the timer."),
        LocalizedStringKey("Not your finest moment, champ."),
    ]

    static func randomMessageKey() -> LocalizedStringKey {
        messageKeys.randomElement() ?? messageKeys.first!
    }
}
