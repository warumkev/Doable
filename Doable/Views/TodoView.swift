//
//  TodoView.swift
//  Doable
//
//  Created by Kevin Tamme on 26.09.25.
//

import SwiftUI
import SwiftData

struct TodoView: View {
    @Bindable var todo: Todo
    @FocusState private var isTextFieldFocused: Bool
    @State private var highlightNew: Bool = false
    @State private var suggestedNameKey: LocalizedStringKey = LocalizedStringKey("todo.placeholder")
    var onRequestComplete: (() -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack {
            Button(action: {
                if todo.isCompleted {
                    // Allow un-completing immediately
                    todo.isCompleted.toggle()
                } else {
                    // Ask parent to present timer sheet
                    onRequestComplete?()
                }
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            TextField(suggestedNameKey, text: $todo.title)
                .textFieldStyle(PlainTextFieldStyle())
                .strikethrough(todo.isCompleted)
                .foregroundColor(todo.isCompleted ? .secondary : .primary)
                .focused($isTextFieldFocused)
                .overlay(
                    // soft glow when new
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentColor.opacity(highlightNew ? 0.5 : 0.0), lineWidth: 2)
                        .blur(radius: highlightNew ? 6 : 0)
                        .animation(.easeOut(duration: 0.5), value: highlightNew)
                )
                .onAppear {
                    if todo.title.isEmpty {
                        // pick a friendly suggested placeholder and autofocus
                        suggestedNameKey = NewTodoNames.randomNameKey()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            isTextFieldFocused = true
                            highlightNew = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    highlightNew = false
                                }
                            }
                        }
                    }
                }
                .onChange(of: isTextFieldFocused) { _, focused in
                    if !focused {
                        // If the user left the field and didn't type anything, remove the empty todo.
                        let trimmed = todo.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            // Use main thread animation for UI consistency
                            DispatchQueue.main.async {
                                withAnimation {
                                    modelContext.delete(todo)
                                }
                            }
                        }
                    }
                }
                .onDisappear {
                    // As a safety net: if the view disappears while title is empty, remove it.
                    let trimmed = todo.title.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        DispatchQueue.main.async {
                            withAnimation {
                                modelContext.delete(todo)
                            }
                        }
                    }
                }
        }
        .padding(.vertical, 4)
    }
}
