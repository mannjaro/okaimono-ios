//
//  NSManagedObjectContext+Save.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/06/28.
//

import SwiftUI
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
    
    // T は NSManagedObject を継承している型に限定
    func delete<T: NSManagedObject>(_ objects: FetchedResults<T>, at offsets: IndexSet) {
        // offsetsから要素を取り出して削除
        offsets.map { objects[$0] }.forEach(delete)
        saveIfNeeded()
    }
}
