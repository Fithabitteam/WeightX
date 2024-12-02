import Foundation
import FirebaseFirestore

struct WeightEntry {
    let id: String
    let userId: String
    let weight: Double
    let date: Date
    let weightUnit: WeightUnit
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
    
    init(id: String, weight: Double, date: Date, userId: String = "") {
        self.id = id
        self.userId = userId
        self.weight = weight
        self.date = date
        self.weightUnit = .kg
        self.tags = []
        self.notes = ""
        self.createdAt = Date()
    }
    
    init(forGraph id: String = UUID().uuidString, weight: Double, date: Date) {
        self.id = id
        self.userId = ""
        self.weight = weight
        self.date = date
        self.weightUnit = .kg
        self.tags = []
        self.notes = ""
        self.createdAt = date
    }
} 