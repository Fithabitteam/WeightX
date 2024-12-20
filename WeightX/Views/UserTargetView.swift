import SwiftUI
import Firebase
import FirebaseAuth

// Add this extension for placeholder functionality
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 0.65 : 0)
            self
        }
    }
}

struct UserTargetView: View {
    @State private var targetWeight: String = ""
    @State private var targetBF: String = ""
    @State private var suggestedWeight: Double = 0
    @State private var suggestedBF: Double = 0
    @State private var isKg: Bool = true
    let currentWeight: Double
    let currentBF: Double
    let height: Double
    let sex: String
    let selectedGoal: String
    let motivations: [String]
    @State private var showingBFGuide = false
    @State private var showNextScreen = false
    @State private var progress: Double = 0.714 // Changed from 0.833 to 0.714 (5/7)
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 5
    
    // Add isInputValid property
    private var isInputValid: Bool {
        guard let weight = Double(targetWeight),
              let bodyFat = Double(targetBF) else {
            return false
        }
        return weight > 0 && bodyFat >= 0 && bodyFat <= 100
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress bar (5/7)
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Goal Text
                        Text("Your goal is \(selectedGoal)")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.top)
                        
                        Text("Now let's talk about where we want to be")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Target Weight with suggestion and unit picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Weight")
                                .font(.headline)
                            
                            HStack {
                                TextField("Enter target weight", text: $targetWeight)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .placeholder(when: targetWeight.isEmpty) {
                                        Text("\(String(format: "%.1f", suggestedWeight)) kg")
                                            .foregroundColor(.gray)
                                    }
                                
                                Picker("Unit", selection: $isKg) {
                                    Text("kg").tag(true)
                                    Text("lbs").tag(false)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 100)
                            }
                            
                            Text("Suggested weight for you is \(String(format: "%.1f", suggestedWeight)) kg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Target BF% with suggestion
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Body Fat %")
                                .font(.headline)
                            
                            HStack {
                                TextField("Enter target body fat", text: $targetBF)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .placeholder(when: targetBF.isEmpty) {
                                        Text("\(String(format: "%.1f", suggestedBF))%")
                                            .foregroundColor(.gray)
                                    }
                                
                                Text("%")
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Suggested body fat % for you is \(String(format: "%.1f", suggestedBF))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: { showingBFGuide = true }) {
                                Text("Don't know your BF%? Don't worry, click to see some reference")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .padding()
                }
                
                // Continue Button
                Button(action: saveAndContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(isInputValid ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .disabled(!isInputValid)
            }
            .navigationTitle("Profile Setup (5/7)")
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showingBFGuide) {
                BodyFatGuideView(userSex: sex)
            }
            .fullScreenCover(isPresented: $showNextScreen) {
                GoalTimelineView(
                    selectedGoal: selectedGoal,
                    userMotivations: motivations,
                    currentWeight: currentWeight,
                    targetWeight: Double(targetWeight) ?? 0
                )
            }
            .onAppear {
                calculateSuggestedValues()
            }
        }
    }
    
    private func saveAndContinue() {
        guard isInputValid else { return }
        
        guard let user = Auth.auth().currentUser else { return }
        
        let userData: [String: Any] = [
            "targetWeight": Double(targetWeight) ?? 0,
            "targetWeightUnit": isKg ? "kg" : "lbs",
            "targetBodyFat": Double(targetBF) ?? 0,
            "lastCompletedPage": 5
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData(userData, merge: true) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
                return
            }
            
            lastCompletedPage = 5
            showNextScreen = true
        }
    }
    
    private func calculateSuggestedValues() {
        // Calculate suggested weight based on BMI and goal
        let heightInMeters = height / 100
        let normalBMI: Double
        
        // Adjust BMI based on sex
        if sex.lowercased() == "male" {
            normalBMI = 22.5 // Middle of healthy BMI range for men
        } else {
            normalBMI = 21.5 // Middle of healthy BMI range for women
        }
        
        let baseWeight = normalBMI * (heightInMeters * heightInMeters)
        
        // Adjust based on goal
        switch selectedGoal.lowercased() {
        case "weight loss":
            // Suggest either 10% loss or healthy BMI weight, whichever is higher
            suggestedWeight = max(currentWeight * 0.9, baseWeight)
        case "weight gain":
            // Suggest either 10% gain or healthy BMI weight, whichever is lower
            suggestedWeight = min(currentWeight * 1.1, baseWeight)
        default:
            // For maintenance, suggest healthy BMI weight
            suggestedWeight = baseWeight
        }
        
        // Calculate suggested BF% based on sex and goal
        if sex.lowercased() == "male" {
            switch selectedGoal.lowercased() {
            case "weight loss":
                suggestedBF = 12.0 // Athletic range for men
            case "weight gain":
                suggestedBF = 15.0 // Fitness range for men
            default:
                suggestedBF = 15.0 // Healthy range for men
            }
        } else {
            switch selectedGoal.lowercased() {
            case "weight loss":
                suggestedBF = 21.0 // Athletic range for women
            case "weight gain":
                suggestedBF = 25.0 // Fitness range for women
            default:
                suggestedBF = 25.0 // Healthy range for women
            }
        }
    }
}

// Update preview
struct UserTargetView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserTargetView(
                currentWeight: 80.0,
                currentBF: 25.0,
                height: 175.0,
                sex: "male",
                selectedGoal: "Weight Loss",
                motivations: ["Health", "Fitness"]
            )
        }
    }
}

// Note: We're reusing the BodyFatGuideView from UserCurrentView 
