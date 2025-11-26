//
//  eitangosApp.swift
//  eitangos
//
//  Created by Shuhei Kinugasa on 2025/11/24.
//

import SwiftUI
import CoreData

@main
struct eitangosApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()  // ← Changed from ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
