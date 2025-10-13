import Foundation
import UserNotifications
import SwiftData

class TodoNotificationManager {
    static let shared = TodoNotificationManager()
    private init() {}
    
    func scheduleNotification(for todo: Todo) {
        guard let time = todo.time, !todo.isCompleted else { return }
        let content = UNMutableNotificationContent()
    content.title = NotificationTitleStrings.randomTitle()
    let bodyTemplate = NSLocalizedString("notification.todo.body", comment: "Motivational todo notification body")
    let todoTitle = todo.title.isEmpty ? NSLocalizedString("todo.placeholder", comment: "Todo placeholder") : todo.title
    content.body = String(format: bodyTemplate, todoTitle)
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(time.timeIntervalSinceNow, 1), repeats: false)
    let request = UNNotificationRequest(identifier: "todo_\(String(describing: todo.id))", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[TodoNotificationManager] Error scheduling notification: \(error)")
            }
        }
    }
    
    func removeNotification(for todo: Todo) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["todo_\(String(describing: todo.id))"])
    }
}
