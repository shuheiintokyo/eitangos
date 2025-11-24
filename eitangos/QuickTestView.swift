import Foundation
import SwiftUI
import CoreData

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

