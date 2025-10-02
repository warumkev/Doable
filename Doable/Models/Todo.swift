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
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    // Optional timestamp for when the todo was completed
    var completedAt: Date?

    init(title: String) {
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
        self.completedAt = nil
    }
}