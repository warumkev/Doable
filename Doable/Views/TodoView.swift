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
                .onAppear {
                    if todo.title.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTextFieldFocused = true
                        }
                    }
                }
        }
        .padding(.vertical, 4)
    }
}
