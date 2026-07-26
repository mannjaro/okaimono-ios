//
//  IngredientDraft.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/07/20.
//

import Foundation

struct IngredientDraft: Equatable {
    let name: String
    let quantity: String?
    static func make(from input: String, qty: String?) -> Self? {
        let name = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedQty = qty?.trimmingCharacters(in: .whitespacesAndNewlines)
        let quantity = (trimmedQty?.isEmpty == false) ? trimmedQty : nil
        guard !name.isEmpty else { return nil }
        return Self(name: name, quantity: quantity)
    }
}
