//
//  QuickTestView.swift
//  eitangos
//
//  Quick test with 10-question limit and scoring
//

import Foundation
import SwiftUI
import CoreData

// MARK: - Quick Test View (10 questions with scoring)
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
    @State private var correctCount = 0
    @State private var showResults = false
    
    private let maxQuestions = 10
    
    var currentItem: VocabularyItem? {
        guard shuffledItems.indices.contains(currentIndex) else { return nil }
        return shuffledItems[currentIndex]
    }
    
    var progress: Double {
        guard !shuffledItems.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(min(shuffledItems.count, maxQuestions))
    }
    
    var totalQuestions: Int {
        min(shuffledItems.count, maxQuestions)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if shuffledItems.isEmpty {
                    emptyStateView
                } else if showResults {
                    resultsView
                } else {
                    // Progress Section
                    VStack(spacing: 12) {
                        HStack {
                            Text("問題 \(currentIndex + 1) / \(totalQuestions)")
                                .font(.headline)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(correctCount)")
                                    .font(.subheadline.bold())
                            }
                        }
                        
                        ProgressView(value: progress)
                            .tint(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    
                    Spacer()
                    
                    if let item = currentItem {
                        testCards(for: item)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    actionButtons
                        .padding()
                }
            }
            .navigationTitle("クイックテスト")
            .onAppear {
                if shuffledItems.isEmpty {
                    startNewTest()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("テストする語彙がありません")
                .font(.title2.bold())
            
            Text("まずリストタブで語彙を追加してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Trophy or result icon
            Image(systemName: correctCount == totalQuestions ? "trophy.fill" : "star.fill")
                .font(.system(size: 80))
                .foregroundColor(correctCount == totalQuestions ? .yellow : .blue)
                .padding(.bottom, 20)
            
            Text("テスト完了！")
                .font(.system(size: 32, weight: .bold))
            
            // Score display
            VStack(spacing: 10) {
                Text("あなたのスコア")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(correctCount)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(scoreColor)
                    
                    Text("/ \(totalQuestions)")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 20)
            
            // Percentage
            Text("\(Int(Double(correctCount) / Double(totalQuestions) * 100))%")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(scoreColor)
            
            // Message
            Text(resultMessage)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 10)
            
            Spacer()
            
            // Restart button
            Button(action: {
                startNewTest()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("もう一度テスト")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    private var scoreColor: Color {
        let percentage = Double(correctCount) / Double(totalQuestions)
        if percentage >= 0.9 {
            return .green
        } else if percentage >= 0.7 {
            return .blue
        } else if percentage >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var resultMessage: String {
        let percentage = Double(correctCount) / Double(totalQuestions)
        if percentage == 1.0 {
            return "完璧です！🎉"
        } else if percentage >= 0.9 {
            return "素晴らしい！"
        } else if percentage >= 0.7 {
            return "よくできました！"
        } else if percentage >= 0.5 {
            return "もう少し頑張りましょう"
        } else {
            return "復習が必要です"
        }
    }
    
    private func testCards(for item: VocabularyItem) -> some View {
        VStack(spacing: 32) {
            // Question Card - WITH TEXT WRAPPING
            VStack(spacing: 16) {
                Text("英語は？")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.english ?? "")
                    .font(.system(size: 44, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)  // ← Allow unlimited lines
                    .fixedSize(horizontal: false, vertical: true)  // ← Allow vertical expansion
                    .minimumScaleFactor(0.5)  // ← Scale down if still too long
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)  // Reduced padding to allow more space for text
            .padding(.horizontal, 20)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // Answer Card - WITH TEXT WRAPPING
            VStack(spacing: 16) {
                if isAnswerRevealed {
                    VStack(spacing: 12) {
                        Text("日本語")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(item.japanese ?? "")
                            .font(.system(size: 40, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.green)
                            .lineLimit(nil)  // ← Allow unlimited lines
                            .fixedSize(horizontal: false, vertical: true)  // ← Allow vertical expansion
                            .minimumScaleFactor(0.5)  // ← Scale down if still too long
                        
                        // Correct/Wrong buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                markCorrect()
                            }) {
                                Label("正解", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                nextQuestion()
                            }) {
                                Label("不正解", systemImage: "xmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.top, 8)
                    }
                } else {
                    Text("タップして答えを表示")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 200)
            .padding(.horizontal, 20)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            .onTapGesture {
                withAnimation(.spring()) {
                    isAnswerRevealed = true
                }
            }
        }
        .padding()
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: previousQuestion) {
                Label("戻る", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            .disabled(currentIndex == 0)
            
            Button(action: nextQuestion) {
                Label("次へ", systemImage: "chevron.right")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isAnswerRevealed)
        }
    }
    
    private func startNewTest() {
        // Take only first 10 items (or all if less than 10)
        let allItemsArray = Array(allItems).shuffled()
        shuffledItems = Array(allItemsArray.prefix(maxQuestions))
        currentIndex = 0
        correctCount = 0
        isAnswerRevealed = false
        showResults = false
    }
    
    private func markCorrect() {
        correctCount += 1
        nextQuestion()
    }
    
    private func nextQuestion() {
        withAnimation {
            if currentIndex < totalQuestions - 1 {
                currentIndex += 1
                isAnswerRevealed = false
            } else {
                // Show results
                showResults = true
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
