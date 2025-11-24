//
//  VocabularyItem+CoreDataProperties.swift
//  eitangos
//
//  Created by Shuhei Kinugasa on 2025/11/24.
//
//

import Foundation
import CoreData

extension VocabularyItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VocabularyItem> {
        return NSFetchRequest<VocabularyItem>(entityName: "VocabularyItem")
    }

    @NSManaged public var english: String?
    @NSManaged public var id: UUID?
    @NSManaged public var japanese: String?

}

extension VocabularyItem : Identifiable {

}
