import SwiftUI
import Foundation
import UIKit

struct StatisticsView: View {
    // Todos provided by parent (avoids private synthesized initializers from @Query)
    var todos: [Todo] = []

    // Show the current month calendar
    @State private var displayDate: Date = Date()

    private let calendar = Calendar.current

    // (no explicit share state needed for basic system share)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // --- Streak View ---
                    streakView

                    Divider()
                    // Summary statistics row
                    summaryStats

                    Spacer()
                }
                .padding(.top, 32) // Add extra top padding to avoid overlap
                .padding()
            }
            .navigationTitle(LocalizedStringKey("statistics.title"))
            .navigationBarTitleDisplayMode(.inline)
            // Share toolbar removed
        }
    }
    // --- Streak View ---
    private var streakView: some View {
        VStack(spacing: 8) {
            ZStack {
                VStack(spacing: 0) {
                    Image(systemName: "flame.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundColor(currentStreak > 0 ? .orange : .gray)
                        .shadow(color: (currentStreak > 0 ? Color.orange : Color.gray).opacity(0.3), radius: 4, x: 0, y: 2)
                    Text("\(currentStreak)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.top, 2)
                }
            }
            Text(LocalizedStringKey("statistics.streak_label"))
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 2)
            Text(LocalizedStringKey("statistics.streak_encouragement"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 2)

            // weekStreakRow removed
        }
        .padding(.vertical, 8)
    }

    // weekStreakRow removed

    // MARK: - Summary stats
    private var summaryStats: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(LocalizedStringKey("statistics.summary"))
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 4)
            // 2x2 bento grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                statBlock(title: NSLocalizedString("statistics.total", comment: "Total"), value: String(totalCompletions))
                statBlock(title: NSLocalizedString("statistics.this_month", comment: "This month"), value: String(completionsThisMonth))
                statBlock(title: NSLocalizedString("statistics.current_streak", comment: "Streak"), value: String(currentStreak))
                statBlock(title: NSLocalizedString("statistics.longest_streak", comment: "Longest"), value: String(longestStreak))
            }
        }
        .padding(.vertical)
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // Computed stats
    private var totalCompletions: Int {
        todos.reduce(0) { $0 + (($1.isCompleted && $1.completedAt != nil) ? 1 : 0) }
    }

    private var completionsThisMonth: Int {
        let comps = completionsByDay()
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayDate)) ?? displayDate
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? displayDate
        return comps.filter { $0.key >= calendar.startOfDay(for: start) && $0.key < calendar.startOfDay(for: end) }
            .reduce(0) { $0 + $1.value }
    }

    private var currentStreak: Int {
        // Count consecutive days up to today with at least one completion
        let comps = completionsByDay()
        var streak = 0
        var day = calendar.startOfDay(for: Date())
        while true {
            if comps[day] ?? 0 > 0 {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
            } else {
                break
            }
        }
        return streak
    }

    private var longestStreak: Int {
        // Scan through sorted days to find the longest consecutive run
        let comps = completionsByDay()
        let days = comps.keys.sorted()
        var longest = 0
        var current = 0
        var lastDay: Date? = nil
        for d in days {
            if let ld = lastDay, calendar.date(byAdding: .day, value: 1, to: ld) == d {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            lastDay = d
        }
        return longest
    }

    private var averagePerWeek: Double {
        let comps = completionsByDay()
        guard let first = comps.keys.min(), let last = comps.keys.max() else { return 0 }
        let weeks = max(1, calendar.dateComponents([.weekOfYear], from: first, to: last).weekOfYear ?? 0)
        let total = comps.reduce(0) { $0 + $1.value }
        return Double(total) / Double(weeks)
    }

    // Helpers
    private func startOfDay(_ date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }

    private func dayNumberString(from date: Date) -> String {
        let d = calendar.component(.day, from: date)
        return String(d)
    }

    private func monthYearString(from date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "LLLL yyyy"
        df.locale = Locale.current
        return df.string(from: date)
    }

    private func changeMonth(by months: Int) {
        if let d = calendar.date(byAdding: .month, value: months, to: displayDate) {
            displayDate = d
        }
    }

    private func makeDaysForMonth(date: Date) -> [Date] {
        var days: [Date] = []
                guard calendar.range(of: .day, in: .month, for: date) != nil,
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return days
        }

        // Determine weekday offset
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) // 1..7
        let leading = firstWeekday - calendar.firstWeekday
        let start = calendar.date(byAdding: .day, value: -leading, to: firstOfMonth) ?? firstOfMonth

        for i in 0..<42 { // 6 weeks
            if let d = calendar.date(byAdding: .day, value: i, to: start) {
                days.append(d)
            }
        }

        return days
    }

    private func completionsByDay() -> [Date: Int] {
        var map: [Date: Int] = [:]
        for todo in todos {
            if todo.isCompleted, let completedAt = todo.completedAt {
                let sd = startOfDay(completedAt)
                map[sd, default: 0] += 1
            }
        }
        return map
    }

    // Share functions removed
}

#Preview {
    StatisticsView()
}
