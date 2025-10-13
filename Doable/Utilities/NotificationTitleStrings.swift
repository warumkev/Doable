import Foundation
import SwiftUI

struct NotificationTitleStrings {
    // Localized keys for notification titles
    static let titleKeys: [String] = [
        "notification.todo.title.1",
        "notification.todo.title.2",
        "notification.todo.title.3",
        "notification.todo.title.4",
        "notification.todo.title.5",
        "notification.todo.title.6",
        "notification.todo.title.7",
        "notification.todo.title.8",
        "notification.todo.title.9",
        "notification.todo.title.10"
    ]
    
    static func randomTitle() -> String {
        let key = titleKeys.randomElement() ?? titleKeys.first!
        return NSLocalizedString(key, comment: "Motivational todo notification title")
    }
}
