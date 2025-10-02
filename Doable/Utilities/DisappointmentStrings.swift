import Foundation
import SwiftUI

/// Utility that centralizes the localized keys/messages used when the user
/// abandons a running timer. Exposes LocalizedStringKey values so SwiftUI views
/// can use them directly without converting at call sites.
struct DisappointmentText {
    // Title shown in the disappointment overlay
    static var titleKey: LocalizedStringKey { LocalizedStringKey("Timer cancelled") }
    // Label for the acknowledgement button
    static var okButtonKey: LocalizedStringKey { LocalizedStringKey("OK") }

    // Variety of playful messages that are selected at random to make the cancellation UX lighter.
    private static let messageKeys: [LocalizedStringKey] = [
        LocalizedStringKey("This wasn't very Doable of you."),
        LocalizedStringKey("You left the timer hanging. Rude."),
        LocalizedStringKey("The timer was getting lonely."),
        LocalizedStringKey("Come back! The timer misses you."),
        LocalizedStringKey("That was a soft commitment."),
        LocalizedStringKey("You ghosted the timer."),
        LocalizedStringKey("Not your finest moment, champ."),
    ]

    // Pick a random message to display when the timer is cancelled.
    static func randomMessageKey() -> LocalizedStringKey {
        messageKeys.randomElement() ?? messageKeys.first!
    }
}
