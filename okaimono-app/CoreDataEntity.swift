//
//  CoreDataEntity.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/06/28.
//

import CoreData

protocol CoreDataEntity: NSManagedObject {
    var id: UUID? { get set }
    var createdAt: Date? { get set }
}

extension CoreDataEntity {
    func setupDefaults() {
        id = UUID()
        createdAt = Date()
    }
}
