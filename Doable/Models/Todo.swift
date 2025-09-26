//
//  Todo.swift
//  Doable
//
//  Created by Kevin Tamme on 26.09.25.
//

import Foundation
import SwiftData

@Model
final class Todo {
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    
    init(title: String) {
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
    }
}