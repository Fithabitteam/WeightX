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
    @State private var progress: Double = 0.67 // 67% for the fourth screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 4
    var selectedGoal: String

    var body: some View {
        VStack {
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()

            Form {
                Section(header: Text("Target Weight")) {
                    TextField("Enter current weight", text: $currentWeight)
                        .keyboardType(.decimalPad)

                    if selectedGoal != "Maintain" {
                        TextField("Enter target weight", text: $targetWeight)
                            .keyboardType(.decimalPad)
                    } else {
                        Text("Target weight will be set to current weight")
                    }

                    Toggle("Use Kg", isOn: $useKg)
                }

                Button(action: {
                    if selectedGoal == "Maintain" {
                        targetWeight = currentWeight // Assign targetWeight if maintaining
                    }
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
            if lastCompletedPage > 4 {
                navigateToPage(lastCompletedPage)
            }
        }
        .navigationTitle("Profile Settings 4")
    }

    private func saveDataToFirebase() {
        // Firebase reference
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Save data to Firebase
        db.collection("users").document(userId).setData([
            "currentWeight": currentWeight,
            "targetWeight": targetWeight,
            "useKg": useKg,
            "lastCompletedPage": 4
        ], merge: true) { error in
            if let error = error {
                print("Error saving data: \(error.localizedDescription)")
            } else {
                print("Data saved successfully for ProfileSettings4")
            }
        }
        lastCompletedPage = 5
    }

    private func navigateToNextPage() {
        // Logic to navigate to ProfileSettings5
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = UIHostingController(rootView: ProfileSettings5())
            window.makeKeyAndVisible()
        }
    }

    private func navigateToPage(_ page: Int) {
        switch page {
        case 5:
            navigateToNextPage()
        // Add cases for other pages as needed
        default:
            break
        }
    }
}
