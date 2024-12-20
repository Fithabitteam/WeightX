/*import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct TargetWeightView: View {
    @Binding var currentStep: OnboardingStep
    @AppStorage("targetWeight") private var targetWeight: Double = 0.0
    @AppStorage("weightGoal") private var weightGoal: String = ""
    @State private var weight: String = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Your goal is \(weightGoal)")
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.top)
            
            Text("What's your target weight?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("Enter target weight", text: $weight)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
                .padding()
            
            Text("kg")
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: saveTargetWeight) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Invalid Weight"),
                message: Text("Please enter a valid weight"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveTargetWeight() {
        guard let weightValue = Double(weight),
              weightValue > 0 else {
            showError = true
            return
        }
        
        targetWeight = weightValue
        currentStep = .targetBodyFat
    }
} */
