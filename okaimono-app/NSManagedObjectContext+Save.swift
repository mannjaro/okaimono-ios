//
//  NSManagedObjectContext+Save.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/06/28.
//

import CoreData

extension NSManagedObjectContext {
    func saveIfNeeded() {
        if hasChanges {
            do {
                try save()
            } catch {
                print("Core Data save error: \(error.localizedDescription)")
            }
        }
    }
}
