import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditTargetView: View {
    let currentWeight: Double
    let currentBodyFat: Double
    @State private var targetWeight: String
    @State private var targetBodyFat: String
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    init(currentWeight: Double, currentBodyFat: Double) {
        self.currentWeight = currentWeight
        self.currentBodyFat = currentBodyFat
        _targetWeight = State(initialValue: String(format: "%.1f", currentWeight))
        _targetBodyFat = State(initialValue: String(format: "%.1f", currentBodyFat))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Target Weight")) {
                HStack {
                    TextField("Enter target weight", text: $targetWeight)
                        .keyboardType(.decimalPad)
                    Text("kg")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Target Body Fat")) {
                HStack {
                    TextField("Enter target body fat", text: $targetBodyFat)
                        .keyboardType(.decimalPad)
                    Text("%")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                 to: nil, 
                                                 from: nil, 
                                                 for: nil)
                    saveTargets()
                }) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Edit Targets")
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Invalid Input"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveTargets() {
        guard let weightValue = Double(targetWeight),
              let bodyFatValue = Double(targetBodyFat) else {
            errorMessage = "Please enter valid numbers"
            showError = true
            return
        }
        
        guard weightValue > 0 else {
            errorMessage = "Weight must be greater than 0"
            showError = true
            return
        }
        
        guard bodyFatValue >= 0 && bodyFatValue <= 100 else {
            errorMessage = "Body fat percentage must be between 0 and 100"
            showError = true
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "targetWeight": weightValue,
            "targetBodyFat": bodyFatValue
        ]) { error in
            if let error = error {
                print("Error updating targets: \(error)")
                errorMessage = "Failed to save changes"
                showError = true
                return
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EditTargetView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditTargetView(currentWeight: 70.0, currentBodyFat: 20.0)
        }
    }
} 
