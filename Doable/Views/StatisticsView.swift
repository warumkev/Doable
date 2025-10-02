import SwiftUI
import Foundation

struct StatisticsView: View {
    // Todos provided by parent (avoids private synthesized initializers from @Query)
    var todos: [Todo] = []

    // Show the current month calendar
    @State private var displayDate: Date = Date()

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(LocalizedStringKey("statistics.title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)

                monthHeader

                calendarGrid

                Spacer()
            }
            .padding()
            .navigationTitle(LocalizedStringKey("statistics.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
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
        guard let range = calendar.range(of: .day, in: .month, for: date),
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
}

#Preview {
    StatisticsView()
}
