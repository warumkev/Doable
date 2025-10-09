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

                    monthHeader

                    calendarGrid

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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { shareSystemImage() }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
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

            weekStreakRow
        }
        .padding(.vertical, 8)
    }

    // Week row with highlighted streak days
    private var weekStreakRow: some View {
        let today = calendar.startOfDay(for: Date())
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let weekday = calendar.component(.weekday, from: today) // 1 = Sunday
        // Calculate start of week (using current locale)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - calendar.firstWeekday), to: today) ?? today
        // Build array of 7 days for the week
        let weekDays: [Date] = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        let completions = completionsByDay()

        return HStack(spacing: 16) {
            ForEach(0..<7, id: \ .self) { i in
                VStack(spacing: 4) {
                    Text(String(weekdaySymbols[i].prefix(1)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    ZStack {
                        Circle()
                            .fill((completions[startOfDay(weekDays[i])] ?? 0) > 0 ? Color.orange : Color(.systemGray4))
                            .frame(width: 24, height: 24)
                        if (completions[startOfDay(weekDays[i])] ?? 0) > 0 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private var monthHeader: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthYearString(from: displayDate))
                .font(.headline)
            Spacer()
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
    }

    private var calendarGrid: some View {
        let days = makeDaysForMonth(date: displayDate)
    let completions = completionsByDay()

        return VStack(spacing: 8) {
            // weekday headers
            HStack(spacing: 12) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(String(symbol.prefix(1)))
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }

            // 6 rows x 7 columns
            ForEach(0..<6) { row in
                HStack(spacing: 12) {
                    ForEach(0..<7) { col in
                        let idx = row * 7 + col
                        if idx < days.count {
                            let day = days[idx]
                            let count = completions[startOfDay(day)] ?? 0
                            let inMonth = calendar.isDate(day, equalTo: displayDate, toGranularity: .month)
                            VStack(spacing: 6) {
                                Text(dayNumberString(from: day))
                                    .font(.caption2)
                                    .foregroundColor(inMonth ? .secondary : .secondary.opacity(0.5))
                                ZStack {
                                    Circle()
                                        .fill(count > 0 ? Color(.green) : Color(.lightGray))
                                        .frame(width: 22, height: 22)
                                    if count > 0 {
                                        Text("\(count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary stats
    private var summaryStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("statistics.summary"))
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 4)
            statBlock(title: NSLocalizedString("statistics.total", comment: "Total"), value: String(totalCompletions))
            statBlock(title: NSLocalizedString("statistics.this_month", comment: "This month"), value: String(completionsThisMonth))
            statBlock(title: NSLocalizedString("statistics.current_streak", comment: "Streak"), value: String(currentStreak))
            statBlock(title: NSLocalizedString("statistics.longest_streak", comment: "Longest"), value: String(longestStreak))
        }
        .padding(.vertical)
    }

    private func statBlock(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
        .padding(.horizontal)
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

    // MARK: - Sharing helpers

    private func snapshotStatsView() -> UIImage? {
        // Render a polished share card at 9:16 aspect ratio (portrait story size)
        let width: CGFloat = 1080
        let height: CGFloat = 1920 // 9:16 -> width:height = 9:16, 1080 x 1920

        let controller = UIHostingController(rootView: shareCard
            .frame(width: width, height: height)
            .background(LinearGradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)], startPoint: .top, endPoint: .bottom))
        )

        let view = controller.view!
        view.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        view.backgroundColor = UIColor.systemBackground
        // Ensure layout
        view.setNeedsLayout()
        view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat.default()
        // Derive scale from context to avoid deprecated UIScreen.main usage (iOS 26)
        let scale = view.window?.windowScene?.screen.scale ?? view.traitCollection.displayScale
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size, format: format)
        return renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }

    // A polished card used for sharing: logo, calendar, summary stacked vertically
    private var shareCard: some View {
        VStack(spacing: 18) {
            // Logo
            Image("doableLogo")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(height: 140)
                .foregroundColor(.accentColor)
                .padding(.top, 40)

            // Calendar area: encapsulate calendarGrid into a card-like view
            calendarGrid
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground).opacity(0.9)))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 24)

            // Summary at bottom
            VStack(spacing: 8) {
                Text(LocalizedStringKey("statistics.summary"))
                    .font(.title)
                    .fontWeight(.bold)
                HStack(spacing: 12) {
                    statBlock(title: NSLocalizedString("statistics.total", comment: "Total"), value: String(totalCompletions))
                    Divider()
                    statBlock(title: NSLocalizedString("statistics.this_month", comment: "This month"), value: String(completionsThisMonth))
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground).opacity(0.95)))
                .padding(.horizontal, 24)
                Spacer()
            }
            .padding(.bottom, 40)
        }
        .foregroundColor(Color.primary)
    }

    private func shareSystemImage() {
        guard let image = snapshotStatsView() else { return }
        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        DispatchQueue.main.async {
            if let top = topViewController() {
                top.present(av, animated: true)
            } else if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let root = scene.windows.first?.rootViewController {
                root.present(av, animated: true)
            }
        }
    }

    private func topViewController() -> UIViewController? {
        for scene in UIApplication.shared.connectedScenes {
            if let ws = scene as? UIWindowScene {
                for window in ws.windows where window.isKeyWindow {
                    var vc = window.rootViewController
                    while let presented = vc?.presentedViewController {
                        vc = presented
                    }
                    if let v = vc { return v }
                }
            }
        }
        return nil
    }

    private func shareToInstagramStory() {
        guard let image = snapshotStatsView(), let png = image.pngData() else { return }
        let pasteboardItems: [String: Any] = ["com.instagram.sharedSticker.backgroundImage": png]
        let pasteboardOptions = [UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(300)]
        UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)

        if let url = URL(string: "instagram-stories://share") , UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // fallback to system share
            shareSystemImage()
        }
    }

    private func shareToSnapchatStory() {
        guard let image = snapshotStatsView(), let png = image.pngData() else { return }
        // Snapchat uses pasteboard key com.snapchat.sharedSticker.stickerImage
        let pasteboardItems: [String: Any] = ["com.snapchat.sharedSticker.stickerImage": png]
        let pasteboardOptions = [UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(300)]
        UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)

        if let url = URL(string: "snapchat://add_sticker") , UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            shareSystemImage()
        }
    }
}

#Preview {
    StatisticsView()
}
