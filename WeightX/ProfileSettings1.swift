//
//  ProfileSettingPage1.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 31/10/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileSettings1: View {
    @State private var name: String = ""
    @AppStorage("userName") private var storedName: String = ""
    @State private var height: String = ""
    @State private var isHeightInCM: Bool = true
    @State private var selectedSex: String = "Male"
    @State private var birthDate = Date()
    @State private var showProfileSettings2 = false
    @State private var progress: Double = 0.166 // 16.6% for first screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 1
    
    let sexOptions = ["Male", "Female", "Other"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress Bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                Form {
                    // Basic Information Section
                    Section(header: Text("Basic Information")) {
                        TextField("Full Name", text: $name)
                            .textContentType(.name)
                        
                        DatePicker("Date of Birth",
                                 selection: $birthDate,
                                 in: ...Date(),
                                 displayedComponents: .date)
                        
                        Picker("Sex", selection: $selectedSex) {
                            ForEach(sexOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                    }
                    
                    // Height Section
                    Section(header: Text("Height")) {
                        HStack {
                            TextField("Height", text: $height)
                                .keyboardType(.decimalPad)
                            
                            Picker("Unit", selection: $isHeightInCM) {
                                Text("cm").tag(true)
                                Text("ft").tag(false)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 100)
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
            }
            .navigationTitle("Profile Setup (1/6)")
            .fullScreenCover(isPresented: $showProfileSettings2) {
                ProfileSettings2()
            }
        }
    }
    
    private func saveAndContinue() {
        // Validate inputs
        guard !name.isEmpty, !height.isEmpty else { return }
        
        // Save to UserDefaults
        storedName = name
        lastCompletedPage = 1
        
        // Save to Firebase (implementation needed)
        saveToFirebase()
        
        // Navigate to next screen
        showProfileSettings2 = true
    }
    
    private func saveToFirebase() {
        guard let user = Auth.auth().currentUser else { return }
        
        let userData: [String: Any] = [
            "name": name,
            "dateOfBirth": birthDate,
            "sex": selectedSex,
            "height": height,
            "heightUnit": isHeightInCM ? "cm" : "ft",
            "lastCompletedPage": 1
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData(userData, merge: true) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            }
        }
    }
}
