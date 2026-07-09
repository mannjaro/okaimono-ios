//
//  CartIngredientGroup.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/07/05.
//

import SwiftUI

struct CartIngredientGroup: Identifiable {
    var id: String { key }          // ForEach 用
    let key: String
    let displayName: String
    let items: [Ingredient]
    var isChecked: Bool {
        items.allSatisfy(\.isChecked)
    }
    var displayQuantity: String {
        let quantities = items
            .compactMap { $0.quantity?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var seen = Set<String>()
        return quantities
            .filter { seen.insert($0).inserted }
            .joined(separator: ", ")
    }
    
    static func makeGroups(from ingredients:[Ingredient]) -> [CartIngredientGroup] {
        let groups = Dictionary(grouping: ingredients, by: { normalize($0.name) })
        return groups.map { key, items in
            CartIngredientGroup(
                key: key,
                displayName: items.first { !($0.name ?? "").isEmpty }?.name ?? key,
                items: items
            )
        }
        .sorted {
            $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
        }
    }

    private static func normalize(_ name: String?) -> String {
        name?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }
}
