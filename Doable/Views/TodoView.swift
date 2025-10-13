//
//  TodoView.swift
//  Doable
//
//  Created by Kevin Tamme on 26.09.25.
//

import SwiftUI
import SwiftData

struct TodoView: View {
    @State private var isDateTimePickerPresented: Bool = false
    @Bindable var todo: Todo
    @FocusState private var isTextFieldFocused: Bool
    @FocusState private var isNotesFieldFocused: Bool
    @State private var highlightNew: Bool = false
    @State private var suggestedNameKey: LocalizedStringKey = LocalizedStringKey("todo.placeholder")
    var onRequestComplete: (() -> Void)? = nil
    var onEditingChanged: ((Bool) -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    @AppStorage("settings.prefillSuggestions") private var prefillSuggestions: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Row: Checkbox, todo title, and time picker
            HStack(alignment: .center) {
                Button(action: {
                    let leadingPadding: CGFloat = 34 // Checkbox width + spacing
                    if todo.isCompleted {
                        todo.isCompleted.toggle()
                    } else {
                        onRequestComplete?()
                    }
                }) {
                    let now = Date()
                    let isPast = (todo.time ?? todo.createdAt) < now
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(todo.isCompleted ? .green : (isPast ? .red : .gray))
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())

                TextField(suggestedNameKey, text: $todo.title)
                    .textFieldStyle(PlainTextFieldStyle())
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .focused($isTextFieldFocused)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor.opacity(highlightNew ? 0.5 : 0.0), lineWidth: 2)
                            .blur(radius: highlightNew ? 6 : 0)
                            .animation(.easeOut(duration: 0.5), value: highlightNew)
                    )
                    .onAppear {
                        if todo.title.isEmpty {
                            let key = NewTodoNames.randomNameKey()
                            suggestedNameKey = key
                            if prefillSuggestions {
                                let mirror = Mirror(reflecting: key)
                                if let anyKey = mirror.children.first(where: { $0.label == "key" })?.value as? String {
                                    let localized = NSLocalizedString(anyKey, comment: "")
                                    todo.title = localized
                                } else {
                                    todo.title = String(describing: key)
                                }
                            }
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
                        onEditingChanged?(focused)
                        if !focused {
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
                    .onDisappear {
                        let trimmed = todo.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            DispatchQueue.main.async {
                                withAnimation {
                                    modelContext.delete(todo)
                                }
                            }
                        }
                    }

                Spacer(minLength: 8)
                Button(action: { isDateTimePickerPresented = true }) {
                    HStack(spacing: 4) {
                        if let time = todo.time {
                            Text(DateFormatter.localizedString(from: time, dateStyle: .short, timeStyle: .short))
                                .font(.caption2)
                                .foregroundColor(.primary)
                        } else {
                            Text(LocalizedStringKey("todo.set_time"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $isDateTimePickerPresented) {
                    VStack(spacing: 16) {
                        Text(LocalizedStringKey("todo.select_date_time"))
                            .font(.headline)
                            .padding(.top)
                        DatePicker(
                            LocalizedStringKey("todo.select_date"),
                            selection: Binding(
                                get: { todo.time ?? Date() },
                                set: { newValue in
                                    let calendar = Calendar.current
                                    let currentTime = todo.time ?? Date()
                                    let newDate = calendar.date(bySettingHour: calendar.component(.hour, from: currentTime), minute: calendar.component(.minute, from: currentTime), second: 0, of: newValue) ?? newValue
                                    todo.time = newDate
                                }
                            ),
                            displayedComponents: .date
                        )
                        DatePicker(
                            LocalizedStringKey("todo.select_time"),
                            selection: Binding(
                                get: { todo.time ?? Date() },
                                set: { newValue in todo.time = newValue }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                    .padding()
                    .presentationDetents([.height(220)])
                }
            }

            // Notes field below the row, indented to align with todo title
            let leadingPadding: CGFloat = 34 // Checkbox width + spacing
            if !todo.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTextFieldFocused || isNotesFieldFocused {
                TextField(LocalizedStringKey("todo.notes.placeholder"), text: $todo.notes, axis: .vertical)
                    .font(.caption)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                    .padding(.leading, leadingPadding)
                    .submitLabel(.done)
                    .focused($isNotesFieldFocused)
                    .onSubmit {
                        isNotesFieldFocused = false
                    }
            }

            // Minimal horizontal category selection below notes, indented to align with todo title
            let categories: [String] = [
                "todo.category.work",
                "todo.category.school",
                "todo.category.shopping",
                "todo.category.personal",
                "todo.category.other"
            ]
            // Show category list only when editing (either field focused)
            if todo.category.isEmpty && (isTextFieldFocused || isNotesFieldFocused) {
                // Wrap categories using a flexible grid
                FlexibleView(data: categories, spacing: 6, alignment: .leading) { cat in
                    Text(LocalizedStringKey(cat))
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .onTapGesture {
                            todo.category = cat
                        }
                }
                .padding(.top, 2)
                .padding(.leading, leadingPadding)
            } else if !todo.category.isEmpty {
                HStack(spacing: 4) {
                    Text(LocalizedStringKey(todo.category))
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.25))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                    if isTextFieldFocused || isNotesFieldFocused {
                        Button(action: {
                            todo.category = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
                .padding(.leading, leadingPadding)
            }
        }
        .padding(.vertical, 4)
    }
}
