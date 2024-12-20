struct EditGoalView: View {
    let currentGoal: String
    @State private var selectedGoal: String
    @Environment(\.presentationMode) var presentationMode
    
    // Add these constants
    private enum Goal {
        static let lose = "Lose"
        static let gain = "Gain"
        static let maintain = "Maintain"
    }
    
    init(currentGoal: String) {
        self.currentGoal = currentGoal
        _selectedGoal = State(initialValue: currentGoal)
    }
    
    var body: some View {
        Form {
            Section {
                Button(action: { selectedGoal = Goal.lose }) {
                    HStack {
                        Text("Weight Loss")
                        Spacer()
                        if selectedGoal == Goal.lose {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: { selectedGoal = Goal.gain }) {
                    HStack {
                        Text("Weight Gain")
                        Spacer()
                        if selectedGoal == Goal.gain {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Button(action: { selectedGoal = Goal.maintain }) {
                    HStack {
                        Text("Maintain Weight")
                        Spacer()
                        if selectedGoal == Goal.maintain {
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
            "selectedGoal": selectedGoal  // Changed from "weightGoal" to "selectedGoal"
        ]) { error in
            if let error = error {
                print("Error updating goal: \(error)")
                return
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
} 