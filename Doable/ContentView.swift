//
//  ContentView.swift
//  Doable
//
//  Created by Kevin Tamme on 26.09.25.
//

import SwiftUI
import SwiftData
import Foundation
import Combine

/// The app's primary view showing the list of todos and controls to add/complete them.
///
/// Responsibilities:
/// - Query and display `Todo` items from SwiftData.
/// - Provide adding/deleting, completion (via a timed fullscreen flow), and an undo snackbar.
struct ContentView: View {
    // SwiftData model context for inserting/deleting model objects
    @Environment(\.modelContext) private var modelContext
    // Query property wrapper to fetch all Todo objects
    @Query private var todos: [Todo]

    // UI state
    @State private var isLogoRubbed: Bool = false
    @State private var isDoneSectionExpanded = false
    @State private var pendingCompletionTodo: Todo? = nil
    @State private var isTimerSheetPresented: Bool = false
    @State private var isFullscreenTimerPresented: Bool = false
    @State private var timerSecondsToRun: Int = 0

    // Flag set while the time-setup sheet is dismissing so we can present the fullscreen cover
    @State private var shouldPresentFullscreenAfterSheet: Bool = false
    @State private var isAdding: Bool = false
    @State private var isStatisticsPresented: Bool = false
    @State private var isSettingsPresented: Bool = false
    @State private var isMenuPresented: Bool = false
    @State private var isHistoryPresented: Bool = false
    // Track if any todo is currently being edited
    @State private var isAnyTodoEditing: Bool = false

    // Snackbar / undo state
    @State private var snackbarVisible: Bool = false
    @State private var snackbarMessage: String = ""
    @State private var lastDeletedTodo: Todo? = nil
    @State private var lastCompletedTodo: Todo? = nil
    @State private var snackbarTimerCancellable: AnyCancellable? = nil
    enum LastAction { case none, deleted, completed }
    @State private var lastAction: LastAction = .none

    // How long the snackbar stays visible before auto-dismiss
    private var snackbarDuration: TimeInterval { 4.0 }

    // Derived lists for convenience and ordering
    private var incompleteTodos: [Todo] {
        todos.filter { !$0.isCompleted }
            .sorted {
                let lhsTime = $0.time ?? $0.createdAt
                let rhsTime = $1.time ?? $1.createdAt
                return lhsTime < rhsTime
            }
    }

