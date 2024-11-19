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
    @State private var birthDate: Date = Date()
    let sexOptions = ["Male", "Female", "Other"]
    @State private var progress: Double = 0.166 // 16.6% for the first screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 1

    var body: some View {
        VStack {
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()

            Form {
                
                Section(header: Text("Name")) {
                    TextField("Enter your name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Sex")) {
                    Picker("Select your sex", selection: $selectedSex) {
                        ForEach(sexOptions, id: \.self) { sex in
                            Text(sex).tag(sex)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section(header: Text("Birthday")) {
                    DatePicker("Select your birthdate", selection: $birthDate, displayedComponents: .date)
                }
                
                // Height field
                Section(header: Text("Height")) {
                    TextField("Enter your height", text: $height)
                        .keyboardType(.decimalPad)
                    Toggle(isOn: $isHeightInCM) {
                        Text("Use metric units (cm)")
                    }
                }
            
                Button(action: {
                    storedName = name
                    saveDataToFirebase()
                    navigateToNextPage()
                }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
        }
        .onAppear {
            if lastCompletedPage > 1 {
                navigateToPage(lastCompletedPage)
            }
        }
        .navigationTitle("Profile Settings 1")
    }

    private func saveDataToFirebase() {
        // Firebase reference
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Save data to Firebase
        db.collection("users").document(userId).setData([
            "name": name,
            "sex": selectedSex,
            "birthday": birthDate,
            "height": height,
            "isHeightInCM": isHeightInCM,
            "lastCompletedPage": 1
        ], merge: true) { error in
            if let error = error {
                print("Error saving data: \(error.localizedDescription)")
            } else {
                print("Data saved successfully for ProfileSettings1")
            }
        }
        lastCompletedPage = 2
    }

    private func navigateToNextPage() {
        // Logic to navigate to ProfileSettings2
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = UIHostingController(rootView: ProfileSettings2())
            window.makeKeyAndVisible()
        }
    }

    private func navigateToPage(_ page: Int) {
        switch page {
        case 2:
            navigateToNextPage()
        // Add cases for other pages as needed
        default:
            break
        }
    }
}
