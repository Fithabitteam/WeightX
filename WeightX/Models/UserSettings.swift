import SwiftUI
import FirebaseFirestore

enum WeightUnit: String, Codable {
    case kg
    case lbs
    
    func convert(_ weight: Double, from: WeightUnit) -> Double {
        if self == from { return weight }
        if self == .kg { return weight / 2.20462 } // lbs to kg
        return weight * 2.20462 // kg to lbs
    }
}

class UserSettings {
    static let shared = UserSettings()
    
    @AppStorage("weightUnit") private(set) var weightUnit: WeightUnit = .kg
    
    func setWeightUnit(_ unit: WeightUnit) {
        weightUnit = unit
        saveWeightUnitToUser(unit)
    }
    
    private func saveWeightUnitToUser(_ unit: WeightUnit) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "weightUnit": unit.rawValue,
            "updatedAt": Timestamp()
        ]
        
        db.collection("users").document(userId).setData(data, merge: true) { error in
            if let error = error {
                print("Error saving weight unit: \(error)")
            } else {
                print("Weight unit saved successfully: \(unit.rawValue)")
            }
        }
    }
    
    func loadWeightUnitFromUser() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error loading weight unit: \(error)")
                return
            }
            
            if let data = snapshot?.data(),
               let unitString = data["weightUnit"] as? String,
               let unit = WeightUnit(rawValue: unitString) {
                DispatchQueue.main.async {
                    self.weightUnit = unit
                    print("Weight unit loaded from user: \(unit.rawValue)")
                }
            } else {
                // Set default unit and save it for new users
                self.setWeightUnit(.kg)
                print("No weight unit found, setting default to kg")
            }
        }
    }
    
    func formatWeight(_ weight: Double) -> String {
        let convertedWeight = weightUnit.convert(weight, from: .kg)
        return String(format: "%.1f %@", convertedWeight, weightUnit.rawValue)
    }
} 