    private var completedTodos: [Todo] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return todos.filter {
            $0.isCompleted &&
            ($0.completedAt != nil) &&
            calendar.isDate($0.completedAt!, inSameDayAs: today)
        }.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    /// Overdue todos: not completed and (time ?? createdAt) < now
    private var overdueTodos: [Todo] {
        let now = Date()
        return todos.filter { !$0.isCompleted && (($0.time ?? $0.createdAt) < now) }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header with title left and optional icons on the right
                VStack {
                    // Replace `Menu` with a simple Button + confirmationDialog to avoid
                    // UIKit context-menu reparenting warnings on some iOS versions.
                    Button {
                        isMenuPresented = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(LocalizedStringKey("app.title"))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.down")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                    .confirmationDialog("Title", isPresented: $isMenuPresented, titleVisibility: .hidden) {
                        Button(LocalizedStringKey("menu.statistics")) {
                            isMenuPresented = false
                            // Present the sheet after the dialog dismisses
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                isStatisticsPresented = true
                            }
                        }
                        Button(LocalizedStringKey("menu.settings")) {
                            isMenuPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                isSettingsPresented = true
                            }
                        }
                        Button(LocalizedStringKey("menu.history")) {
                            isMenuPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                isHistoryPresented = true
                            }
                        }
                    }

                    Divider()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    HStack {
                        // Left: current day abbreviation (e.g. Fri)
                        Text(formattedDate("EE"))
                            .font(.largeTitle)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Right: yy.month <br> yyyy
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(formattedDate("dd. MMMM"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(formattedDate("yyyy"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 8)

                    Divider()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)

                // Empty state
                if incompleteTodos.isEmpty && completedTodos.isEmpty {
                    VStack {
                        Spacer()
                        Text(LocalizedStringKey("empty.no_todos"))
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text(LocalizedStringKey("empty.tap_plus_to_create"))
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Main todos list (incomplete first)
                        List {
                            ForEach(incompleteTodos) { todo in
                                TodoView(
                                    todo: todo,
                                    onRequestComplete: {
                                        pendingCompletionTodo = todo
                                        isTimerSheetPresented = true
                                    },
                                    onEditingChanged: { editing in
                                        isAnyTodoEditing = editing
                                    }
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        performDelete(todo)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())

                        // Done section: collapsible list of completed todos
                        if !completedTodos.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isDoneSectionExpanded.toggle()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: isDoneSectionExpanded ? "chevron.down" : "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Text(LocalizedStringKey("section.done"))
                                            .font(.headline)
                                            .foregroundColor(.secondary)

                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(PlainButtonStyle())

                                if isDoneSectionExpanded {
                                    ScrollView {
                                        LazyVStack(alignment: .leading, spacing: 12) {
                                            ForEach(completedTodos) { todo in
                                                TodoView(todo: todo)
                                            }
                                        }
                                        // Match main todos list: remove extra horizontal padding
                                    }
                                    .frame(maxHeight: 200) // Limit height of expanded done section
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .cornerRadius(12)
                            // Remove .padding(.horizontal, 16) to align with main todos
                            .padding(.bottom, 0)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            // Overlay: snackbar and + button at the bottom
            VStack(spacing: 8) {
                if snackbarVisible {
                    HStack {
                        Text(snackbarMessage)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Button(action: undoLastAction) {
                            Text(NSLocalizedString("snackbar.undo", comment: "Undo"))
                                .bold()
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(BlurView(style: .systemThinMaterialDark))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                let hasEmptyTodo = incompleteTodos.contains { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if !isAnyTodoEditing {
                    Button(action: addTodo) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(Color.primary))
                            .scaleEffect(isAdding ? 0.9 : 1.0)
                            .shadow(color: Color.black.opacity(0.85), radius: 12, x: 0, y: 4)
                            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isAdding)
                    }
                    .disabled(hasEmptyTodo)
                    .opacity(hasEmptyTodo ? 0.3 : 1.0)
                    .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged({ _ in
                        isAdding = true
                    }).onEnded({ _ in
                        isAdding = false
                    }))
                }
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            // Schedule/cancel streak notification for 6pm based on today's completion status
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let completedToday = todos.contains { $0.isCompleted && $0.completedAt != nil && calendar.isDate($0.completedAt!, inSameDayAs: today) }
            let center = UNUserNotificationCenter.current()
            let identifier = "streakReminder"
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            if !completedToday {
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("streak.notification.title", comment: "Streak reminder title")
                content.body = NSLocalizedString("streak.notification.body", comment: "Streak reminder body")
                content.sound = .default
                var dateComponents = DateComponents()
                dateComponents.hour = 18
                dateComponents.minute = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                center.add(request)
            }
        }
        // Timer setup sheet -> fullscreen timer presentation flow
        .sheet(isPresented: $isTimerSheetPresented) {
            TimerSetupSheet(
                todoTitle: pendingCompletionTodo?.title ?? "",
                onCancel: {
                    isTimerSheetPresented = false
                    pendingCompletionTodo = nil
                },
                onConfirm: { seconds in
                    // Instead of immediately completing, present the fullscreen timer flow.
                    // Dismiss the sheet first, then set a flag to present the fullscreen cover when the sheet is fully dismissed.
                    timerSecondsToRun = seconds
                    shouldPresentFullscreenAfterSheet = true
                    isTimerSheetPresented = false
                },
                onCompleteWithoutTimer: {
                    // Immediately complete the pending todo without running the timer.
                    if let todo = pendingCompletionTodo {
                        withAnimation {
                            todo.isCompleted = true
                            todo.completedAt = Date()
                            todo.completedWithTimer = false
                            todo.timerDurationSeconds = nil
                        }
                        performComplete(todo)
                    }
                    // Dismiss sheet and clear pending
                    isTimerSheetPresented = false
                    pendingCompletionTodo = nil
                }
            )
        }
        .fullScreenCover(isPresented: $isFullscreenTimerPresented) {
            if let todo = pendingCompletionTodo {
                FullscreenTimerView(todo: todo, totalSeconds: timerSecondsToRun) {
                    // completion callback from fullscreen view: mark todo completed and clear pending
                    withAnimation {
                        todo.isCompleted = true
                        todo.completedAt = Date()
                        todo.completedWithTimer = true
                        todo.timerDurationSeconds = timerSecondsToRun
                    }
                    // show snackbar for undo
                    performComplete(todo)
                    pendingCompletionTodo = nil
                    isFullscreenTimerPresented = false
                } onCancel: {
                    // user cancelled the fullscreen timer flow
                    pendingCompletionTodo = nil
                    isFullscreenTimerPresented = false
                }
            } else {
                // Fallback: dismiss if no pending todo
                EmptyView()
            }
        }
        .sheet(isPresented: $isStatisticsPresented) {
            // Present the Statistics view
            StatisticsView(todos: todos)
        }
        .sheet(isPresented: $isSettingsPresented) {
            // Present the Settings view
            SettingsView(todos: todos)
        }
        .onChange(of: isTimerSheetPresented) { _, newValue in
            // When the sheet finishes dismissing and we had requested to present the fullscreen timer, do it now.
            if !newValue && shouldPresentFullscreenAfterSheet {
                shouldPresentFullscreenAfterSheet = false
                isFullscreenTimerPresented = true
            }
        }
        .onChange(of: todos) { _, _ in
            StreakNotificationManager.shared.scheduleStreakNotificationIfNeeded(modelContext: modelContext)
            UIApplication.shared.applicationIconBadgeNumber = overdueTodos.count
        }
        .sheet(isPresented: $isHistoryPresented) {
            HistoryView(todos: todos)
        }

    }

    // MARK: - Actions

    /// Return a formatted date string using the given date format and the current locale.
    private func formattedDate(_ format: String) -> String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = format
        return df.string(from: Date())
    }

    /// Create a new, empty Todo and focus the text field (handled by `TodoView`).
    private func addTodo() {
        withAnimation {
            let now = Date()
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
            components.hour = (components.hour ?? 0) + 1
            components.minute = 0
            components.second = 0
            let nextHour = calendar.date(from: components) ?? now.addingTimeInterval(3600)
            let newTodo = Todo(title: "")
            newTodo.time = nextHour
            modelContext.insert(newTodo)
        }
        // Accessibility announcement for adding a todo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let s = NSLocalizedString("accessibility.added_todo", comment: "Accessibility announcement when a new todo is added")
            UIAccessibility.post(notification: .announcement, argument: s)
        }
    }

    /// Delete a todo and show the undo snackbar.
    private func performDelete(_ todo: Todo) {
        withAnimation {
            lastDeletedTodo = todo
            lastAction = .deleted
            modelContext.delete(todo)
        }
        showSnackbar(message: String(format: NSLocalizedString("snackbar.deleted", comment: "Deleted message with title"), todo.title))
    }

    /// Called when a todo is completed via the fullscreen timer flow. Shows the snackbar for undo.
    private func performComplete(_ todo: Todo) {
        withAnimation {
            lastCompletedTodo = todo
            lastAction = .completed
            // Record completion timestamp
            todo.completedAt = Date()
        }
        UIApplication.shared.applicationIconBadgeNumber = overdueTodos.count
        showSnackbar(message: String(format: NSLocalizedString("snackbar.completed", comment: "Completed message with title"), todo.title))
    }

    /// Undo the last deletion or completion if possible.
    private func undoLastAction() {
        snackbarTimerCancellable?.cancel()
        snackbarTimerCancellable = nil
        switch lastAction {
        case .deleted:
            if let t = lastDeletedTodo {
                withAnimation {
                    modelContext.insert(t)
                }
            }
        case .completed:
            if let t = lastCompletedTodo {
                withAnimation {
                    t.isCompleted = false
                    t.completedAt = nil
                }
            }
        default:
            break
        }
        clearSnackbar()
    }

    /// Show a transient snackbar with undo action.
    private func showSnackbar(message: String) {
        snackbarMessage = message
        withAnimation(.easeOut) {
            snackbarVisible = true
        }
        // auto-dismiss after duration
        snackbarTimerCancellable?.cancel()
        snackbarTimerCancellable = Just(()).delay(for: .seconds(snackbarDuration), scheduler: RunLoop.main).sink { _ in
            withAnimation {
                self.snackbarVisible = false
            }
            self.lastAction = .none
        }
    }

    private func clearSnackbar() {
        withAnimation {
            snackbarVisible = false
        }
        lastAction = .none
        lastDeletedTodo = nil
        lastCompletedTodo = nil
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Todo.self, inMemory: true)
}
