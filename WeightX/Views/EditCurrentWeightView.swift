import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditCurrentWeightView: View {
    let currentWeight: Double
    let currentBodyFat: Double
    @State private var weight: String = ""
    @State private var bodyFat: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    
    init(currentWeight: Double, currentBodyFat: Double) {
        self.currentWeight = currentWeight
        self.currentBodyFat = currentBodyFat
        
        // Initialize state variables using _weight and _bodyFat
        let displayWeight = weightUnit == .kg ? currentWeight : WeightUnit.lbs.convert(currentWeight, from: .kg)
        _weight = State(initialValue: String(format: "%.1f", displayWeight))
        _bodyFat = State(initialValue: String(format: "%.1f", currentBodyFat))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Current Weight")) {
                HStack {
                    TextField("Enter weight", text: $weight)
                        .keyboardType(.decimalPad)
                    Text(weightUnit.rawValue)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Current Body Fat")) {
                HStack {
                    TextField("Enter body fat", text: $bodyFat)
                        .keyboardType(.decimalPad)
                    Text("%")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(action: saveChanges) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Edit Current Stats")
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Invalid Input"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveChanges() {
        guard let weightValue = Double(weight),
              let bodyFatValue = Double(bodyFat) else {
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
        
        // Convert weight to kg for storage if needed
        let weightInKg = weightUnit == .kg ? weightValue : WeightUnit.kg.convert(weightValue, from: .lbs)
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "currentWeight": weightInKg,
            "currentBodyFat": bodyFatValue
        ]) { error in
            if let error = error {
                print("Error updating stats: \(error)")
                errorMessage = "Failed to save changes"
                showError = true
                return
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
}
