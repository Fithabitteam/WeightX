import SwiftUI
import Firebase
import FirebaseAuth

struct UserCurrentView: View {
    let selectedGoal: String
    let userSex: String
    let motivations: [String]
    @State private var currentWeight: String = ""
    @State private var bodyFatPercentage: String = ""
    @State private var isKg: Bool = true
    @State private var showingBFGuide = false
    @State private var showNextScreen = false
    @State private var progress: Double = 0.666 // 66.6% for fourth screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 4
    
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
                BodyFatGuideView(userSex: userSex)
            }
            .fullScreenCover(isPresented: $showNextScreen) {
                UserTargetView(
                    selectedGoal: selectedGoal,
                    userSex: userSex,
                    motivations: motivations
                )
            }
        }
    }
    
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
}

struct BodyFatGuideView: View {
    let userSex: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Image(userSex == "Male" ? "male_bodyfat_guide" : "female_bodyfat_guide")
                    .resizable()
                    .scaledToFit()
                    .padding()
                
                Text("Body Fat Percentage Reference Guide")
                    .font(.headline)
                    .padding()
                
                Text("This is a visual guide to help estimate your body fat percentage. For accurate measurements, consider using professional methods like DEXA scan or calipers.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationBarItems(
                trailing: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct UserCurrentView_Previews: PreviewProvider {
    static var previews: some View {
        UserCurrentView(selectedGoal: "Lose Weight", userSex: "Male", motivations: [])
    }
} 