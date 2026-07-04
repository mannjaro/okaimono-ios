//
//  IngredientTests.swift
//  okaimono-appTests
//
//  Created by Takayuki Zukawa on 2026/06/28.
//

import Testing
import CoreData
@testable import okaimono_app

struct IngredientTests {
    
    // テスト用の　in-memory ストアを作成
    let context: NSManagedObjectContext = {
        let result = PersistenceController(inMemory: true)
        let context = result.container.viewContext
        
        for i in 1...2 {
            let list = ShoppingList(context: context)
            list.id = UUID()
            list.name = "Shopping list \(i)"
            list.createdAt = Date()

            let menu = MenuItem(context: context)
            menu.id = UUID()
            menu.name = "Ingredient \(i)"
            menu.createdAt = Date()
            menu.list = list

            for i in 1...2 {
                let ingredient = Ingredient(context: context)
                ingredient.id = UUID()
                ingredient.name = "Sample \(i)"
                ingredient.quantity = "100g"
                ingredient.isChecked = false
                ingredient.createdAt = Date()
                ingredient.menu = menu
            }
        }
        return context
    }()

    @Test func toggleCheck_changesIsChecked() async throws {
        // Arrange: create ingredient
        let ingredient = Ingredient(context: context)
        ingredient.isChecked = false
        
        // Act: toggle isChecked
        ingredient.toggleCheck()
        
        // Assert: check state
        #expect(ingredient.isChecked == true)
    }

}
