//
//  MainTabView.swift
//  eitangos
//
//  Updated version without audio, with 10-question limit and scoring
//

import SwiftUI
import CoreData

// MARK: - Main Tab View
struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            VocabularyListViewWithSync()
                .tabItem {
                    Label("リスト", systemImage: "list.bullet")
                }
            
            EnhancedQuickTestView()
                .tabItem {
                    Label("テスト", systemImage: "brain.head.profile")
                }
            
            EnhancedSettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
    }
}

// MARK: - Enhanced List View with Stats
struct VocabularyListViewWithSync: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: VocabularyItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \VocabularyItem.english, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<VocabularyItem>
    
    @State private var appwriteService = AppwriteService()
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var searchText = ""
    @State private var lastSyncDate: Date?
    
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
            VStack(spacing: 0) {
                // Stats Card
                statsCard
                    .padding()
                
                // Cloud sync button
                HStack {
                    Button(action: updateDataFromCloud) {
                        HStack {
                            Image(systemName: isUpdating ? "arrow.clockwise" : "icloud.and.arrow.down")
                                .rotationEffect(isUpdating ? .degrees(360) : .degrees(0))
                                .animation(isUpdating ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isUpdating)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("クラウドから更新")
                                    .font(.system(size: 15, weight: .semibold))
                                
                                if let lastSync = lastSyncDate {
                                    Text("最終: \(formatDate(lastSync))")
                                        .font(.caption2)
                                        .opacity(0.8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isUpdating)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                
                // Vocabulary list
                if items.isEmpty {
                    emptyStateView
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
            .navigationTitle("英単語帳")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .searchable(text: $searchText, prompt: "単語を検索")
            .alert("更新結果", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
            }
        }
    }
    
    private var statsCard: some View {
        HStack(spacing: 20) {
            StatItem(icon: "book.fill", value: "\(items.count)", label: "総単語数")
            
            Divider()
                .frame(height: 40)
            
            StatItem(icon: "chart.line.uptrend.xyaxis", value: "\(todayAdded)", label: "今日追加")
            
            Divider()
                .frame(height: 40)
            
            StatItem(icon: "star.fill", value: "\(items.count)", label: "学習中")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var todayAdded: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return items.filter { item in
            guard let createdAt = item.value(forKey: "createdAt") as? Date else { return false }
            return calendar.isDate(createdAt, inSameDayAs: today)
        }.count
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.5))
            
            Text("語彙がありません")
                .font(.title2.bold())
            
            Text("「クラウドから更新」をタップして\n単語を読み込んでください")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting item: \(error)")
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
                            print("Error checking existing item: \(error)")
                        }
                    }
                    
                    do {
                        if viewContext.hasChanges {
                            try viewContext.save()
                        }
                        lastSyncDate = Date()
                        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
                        alertMessage = "更新完了！\n新規: \(newCount)件\n更新: \(updatedCount)件"
                    } catch {
                        alertMessage = "保存エラー: \(error.localizedDescription)"
                    }
                    
                    isUpdating = false
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "クラウドからのデータ取得に失敗しました: \(error.localizedDescription)"
                    isUpdating = false
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2.bold())
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

//// MARK: - Vocabulary Row (without audio)
//struct VocabularyRow: View {
//    let item: VocabularyItem
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            // Words
//            HStack(spacing: 12) {
//                Text(item.english ?? "")
//                    .font(.system(size: 17, weight: .medium))
//                    .foregroundColor(.primary)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                
//                Text("→")
//                    .font(.system(size: 17))
//                    .foregroundColor(.secondary)
//                
//                Text(item.japanese ?? "")
//                    .font(.system(size: 17, weight: .medium))
//                    .foregroundColor(.primary)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//        }
//        .padding(.vertical, 8)
//    }
//}

// MARK: - Enhanced Quick Test View (10 questions, with scoring)
struct EnhancedQuickTestView: View {
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
            // Question Card
            VStack(spacing: 16) {
                Text("英語は？")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.english ?? "")
                    .font(.system(size: 44, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // Answer Card
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

// MARK: - Enhanced Settings View (without audio settings)
struct EnhancedSettingsView: View {
    @State private var showJapaneseFirst = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("学習設定")) {
                    Toggle(isOn: $showJapaneseFirst) {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundColor(.blue)
                            Text("日本語を最初に表示")
                        }
                    }
                }
                
                Section(header: Text("アプリ情報")) {
                    HStack {
                        Text("アプリバージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("このアプリについて")
                        }
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

// MARK: - About View
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
