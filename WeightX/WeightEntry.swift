//
//  WeightEntry.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 24/11/24.
//
import Foundation
import FirebaseFirestore

struct WeightEntry {
    let id: String
    let userId: String
    let weight: Double
    let weightUnit: String
    let date: Date
    let tags: [String]
    let notes: String
    let createdAt: Date
    
    init?(from document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let userId = data["userId"] as? String,
              let weight = data["weight"] as? Double,
              let timestamp = data["date"] as? Timestamp else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.weight = weight
        self.weightUnit = data["weightUnit"] as? String ?? "kg"
        self.date = timestamp.dateValue()
        self.tags = data["tags"] as? [String] ?? []
        self.notes = data["notes"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? timestamp.dateValue()
    }
}
