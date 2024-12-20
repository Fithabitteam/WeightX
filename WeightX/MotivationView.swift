import SwiftUI
import Firebase
import FirebaseAuth

struct MotivationView: View {
    let selectedGoal: String
    @State private var selectedMotivations: Set<String> = []
    @State private var customMotivation: String = ""
    @State private var showNextScreen = false
    @State private var progress: Double = 0.333 // 33.3% for second screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 2
    
    let predefinedMotivations = [
        "Prepare for social event",
        "Keeping up with friends",
        "Improving overall health",
        "To look and feel good",
        "Training for a sport",
        "To make fitness your hobby"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("What motivates you to work towards your goal?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        Text("Select all that apply")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Predefined motivations
                        VStack(spacing: 12) {
                            ForEach(predefinedMotivations, id: \.self) { motivation in
                                MotivationButton(
                                    title: motivation,
                                    isSelected: selectedMotivations.contains(motivation)
                                ) {
                                    toggleMotivation(motivation)
                                }
                            }
                        }
                        
                        // Custom motivation input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Other motivation")
                                .font(.headline)
                            
                            TextField("Enter your motivation", text: $customMotivation)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: customMotivation) { newValue in
                                    if !newValue.isEmpty {
                                        selectedMotivations.insert(newValue)
                                    }
                                }
                        }
                        .padding(.top)
                    }
                    .padding()
                }
                
                // Continue Button
                Button(action: saveAndContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(!selectedMotivations.isEmpty ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .disabled(selectedMotivations.isEmpty)
            }
            .navigationTitle("Profile Setup (2/6)")
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $showNextScreen) {
                PersonalInfoView(selectedGoal: selectedGoal, motivations: Array(selectedMotivations))
            }
        }
    }
    
    private func toggleMotivation(_ motivation: String) {
        if selectedMotivations.contains(motivation) {
            selectedMotivations.remove(motivation)
        } else {
            selectedMotivations.insert(motivation)
        }
    }
    
    private func saveAndContinue() {
        guard !selectedMotivations.isEmpty else { return }
        
        // Save to Firebase
        guard let user = Auth.auth().currentUser else { return }
        
        var motivations = Array(selectedMotivations)
        if !customMotivation.isEmpty && !motivations.contains(customMotivation) {
            motivations.append(customMotivation)
        }
        
        let userData: [String: Any] = [
            "motivations": motivations,
            "lastCompletedPage": 2
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData(userData, merge: true)
        
        // Update completion status and navigate
        lastCompletedPage = 2
        showNextScreen = true
    }
}

