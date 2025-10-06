import Foundation
import SwiftUI

/// Utility that centralizes the localized keys/messages used when the user
/// abandons a running timer. Exposes LocalizedStringKey values so SwiftUI views
/// can use them directly without converting at call sites.
struct DisappointmentText {
    // Title shown in the disappointment overlay
    static var titleKey: LocalizedStringKey { LocalizedStringKey("disappointment.title") }
    // Label for the acknowledgement button
    static var okButtonKey: LocalizedStringKey { LocalizedStringKey("disappointment.ok") }

    // Variety of playful messages that are selected at random to make the cancellation UX lighter.
    private static let messageKeys: [LocalizedStringKey] = [
        LocalizedStringKey("disappointment.msg.1"),
        LocalizedStringKey("disappointment.msg.2"),
        LocalizedStringKey("disappointment.msg.3"),
        LocalizedStringKey("disappointment.msg.4"),
        LocalizedStringKey("disappointment.msg.5"),
        LocalizedStringKey("disappointment.msg.6"),
        LocalizedStringKey("disappointment.msg.7"),
    ]

    // Pick a random message to display when the timer is cancelled.
    static func randomMessageKey() -> LocalizedStringKey {
        messageKeys.randomElement() ?? messageKeys.first!
    }
}
