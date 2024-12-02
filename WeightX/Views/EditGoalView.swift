import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditGoalView: View {
    let currentGoal: String
    @State private var selectedGoal: String
    @Environment(\.presentationMode) var presentationMode
    
    init(currentGoal: String) {
        self.currentGoal = currentGoal
        _selectedGoal = State(initialValue: currentGoal)
    }
    
    var body: some View {
        Form {
            Section {
                Button(action: { selectedGoal = "Weight Loss" }) {
                    HStack {
                        Text("Weight Loss")
                        Spacer()
                        if selectedGoal == "Weight Loss" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: { selectedGoal = "Weight Gain" }) {
                    HStack {
                        Text("Weight Gain")
                        Spacer()
                        if selectedGoal == "Weight Gain" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: { selectedGoal = "Maintain Weight" }) {
                    HStack {
                        Text("Maintain Weight")
                        Spacer()
                        if selectedGoal == "Maintain Weight" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Goal")
        .navigationBarItems(trailing: Button("Save") {
            saveGoal()
        })
    }
    
    private func saveGoal() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "weightGoal": selectedGoal
        ]) { error in
            if let error = error {
                print("Error updating goal: \(error)")
                return
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
} 