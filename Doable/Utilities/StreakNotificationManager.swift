import Foundation
import UserNotifications
import SwiftData

class StreakNotificationManager {
    static let shared = StreakNotificationManager()
    private init() {}
    
    func scheduleStreakNotificationIfNeeded(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let request = FetchDescriptor<Todo>(predicate: #Predicate { $0.isCompleted && $0.completedAt != nil })
        let completed = (try? modelContext.fetch(request)) ?? []
        let completedToday = completed.filter { todo in
            if let completedAt = todo.completedAt {
                return calendar.isDate(completedAt, inSameDayAs: today)
            }
            return false
        }
        if completedToday.isEmpty {
            print("[StreakNotificationManager] Scheduling streak notification for today.")
            scheduleNotificationFor6PM()
        } else {
            print("[StreakNotificationManager] Cancelling streak notification (already completed today).")
            cancelStreakNotification()
        }
    }
    
    private func scheduleNotificationFor6PM() {
        print("[StreakNotificationManager] scheduleNotificationFor6PM called.")
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("streak.notification.title", comment: "Streak reminder title")
        content.body = NSLocalizedString("streak.notification.body", comment: "Streak reminder body")
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 12
        dateComponents.minute = 33
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "streakReminder", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("[StreakNotificationManager] Error scheduling notification: \(error)")
            } else {
                print("[StreakNotificationManager] Notification scheduled successfully.")
            }
        }
    }
    
    private func cancelStreakNotification() {
        print("[StreakNotificationManager] cancelStreakNotification called.")
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streakReminder"])
    }
}
