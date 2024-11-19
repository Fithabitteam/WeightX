//
//  ProfileSettings5.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 01/11/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileSettings5: View {
    @State private var selectedTimeframe: String = ""
    @State private var progress: Double = 0.83 // 83% for the fifth screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 5

    var body: some View {
        VStack {
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()

            Form {
                Section(header: Text("Tell us when do you want to reach your target")) {
                    Button(action: { selectedTimeframe = "In 1-2 months"; saveDataAndNavigate() }) {
                        Text("In 1-2 months (Advanced: 750-1000gms lose/gain per week)")
                    }
                    .padding()

                    Button(action: { selectedTimeframe = "In 2-4 months"; saveDataAndNavigate() }) {
                        Text("In 2-4 months (Intermediate: 500-750gms lose/gain per week)")
                    }
                    .padding()

                    Button(action: { selectedTimeframe = "In 4+ months"; saveDataAndNavigate() }) {
                        Text("In 4+ months (Beginner: 250-500gms lose/gain per week)")
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if lastCompletedPage > 5 {
                navigateToPage(lastCompletedPage)
            }
        }
        .navigationTitle("Profile Settings 5")
    }

    private func saveDataAndNavigate() {
        saveDataToFirebase()
        navigateToNextPage()
    }

    private func saveDataToFirebase() {
        // Firebase reference
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Save data to Firebase
        db.collection("users").document(userId).setData([
            "selectedTimeframe": selectedTimeframe,
            "lastCompletedPage": 5
        ], merge: true) { error in
            if let error = error {
                print("Error saving data: \(error.localizedDescription)")
            } else {
                print("Data saved successfully for ProfileSettings5")
            }
        }
        lastCompletedPage = 6
    }

    private func navigateToNextPage() {
        // Logic to navigate to ProfileSettings6
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = UIHostingController(rootView: ProfileSettings6())
            window.makeKeyAndVisible()
        }
    }

    private func navigateToPage(_ page: Int) {
        switch page {
        case 6:
            navigateToNextPage()
        // Add cases for other pages as needed
        default:
            break
        }
    }
}
