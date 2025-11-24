//
//  ContentView.swift
//  eitangos
//
//  Created by Shuhei Kinugasa on 2025/11/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Vocabulary List Tab
            VocabularyListView()
                .tabItem {
                    Label("リスト", systemImage: "list.bullet")
                }
                .tag(0)
            
            // Quick Test Tab
            QuickTestView()
                .tabItem {
                    Label("テスト", systemImage: "questionmark.circle")
                }
                .tag(1)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
