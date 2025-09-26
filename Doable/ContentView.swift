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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todos: [Todo]
    @State private var isDoneSectionExpanded = false
    @State private var pendingCompletionTodo: Todo? = nil
    @State private var isTimerSheetPresented: Bool = false
    @State private var isFullscreenTimerPresented: Bool = false
    @State private var timerSecondsToRun: Int = 0
    @State private var shouldPresentFullscreenAfterSheet: Bool = false
    @State private var isAdding: Bool = false
    @State private var isStatisticsPresented: Bool = false
    @State private var isSettingsPresented: Bool = false
    // Snackbar / undo state
    @State private var snackbarVisible: Bool = false
    @State private var snackbarMessage: String = ""
    @State private var lastDeletedTodo: Todo? = nil
    @State private var lastCompletedTodo: Todo? = nil
    @State private var snackbarTimerCancellable: AnyCancellable? = nil
    enum LastAction { case none, deleted, completed }
    @State private var lastAction: LastAction = .none
    
    private var snackbarDuration: TimeInterval { 4.0 }
    
    private var incompleteTodos: [Todo] {
        todos.filter { !$0.isCompleted }.sorted { $0.createdAt > $1.createdAt }
    }
    
    private var completedTodos: [Todo] {
        todos.filter { $0.isCompleted }.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with title left and icons on the right
                HStack {
                    Text("Doable")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    HStack(spacing: 14) {
                        Button(action: { isStatisticsPresented = true }) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .accessibilityLabel(Text("Statistics"))

                        Button(action: { isSettingsPresented = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .accessibilityLabel(Text("Settings"))
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                if incompleteTodos.isEmpty && completedTodos.isEmpty {
                    VStack {
                        Spacer()
                        Text("No todos yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Tap the + button to create your first todo")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Main todos area
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(incompleteTodos) { todo in
                                    TodoView(todo: todo, onRequestComplete: {
                                        pendingCompletionTodo = todo
                                        isTimerSheetPresented = true
                                    })
                                    .contextMenu {
                                        Button("Delete", role: .destructive) {
                                            performDelete(todo)
                                        }
                                    }
                                }
                            }
                            // outer VStack already provides horizontal padding; keep inner content tight
                            .padding(.bottom, 20)
                        }
                        
                        Spacer()
                        
                        // Done section - always at bottom
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
                                        
                                        Text("Done")
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
                                        .padding(.horizontal, 20)
                                    }
                                    .frame(maxHeight: 200) // Limit height of expanded done section
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100) // Space above the + button
                        } else {
                            Spacer()
                                .frame(height: 100) // Space for + button when no done items
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            VStack {
                Spacer()

                // Snackbar placed here so it sits above the + button and doesn't overlap it
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
                    // Subtle shadow for better visibility
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    // small gap between snackbar and the + button
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // + button with press bounce
                Button(action: addTodo) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.accentColor))
                        .scaleEffect(isAdding ? 0.9 : 1.0)
                        .shadow(color: .black.opacity(isAdding ? 0.15 : 0.25), radius: isAdding ? 2 : 6, x: 0, y: 4)
                        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isAdding)
                }
                .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged({ _ in
                    isAdding = true
                }).onEnded({ _ in
                    isAdding = false
                }))
                .padding(.bottom, 20)
            }
        }
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
                }
            )
        }
        .fullScreenCover(isPresented: $isFullscreenTimerPresented) {
            if let todo = pendingCompletionTodo {
                FullscreenTimerView(todo: todo, totalSeconds: timerSecondsToRun) {
                    // completion callback from fullscreen view: mark todo completed and clear pending
                    withAnimation {
                                todo.isCompleted = true
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
            // Present the new Statistics view
            StatisticsView()
        }
        .sheet(isPresented: $isSettingsPresented) {
            // Minimal settings placeholder for now
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("App settings will go here.")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onChange(of: isTimerSheetPresented) { _, newValue in
            // When the sheet finishes dismissing and we had requested to present the fullscreen timer, do it now.
            if !newValue && shouldPresentFullscreenAfterSheet {
                shouldPresentFullscreenAfterSheet = false
                isFullscreenTimerPresented = true
            }
        }
        
    }
    
    private func addTodo() {
        withAnimation {
            let newTodo = Todo(title: "")
            modelContext.insert(newTodo)
        }
        // Accessibility announcement for adding a todo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let s = NSLocalizedString("accessibility.added_todo", comment: "Accessibility announcement when a new todo is added")
            UIAccessibility.post(notification: .announcement, argument: s)
        }
    }
    
    private func performDelete(_ todo: Todo) {
        // remove and show undo snackbar
        withAnimation {
            lastDeletedTodo = todo
            lastAction = .deleted
            modelContext.delete(todo)
        }
        showSnackbar(message: String(format: NSLocalizedString("snackbar.deleted", comment: "Deleted message with title"), todo.title))
    }

    private func performComplete(_ todo: Todo) {
        withAnimation {
            lastCompletedTodo = todo
            lastAction = .completed
            // already marked completed by caller
        }
        showSnackbar(message: String(format: NSLocalizedString("snackbar.completed", comment: "Completed message with title"), todo.title))
    }

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
                }
            }
        default:
            break
        }
        clearSnackbar()
    }

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
