import SwiftUI

struct HistoryView: View {
    let todos: [Todo]
    
    private var historyByDate: [Date: [Todo]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let filtered = todos.filter { $0.isCompleted && $0.completedAt != nil && !calendar.isDate($0.completedAt!, inSameDayAs: today) }
        let grouped = Dictionary(grouping: filtered) { todo in
            calendar.startOfDay(for: todo.completedAt!)
        }
        return grouped
    }
    
    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateStyle = .medium
        return df.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(historyByDate.keys.sorted(by: >), id: \ .self) { date in
                    Section(header: Text(formattedDate(date)).font(.headline)) {
                        ForEach(historyByDate[date]!) { todo in
                            TodoView(todo: todo)
                        }
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("history.title"))
        }
    }
}

#Preview {
    HistoryView(todos: [])
}
