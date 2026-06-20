//
//  okaimono_appApp.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/06/20.
//

import SwiftUI
import CoreData

@main
struct okaimono_appApp: App {
    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
