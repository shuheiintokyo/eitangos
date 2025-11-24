//
//  Persistence.swift
//  eitangos
//
//  Created by Shuhei Kinugasa on 2025/11/24.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add mock vocabulary data for preview
        let mockData = [
            ("dog", "犬"),
            ("cat", "猫"),
            ("apple", "りんご"),
            ("computer", "コンピューター"),
            ("school trip", "課外活動"),
            ("make a shift", "シフトの作成"),
        ]
        
        for (english, japanese) in mockData {
            let newItem = VocabularyItem(context: viewContext)
            newItem.id = UUID()
            newItem.english = english
            newItem.japanese = japanese
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
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Load initial mock data if database is empty
        if inMemory == false {
            loadInitialDataIfNeeded()
        }
    }
    
    private func loadInitialDataIfNeeded() {
        let fetchRequest: NSFetchRequest<VocabularyItem> = VocabularyItem.fetchRequest()
        let context = container.viewContext
        
        do {
            let count = try context.count(for: fetchRequest)
            if count == 0 {
                let mockData = [
                    ("dog", "犬"),
                    ("cat", "猫"),
                    ("apple", "りんご"),
                    ("computer", "コンピューター"),
                    ("school trip", "課外活動"),
                    ("make a shift", "シフトの作成"),
                ]
                
                for (english, japanese) in mockData {
                    let newItem = VocabularyItem(context: context)
                    newItem.id = UUID()
                    newItem.english = english
                    newItem.japanese = japanese
                }
                
                try context.save()
            }
        } catch {
            let nsError = error as NSError
            print("Failed to load initial data: \(nsError), \(nsError.userInfo)")
        }
    }
}
