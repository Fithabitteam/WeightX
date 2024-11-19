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
    @State private var progress: Double = 0.5 // 50% for the third screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 3

    var body: some View {
        VStack {
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()

            Form {
                Section(header: Text("Weight Goal")) {
                    Text("What's your weight goal?")
                    Picker("Select your goal", selection: $selectedGoal) {
                        Text("Gain Weight").tag("Gain Weight")
                        Text("Drop Weight").tag("Drop Weight")
                        Text("Maintain").tag("Maintain")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Button(action: {
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
            if lastCompletedPage > 3 {
                navigateToPage(lastCompletedPage)
            }
        }
        .navigationTitle("Profile Settings 3")
    }

    private func saveDataToFirebase() {
        // Firebase reference
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Save data to Firebase
        db.collection("users").document(userId).setData([
            "weightGoal": selectedGoal,
            "lastCompletedPage": 3
        ], merge: true) { error in
            if let error = error {
                print("Error saving data: \(error.localizedDescription)")
            } else {
                print("Data saved successfully for ProfileSettings3")
            }
        }
        lastCompletedPage = 4
    }

    private func navigateToNextPage() {
        // Logic to navigate to ProfileSettings4
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = UIHostingController(rootView: ProfileSettings4(selectedGoal: selectedGoal))
            window.makeKeyAndVisible()
        }
    }

    private func navigateToPage(_ page: Int) {
        switch page {
        case 4:
            navigateToNextPage()
        // Add cases for other pages as needed
        default:
            break
        }
    }
}
