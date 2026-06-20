//
//  Item.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/06/20.
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
