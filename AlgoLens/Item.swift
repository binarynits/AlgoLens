//
//  Item.swift
//  AlgoLens
//
//  Created by Nitesh Tak on 6/5/26.
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
