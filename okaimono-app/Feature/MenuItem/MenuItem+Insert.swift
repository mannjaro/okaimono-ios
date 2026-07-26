//
//  MenuItem+Insert.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/07/20.
//

import Foundation
import CoreData

extension MenuItem {
    @MainActor
    static func insert(
        from draft: MenuItemDraft,
        into list: ShoppingList,
        context: NSManagedObjectContext
    ) -> MenuItem? {
        let menu = MenuItem(context: context)
        guard context.assign(menu, toSameStoreAs: list) else { return nil }
        menu.name = draft.name
        menu.list = list
        menu.isArchived = false
        return menu
    }
}
