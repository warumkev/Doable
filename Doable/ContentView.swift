//
//  ContentView.swift
//  Doable
//
//  Created by Kevin Tamme on 26.09.25.
//

import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todos: [Todo]
    @State private var isDoneSectionExpanded = false
    @State private var pendingCompletionTodo: Todo? = nil
    @State private var isTimerSheetPresented: Bool = false
    @State private var isFullscreenTimerPresented: Bool = false
    @State private var timerSecondsToRun: Int = 0
    @State private var shouldPresentFullscreenAfterSheet: Bool = false
    
    private var incompleteTodos: [Todo] {
        todos.filter { !$0.isCompleted }.sorted { $0.createdAt > $1.createdAt }
    }
    
    private var completedTodos: [Todo] {
        todos.filter { $0.isCompleted }.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                Text("Doable")
                    .font(.largeTitle)
                    .fontWeight(.bold)
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
                                            deleteTodo(todo)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
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
                                        
                                        Text("Done today(\(completedTodos.count))")
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
            
            VStack {
                Spacer()
                Button(action: addTodo) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .frame(width: 56, height: 56)
                        .background(Color.primary)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
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
    }
    
    private func deleteTodo(_ todo: Todo) {
        withAnimation {
            modelContext.delete(todo)
        }
    }
    }

#Preview {
    ContentView()
        .modelContainer(for: Todo.self, inMemory: true)
}
