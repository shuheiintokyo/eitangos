import Foundation
import SwiftUI
import CoreData

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
        }
        .padding(.vertical, 8)
    }
}
