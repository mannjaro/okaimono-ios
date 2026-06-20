//
//  IngredientView.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/06/20.
//

import SwiftUI
import CoreData

struct IngredientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let menu: MenuItem
    
    var body: some View {
        Text(menu.name ?? "")
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let menu = try! context.fetch(MenuItem.fetchRequest()).first!
    return IngredientView(menu: menu)
        .environment(\.managedObjectContext, context)
}
