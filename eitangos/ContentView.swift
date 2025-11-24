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

// MARK: - Vocabulary List View
struct VocabularyListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: VocabularyItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \VocabularyItem.english, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<VocabularyItem>
    
    @State private var searchText = ""
    
    var filteredItems: [VocabularyItem] {
        if searchText.isEmpty {
            return Array(items)
        } else {
            return items.filter { item in
                (item.english?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.japanese?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("語彙がありません")
                            .font(.headline)
                        
                        Text("新しい語彙を追加してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            VocabularyRow(item: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("英単語リスト")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .searchable(text: $searchText, prompt: "単語を検索")
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting item: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct VocabularyRow: View {
    let item: VocabularyItem
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.english ?? "")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(item.japanese ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Test View
struct QuickTestView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: VocabularyItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \VocabularyItem.english, ascending: true)]
    )
    private var allItems: FetchedResults<VocabularyItem>
    
    @State private var currentIndex = 0
    @State private var isAnswerRevealed = false
    @State private var shuffledItems: [VocabularyItem] = []
    
    var currentItem: VocabularyItem? {
        guard shuffledItems.indices.contains(currentIndex) else { return nil }
        return shuffledItems[currentIndex]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if shuffledItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("テストする語彙がありません")
                            .font(.headline)
                        
                        Text("まずリストタブで語彙を追加してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Progress indicator
                    HStack {
                        Text("問題 \(currentIndex + 1) / \(shuffledItems.count)")
                            .font(.headline)
                        
                        Spacer()
                        
                        ProgressView(value: Double(currentIndex + 1), total: Double(shuffledItems.count))
                            .frame(width: 100)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    if let item = currentItem {
                        VStack(spacing: 32) {
                            // Question Card
                            VStack(spacing: 16) {
                                Text("英語は？")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(item.english ?? "")
                                    .font(.system(size: 48, weight: .bold))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color(.systemBlue).opacity(0.1))
                            .cornerRadius(16)
                            
                            // Answer Card - Tap to reveal
                            VStack(spacing: 16) {
                                if isAnswerRevealed {
                                    Text("日本語")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(item.japanese ?? "")
                                        .font(.system(size: 40, weight: .bold))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.green)
                                } else {
                                    Text("タップして答えを表示")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .onTapGesture {
                                withAnimation {
                                    isAnswerRevealed = true
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: previousQuestion) {
                            Label("戻る", systemImage: "chevron.left")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(currentIndex == 0)
                        
                        Button(action: nextQuestion) {
                            Label("次へ", systemImage: "chevron.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("クイックテスト")
            .onAppear {
                shuffleItems()
            }
        }
    }
    
    private func shuffleItems() {
        shuffledItems = Array(allItems).shuffled()
        currentIndex = 0
        isAnswerRevealed = false
    }
    
    private func nextQuestion() {
        withAnimation {
            if currentIndex < shuffledItems.count - 1 {
                currentIndex += 1
                isAnswerRevealed = false
            } else {
                shuffleItems()
            }
        }
    }
    
    private func previousQuestion() {
        withAnimation {
            if currentIndex > 0 {
                currentIndex -= 1
                isAnswerRevealed = false
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @State private var soundEnabled = true
    @State private var showJapaneseFirst = false
    @State private var selectedLanguage = "ja"
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("学習設定")) {
                    Toggle("音声を有効にする", isOn: $soundEnabled)
                    
                    Picker("表示順序", selection: $showJapaneseFirst) {
                        Text("英語を最初に表示").tag(false)
                        Text("日本語を最初に表示").tag(true)
                    }
                }
                
                Section(header: Text("言語設定")) {
                    Picker("言語", selection: $selectedLanguage) {
                        Text("English").tag("en")
                        Text("日本語").tag("ja")
                    }
                }
                
                Section(header: Text("その他")) {
                    HStack {
                        Text("アプリバージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Text("このアプリについて")
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("EITANGOS")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("英単語ズ")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("アプリについて")
                    .font(.headline)
                
                Text("EITANGOSは、効率的に英単語を学習するためのシンプルで使いやすいアプリです。リスト表示、クイックテスト、設定機能を備えています。")
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("このアプリについて")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
