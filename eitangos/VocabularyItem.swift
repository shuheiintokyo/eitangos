import Foundation

struct VocabularyItem: Identifiable, Codable, Hashable {
    let id: UUID
    let english: String
    let japanese: String
    
    init(english: String, japanese: String) {
        self.id = UUID()
        self.english = english
        self.japanese = japanese
    }
    
    // For Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: VocabularyItem, rhs: VocabularyItem) -> Bool {
        lhs.id == rhs.id
    }
}

// Mock data
let mockVocabularyData: [VocabularyItem] = [
    VocabularyItem(english: "dog", japanese: "犬"),
    VocabularyItem(english: "cat", japanese: "猫"),
    VocabularyItem(english: "apple", japanese: "りんご"),
    VocabularyItem(english: "computer", japanese: "コンピューター"),
    VocabularyItem(english: "school trip", japanese: "課外活動"),
    VocabularyItem(english: "make a shift", japanese: "シフトの作成"),
]
