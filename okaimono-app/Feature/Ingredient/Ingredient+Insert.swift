//
//  Ingredient+Insert.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/07/20.
//

import Foundation
import CoreData

extension Ingredient {
    @MainActor
    static func insert(
        from draft: IngredientDraft,
        into menu: MenuItem,
        context: NSManagedObjectContext
    ) -> Ingredient? {
        let ingredient = Ingredient(context: context)
        guard context.assign(ingredient, toSameStoreAs: menu) else { return nil }
        ingredient.name = draft.name
        ingredient.quantity = draft.quantity
        ingredient.isChecked = false
        ingredient.menu = menu
        
        return ingredient
    }
}
