//
//  ContentView.swift
//  eitangos
//
//  Created by Shuhei Kinugasa on 2025/11/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \VocabularyItem.english, ascending: true)],
        animation: .default)
    private var items: FetchedResults<VocabularyItem>
    
    @State private var appwriteService = AppwriteService()
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Update button at the top
                HStack {
                    Button(action: {
                        updateDataFromCloud()
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                            Text("クラウドから更新")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isUpdating)
                    
                    if isUpdating {
                        ProgressView()
                            .padding(.leading, 10)
                    }
                    
                    Spacer()
                    
                    Text("\(items.count) 単語")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Vocabulary list
                List {
                    ForEach(items) { item in
                        VocabularyRowView(item: item)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("英単語帳")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//            }
            .alert("更新結果", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func updateDataFromCloud() {
        isUpdating = true
        
        Task {
            do {
                let vocabularyItems = try await appwriteService.fetchVocabularyFromCloud()
                
                await MainActor.run {
                    var newCount = 0
                    var updatedCount = 0
                    
                    for vocabData in vocabularyItems {
                        
                        let fetchRequest: NSFetchRequest<VocabularyItem> = VocabularyItem.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "english == %@", vocabData.english)
                        
                        do {
                            let results = try viewContext.fetch(fetchRequest)
                            
                            if let existingItem = results.first {
                                existingItem.japanese = vocabData.japanese
                                updatedCount += 1
                            } else {
                                let newItem = VocabularyItem(context: viewContext)
                                newItem.id = UUID()
                                newItem.english = vocabData.english
                                newItem.japanese = vocabData.japanese
                                newItem.setValue(Date(), forKey: "createdAt")
                                newCount += 1
                            }
                        } catch {
                            print("❌ Error checking existing item: \(error)")
                        }
                    }
                    
                    // Save context
                    do {
                        if viewContext.hasChanges {
                            try viewContext.save()
                            print("💾 Saved to CoreData successfully")
                        }
                        alertMessage = "更新完了！\n新規: \(newCount)件\n更新: \(updatedCount)件"
                    } catch {
                        print("❌ Save error: \(error)")
                        alertMessage = "保存エラー: \(error.localizedDescription)"
                    }
                    
                    isUpdating = false
                    showAlert = true
                }
            } catch {
                print("❌ Fetch error: \(error)")
                await MainActor.run {
                    alertMessage = "クラウドからのデータ取得に失敗しました: \(error.localizedDescription)"
                    isUpdating = false
                    showAlert = true
                }
            }
        }
    }
}

// Improved vocabulary row with equal styling for English and Japanese
struct VocabularyRowView: View {
    let item: VocabularyItem
    
    var body: some View {
        HStack(spacing: 12) {
            // English word
            Text(item.english ?? "")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
//            // Visual separator
//            Text("→")
//                .font(.system(size: 17))
//                .foregroundColor(.secondary)
            
            // Japanese translation (same size and weight)
            Text(item.japanese ?? "")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
}
