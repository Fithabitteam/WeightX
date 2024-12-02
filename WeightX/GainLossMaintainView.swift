import SwiftUI
import Firebase
import FirebaseAuth

struct GainLossMaintainView: View {
    @State private var selectedGoal: String = ""
    @State private var showNextScreen = false
    @State private var progress: Double = 0.143 // 1/7
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 1
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                Text("First things first, let me know your goal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    GoalButton(
                        title: "Gain Weight",
                        description: "Build muscle and increase weight in a healthy way",
                        icon: "arrow.up.circle.fill",
                        isSelected: selectedGoal == "Gain Weight"
                    ) {
                        selectedGoal = "Gain Weight"
                    }
                    
                    GoalButton(
                        title: "Lose Weight",
                        description: "Reduce weight and body fat sustainably",
                        icon: "arrow.down.circle.fill",
                        isSelected: selectedGoal == "Lose Weight"
                    ) {
                        selectedGoal = "Lose Weight"
                    }
                    
                    GoalButton(
                        title: "Maintain",
                        description: "Keep current weight and improve body composition",
                        icon: "equal.circle.fill",
                        isSelected: selectedGoal == "Maintain"
                    ) {
                        selectedGoal = "Maintain"
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Continue Button
                Button(action: saveAndContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(selectedGoal.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .disabled(selectedGoal.isEmpty)
            }
            .navigationTitle("Profile Setup (1/7)")
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $showNextScreen) {
                MotivationView(selectedGoal: selectedGoal)
            }
        }
    }
    
    private func saveAndContinue() {
        guard !selectedGoal.isEmpty else { return }
        
        guard let user = Auth.auth().currentUser else { return }
        
        let userData: [String: Any] = [
            "weightGoal": selectedGoal,
            "lastCompletedPage": 1
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData(userData, merge: true)
        
        lastCompletedPage = 1
        showNextScreen = true
    }
}

struct GoalButton: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GainLossMaintainView_Previews: PreviewProvider {
    static var previews: some View {
        GainLossMaintainView()
    }
}

// Keep the GoalButton view as is 
