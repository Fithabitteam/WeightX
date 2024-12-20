import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserSexView: View {
    @State private var selectedSex: String = ""
    @State private var showNextScreen = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What's your sex?")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Button(action: { selectSex("Male") }) {
                    SexOptionCard(
                        title: "Male",
                        isSelected: selectedSex == "Male"
                    )
                }
                
                Button(action: { selectSex("Female") }) {
                    SexOptionCard(
                        title: "Female",
                        isSelected: selectedSex == "Female"
                    )
                }
            }
            .padding()
            
            Spacer()
            
            Button(action: saveAndDismiss) {
                Text("Save")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(selectedSex.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(selectedSex.isEmpty)
            .padding()
        }
        .navigationTitle("Update Sex")
    }
    
    private func selectSex(_ sex: String) {
        selectedSex = sex
    }
    
    private func saveAndDismiss() {
        guard !selectedSex.isEmpty,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData([
            "sex": selectedSex
        ], merge: true) { error in
            if let error = error {
                print("Error saving sex: \(error)")
                return
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct GoalGuideView: View {
    @State private var selectedGoal: String = ""
    @State private var showNextScreen = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What's your goal?")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Button(action: { selectGoal("Weight Loss") }) {
                    GoalOptionCard(
                        title: "Weight Loss",
                        isSelected: selectedGoal == "Weight Loss"
                    )
                }
                
                Button(action: { selectGoal("Weight Gain") }) {
                    GoalOptionCard(
                        title: "Weight Gain",
                        isSelected: selectedGoal == "Weight Gain"
                    )
                }
                
                Button(action: { selectGoal("Maintain Weight") }) {
                    GoalOptionCard(
                        title: "Maintain Weight",
                        isSelected: selectedGoal == "Maintain Weight"
                    )
                }
            }
            .padding()
            
            Spacer()
            
            Button(action: saveAndDismiss) {
                Text("Save")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(selectedGoal.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(selectedGoal.isEmpty)
            .padding()
        }
        .navigationTitle("Update Goal")
    }
    
    private func selectGoal(_ goal: String) {
        selectedGoal = goal
    }
    
    private func saveAndDismiss() {
        guard !selectedGoal.isEmpty,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData([
            "weightGoal": selectedGoal
        ], merge: true) { error in
            if let error = error {
                print("Error saving goal: \(error)")
                return
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
}

