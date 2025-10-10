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

        // Calculate current streak (number of consecutive days with at least one completed todo)
        var streak = 0
        var day = today
        while true {
            let hasCompleted = completed.contains { todo in
                if let completedAt = todo.completedAt {
                    return calendar.isDate(completedAt, inSameDayAs: day)
                }
                return false
            }
            if hasCompleted {
                streak += 1
                day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
            } else {
                break
            }
        }

        if streak == 0 {
            print("[StreakNotificationManager] No active streak, not scheduling notification.")
            cancelStreakNotification()
            return
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

        // Pick a random streak notification title and body
        let titleKeys = (1...5).map { "streak.notification.title.\($0)" }
        let bodyKeys = (1...5).map { "streak.notification.body.\($0)" }
        let randomTitleKey = titleKeys.randomElement() ?? titleKeys[0]
        let randomBodyKey = bodyKeys.randomElement() ?? bodyKeys[0]
        content.title = NSLocalizedString(randomTitleKey, comment: "Streak reminder title")
        content.body = NSLocalizedString(randomBodyKey, comment: "Streak reminder body")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0
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
