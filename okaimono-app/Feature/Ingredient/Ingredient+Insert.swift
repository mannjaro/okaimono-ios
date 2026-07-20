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
        guard let store = menu.objectID.persistentStore else { return nil }
        let ingredient = Ingredient(context: context)
        context.assign(ingredient, to: store)
        
        ingredient.name = draft.name
        ingredient.quantity = draft.quantity
        ingredient.isChecked = false
        ingredient.menu = menu
        
        return ingredient
    }
}
