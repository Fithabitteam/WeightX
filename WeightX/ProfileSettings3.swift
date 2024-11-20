//
//  ProfileSettings3.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 01/11/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileSettings3: View {
    @State private var selectedGoal: String = ""
    @State private var showProfileSettings4 = false
    @State private var progress: Double = 0.5 // 50% for third screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                Form {
                    Section(header: Text("Weight Goal")) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What's your weight goal?")
                                .font(.headline)
                            
                            GoalButton(title: "Gain Weight",
                                     description: "Build muscle and increase weight",
                                     isSelected: selectedGoal == "Gain Weight") {
                                selectedGoal = "Gain Weight"
                                saveAndContinue()
                            }
                            
                            GoalButton(title: "Drop Weight",
                                     description: "Lose fat and decrease weight",
                                     isSelected: selectedGoal == "Drop Weight") {
                                selectedGoal = "Drop Weight"
                                saveAndContinue()
                            }
                            
                            GoalButton(title: "Maintain",
                                     description: "Maintain current weight and body composition",
                                     isSelected: selectedGoal == "Maintain") {
                                selectedGoal = "Maintain"
                                saveAndContinue()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile Setup (3/6)")
            .fullScreenCover(isPresented: $showProfileSettings4) {
                ProfileSettings4(selectedGoal: selectedGoal)
            }
        }
    }
    
    private func saveAndContinue() {
        guard !selectedGoal.isEmpty else { return }
        
        // Save to Firebase
        guard let user = Auth.auth().currentUser else { return }
        
        let userData: [String: Any] = [
            "weightGoal": selectedGoal,
            "lastCompletedPage": 3
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData(userData, merge: true)
        
        // Update completion status and navigate
        lastCompletedPage = 3
        showProfileSettings4 = true
    }
}

struct GoalButton: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
