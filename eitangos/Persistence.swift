//
//  Persistence.swift
//  eitangos
//
//  Created by Shuhei Kinugasa on 2025/11/24.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for preview
        let sampleWords = [
            ("make a shift", "シフトの作成"),
            ("computer", "コンピューター"),
            ("cat", "猫"),
            ("school trip", "課外活動"),
            ("dog", "犬"),
            ("book", "本"),
            ("water", "水"),
            ("coffee", "コーヒー"),
            ("morning", "朝"),
            ("friend", "友達")
        ]
        
        for (english, japanese) in sampleWords {
            let newItem = VocabularyItem(context: viewContext)
            newItem.id = UUID()
            newItem.english = english
            newItem.japanese = japanese
            newItem.setValue(Date(), forKey: "createdAt")
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "eitangos")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
