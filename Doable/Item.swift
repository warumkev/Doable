//
//  Item.swift
//  Doable
//
//  Created by Kevin Tamme on 26.09.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
