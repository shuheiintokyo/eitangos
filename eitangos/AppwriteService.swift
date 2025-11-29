//
//  AppwriteService.swift
//  eitangos
//
//  Created by Shuhei Kinugasa on 2025/11/24.
//

import Foundation
import Appwrite

struct VocabularyData: Codable, Identifiable {
    let id: String
    let english: String
    let japanese: String
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case english
        case japanese
    }
}

class AppwriteService {
    private let client: Client
    private let databases: Databases
    private let endpoint = "https://cloud.appwrite.io/v1"
    private let projectId = "6923b8ca002785502f73"
    private let databaseId = "6923f7f9000490f509e3"
    private let collectionId = "vocabulary"
    
    init() {
        client = Client()
            .setEndpoint(endpoint)
            .setProject(projectId)
        
        databases = Databases(client)
    }
    
    /// Fetch vocabulary items from Appwrite cloud database
    func fetchVocabularyFromCloud() async throws -> [VocabularyData] {
        do {
            let response = try await databases.listDocuments(
                databaseId: databaseId,
                collectionId: collectionId,
                queries: [
                    Query.limit(1000),
                    Query.orderAsc("english")
                ]
            )
            var vocabularyItems: [VocabularyData] = []
            
            for (index, document) in response.documents.enumerated() {
                // Get the values as Any
                guard let englishAny = document.data["english"],
                      let japaneseAny = document.data["japanese"] else {
                    print("   ❌ Document \(index): Missing fields")
                    continue
                }
                
                // Convert to String using description
                let english = "\(englishAny)"
                let japanese = "\(japaneseAny)"
                
                // Remove "Optional(" wrapper if present
                let cleanEnglish = english
                    .replacingOccurrences(of: "Optional(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                let cleanJapanese = japanese
                    .replacingOccurrences(of: "Optional(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                let vocab = VocabularyData(
                    id: document.id,
                    english: cleanEnglish,
                    japanese: cleanJapanese
                )
                vocabularyItems.append(vocab)
            }
            
            print("✅ Successfully parsed \(vocabularyItems.count) items")
            return vocabularyItems
            
        } catch {
            print("❌ Error fetching from Appwrite: \(error)")
            throw error
        }
    }
}
