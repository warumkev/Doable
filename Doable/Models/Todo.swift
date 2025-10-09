//
//  Todo.swift
//  Doable
//
//  Created by Kevin Tamme on 26.09.25.
//

import Foundation
import SwiftData

/// Simple persistable model representing a single todo item.
/// Stored properties:
/// - `title`: the user-entered text for the todo
/// - `isCompleted`: whether the item has been completed
/// - `createdAt`: timestamp used for sorting and display
@Model
final class Todo {
    var title: String = ""
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    // Optional timestamp for when the todo was completed
    var completedAt: Date?
    // Timer duration in seconds (if completed with timer)
    var timerDurationSeconds: Int? = nil
    // Whether this todo was completed with a timer
    var completedWithTimer: Bool = false

    init(title: String) {
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
        self.completedAt = nil
        self.timerDurationSeconds = nil
        self.completedWithTimer = false
    }
}
