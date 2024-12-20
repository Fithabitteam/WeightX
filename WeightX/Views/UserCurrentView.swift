import SwiftUI
import Firebase
import FirebaseAuth

struct UserCurrentView: View {
    let selectedGoal: String
    let userSex: String
    let motivations: [String]
    let height: Double
    @State private var currentWeight: String = ""
    @State private var bodyFatPercentage: String = ""
    @State private var isKg: Bool = true
    @State private var showingBFGuide = false
    @State private var showNextScreen = false
    @State private var progress: Double = 0.666 // 66.6% for fourth screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 4
    
    private var isInputValid: Bool {
        guard let weight = Double(currentWeight),
              let bodyFat = Double(bodyFatPercentage) else {
            return false
        }
        return weight > 0 && bodyFat >= 0 && bodyFat <= 100
    }
    
    private func saveAndContinue() {
        guard isInputValid else { return }
        
        guard let user = Auth.auth().currentUser else { return }
        
        let userData: [String: Any] = [
            "currentWeight": Double(currentWeight) ?? 0,
            "weightUnit": isKg ? "kg" : "lbs",
            "bodyFatPercentage": Double(bodyFatPercentage) ?? 0,
            "lastCompletedPage": 4
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData(userData, merge: true) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
                return
            }
            
            lastCompletedPage = 4
            showNextScreen = true
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Hmm.. Let me know where we are now")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        // Current Weight Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Weight")
                                .font(.headline)
                            
                            HStack {
                                TextField("Enter weight", text: $currentWeight)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Picker("Unit", selection: $isKg) {
                                    Text("kg").tag(true)
                                    Text("lbs").tag(false)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 100)
                            }
                        }
                        
                        // Body Fat Percentage Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Body Fat %")
                                .font(.headline)
                            
                            HStack {
                                TextField("Enter body fat", text: $bodyFatPercentage)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Text("%")
                                    .foregroundColor(.secondary)
                            }
                            
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
            .navigationTitle("Profile Setup (4/6)")
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showingBFGuide) {
                NavigationView {
                    BodyFatGuideView(userSex: userSex)
                }
            }
            .fullScreenCover(isPresented: $showNextScreen) {
                UserTargetView(
                    currentWeight: Double(currentWeight) ?? 0,
                    currentBF: Double(bodyFatPercentage) ?? 0,
                    height: height,
                    sex: userSex,
                    selectedGoal: selectedGoal,
                    motivations: motivations
                )
            }
        }
    }
}

// Preview
struct UserCurrentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserCurrentView(
                selectedGoal: "Weight Loss",
                userSex: "male",
                motivations: ["Motivation 1", "Motivation 2"],
                height: 0
            )
        }
    }
} 
