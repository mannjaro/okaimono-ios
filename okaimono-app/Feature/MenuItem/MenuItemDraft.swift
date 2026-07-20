//
//  MenuItemDraft.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/07/20.
//

import Foundation

struct MenuItemDraft: Equatable {
    let name: String
    static func make(from input: String) -> Self? {
        let name = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        return Self(name: name)
    }
}
