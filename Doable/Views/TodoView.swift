//
//  TodoView.swift
//  Doable
//
//  Created by Kevin Tamme on 26.09.25.
//

import SwiftUI

struct TodoView: View {
    @Bindable var todo: Todo
    @FocusState private var isTextFieldFocused: Bool
    @State private var highlightNew: Bool = false
    var onRequestComplete: (() -> Void)? = nil
    
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
            
            TextField("Enter todo", text: $todo.title)
                .textFieldStyle(PlainTextFieldStyle())
                .strikethrough(todo.isCompleted)
                .foregroundColor(todo.isCompleted ? .secondary : .primary)
                .focused($isTextFieldFocused)
                .overlay(
                    // soft glow when new
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentColor.opacity(highlightNew ? 0.9 : 0.0), lineWidth: 2)
                        .blur(radius: highlightNew ? 6 : 0)
                        .animation(.easeOut(duration: 0.9), value: highlightNew)
                )
                .onAppear {
                    if todo.title.isEmpty {
                        // autofocus and show a brief flourish
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            isTextFieldFocused = true
                            highlightNew = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.easeOut(duration: 0.6)) {
                                    highlightNew = false
                                }
                            }
                        }
                    }
                }
        }
        .padding(.vertical, 4)
    }
}
