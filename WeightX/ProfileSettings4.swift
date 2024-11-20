//
//  ProfileSettings4.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 01/11/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileSettings4: View {
    @State private var currentWeight: String = ""
    @State private var targetWeight: String = ""
    @State private var useKg: Bool = true
    @State private var showProfileSettings5 = false
    @State private var progress: Double = 0.67 // 67% for fourth screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 4
    let selectedGoal: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                Form {
                    Section(header: Text("Current Weight")) {
                        HStack {
                            TextField("Enter current weight", text: $currentWeight)
                                .keyboardType(.decimalPad)
                            
                            Picker("Unit", selection: $useKg) {
                                Text("kg").tag(true)
                                Text("lbs").tag(false)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 100)
                        }
                    }
                    
                    Section(header: Text("Target Weight")) {
                        HStack {
                            TextField("Enter target weight", text: $targetWeight)
                                .keyboardType(.decimalPad)
                            
                            Text(useKg ? "kg" : "lbs")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Continue Button
                Button(action: saveAndContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .disabled(!isValidInput)
            }
            .navigationTitle("Profile Setup (4/6)")
            .fullScreenCover(isPresented: $showProfileSettings5) {
                ProfileSettings5()
            }
        }
    }
    
    private var isValidInput: Bool {
        guard let current = Double(currentWeight),
              let target = Double(targetWeight) else {
            return false
        }
        return current > 0 && target > 0
    }
    
    private func saveAndContinue() {
        guard isValidInput else { return }
        
        // Save to Firebase
        guard let user = Auth.auth().currentUser else { return }
        
        let userData: [String: Any] = [
            "currentWeight": Double(currentWeight) ?? 0,
            "targetWeight": Double(targetWeight) ?? 0,
            "weightUnit": useKg ? "kg" : "lbs",
            "lastCompletedPage": 4
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData(userData, merge: true)
        
        // Update completion status and navigate
        lastCompletedPage = 4
        showProfileSettings5 = true
    }
}
