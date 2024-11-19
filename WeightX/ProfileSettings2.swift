//
//  ProfileSettings2.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 01/11/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileSettings2: View {
    @State private var bodyFatPercentage: String = ""
    @State private var isShowingPopup: Bool = false
    @State private var progress: Double = 0.333 // 33.3% for the second screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 2

    var body: some View {
        VStack {
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()

            Form {
                Section(header: Text("Body Composition")) {
                    Text("What's your body composition? Enter body fat %")
                    TextField("Body Fat %", text: $bodyFatPercentage)
                        .keyboardType(.decimalPad)

                    Button(action: {
                        isShowingPopup.toggle()
                    }) {
                        Text("Need help figuring out your body fat percent? Click here")
                            .foregroundColor(.blue)
                    }
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
        .overlay(
            // Popup for body fat images
            Group {
                if isShowingPopup {
                    VStack {
                        Image("BodyFatChart") // Replace with your actual image asset
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300)
                        Button("Close") {
                            isShowingPopup = false
                        }
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
                    .edgesIgnoringSafeArea(.all)
                }
            }
        )
        .onAppear {
            if lastCompletedPage > 2 {
                navigateToPage(lastCompletedPage)
            }
        }
        .navigationTitle("Profile Settings 2")
    }

    private func saveDataToFirebase() {
        // Firebase reference
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Save data to Firebase
        db.collection("users").document(userId).setData([
            "bodyFatPercentage": bodyFatPercentage,
            "lastCompletedPage": 2
        ], merge: true) { error in
            if let error = error {
                print("Error saving data: \(error.localizedDescription)")
            } else {
                print("Data saved successfully for ProfileSettings2")
            }
        }
        lastCompletedPage = 3
    }

    private func navigateToNextPage() {
        // Logic to navigate to ProfileSettings3
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = UIHostingController(rootView: ProfileSettings3())
            window.makeKeyAndVisible()
        }
    }

    private func navigateToPage(_ page: Int) {
        switch page {
        case 3:
            navigateToNextPage()
        // Add cases for other pages as needed
        default:
            break
        }
    }
}
