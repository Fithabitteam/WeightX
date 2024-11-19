//
//  ProfileSettings6.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 01/11/24.
//

import SwiftUI
import Firebase
import HealthKit
import FirebaseAuth

struct ProfileSettings6: View {
    @State private var progress: Double = 1.0 // 100% for the last screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 6
    private var healthStore = HKHealthStore()

    var body: some View {
        VStack {
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()

            Text("Connect WeightX to Apple Health")
                .font(.headline)
                .padding()

            Text("Sync your fitness data seamlessly with Apple Health")
                .font(.subheadline)
                .padding()

            Button(action: connectToAppleHealth) {
                Text("Connect to Apple Health")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .onAppear {
            if lastCompletedPage > 6 {
                navigateToHomeScreen()
            }
        }
        .navigationTitle("Profile Settings 6")
    }

    private func connectToAppleHealth() {
        // Request permission to read and write weight data from Apple Health
        let typesToShare: Set = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
        ]
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                saveCompletionStatusToFirebase()
                navigateToHomeScreen()
            } else {
                // Allow navigation even if permissions are not granted
                print("HealthKit authorization was not fully granted, navigating to home screen.")
                navigateToHomeScreen()
                
                if let error = error {
                    print("Error requesting HealthKit authorization: \(error.localizedDescription)")
                }
            }
        }
    }

    private func saveCompletionStatusToFirebase() {
        // Firebase reference
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Save the last completed page to Firebase
        db.collection("users").document(userId).setData([
            "lastCompletedPage": 6
        ], merge: true) { error in
            if let error = error {
                print("Error saving data: \(error.localizedDescription)")
            } else {
                print("Completion status saved successfully for ProfileSettings6")
            }
        }
    }

    private func navigateToHomeScreen() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UIHostingController(rootView: HomeScreenView())
                window.makeKeyAndVisible()
            } else {
                print("Error: Unable to find a suitable window for navigation.")
            }
        }
    }
}

