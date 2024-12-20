//
//  WeightLog.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 30/11/24.
//
import SwiftUI
import FirebaseFirestore

struct WeightLog: Identifiable {
    let id: String
    let userId: String
    let weight: Double
    let weightUnit: String
    let date: Date
    let tags: [String]
    let notes: String
    let createdAt: Date
    
    var displayWeight: Double {
        UserSettings.shared.weightUnit.convert(weight, from: .kg)
    }
    
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
    
    init(id: String, userId: String, weight: Double, weightUnit: String, date: Date, tags: [String], notes: String, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.weight = weight
        self.weightUnit = weightUnit
        self.date = date
        self.tags = tags
        self.notes = notes
        self.createdAt = createdAt
    }
    
    init(from entry: WeightEntry) {
        self.id = entry.id
        self.userId = entry.userId
        self.weight = entry.weight
        self.weightUnit = entry.weightUnit
        self.date = entry.date
        self.tags = entry.tags
        self.notes = entry.notes
        self.createdAt = entry.createdAt
    }
}
