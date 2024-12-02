//
//  UserIntentOfApp.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 21/11/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct UserIntentOfApp: View {
    @State private var showProfileSettings = false
    @State private var showHealthKitScreen = false
    @AppStorage("userIntent") private var userIntent: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Text("Choose your intent")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                // Basic tracking option
                IntentButton(
                    title: "Log, track, analyse and get insights",
                    description: "Simple weight tracking with analytics and trends",
                    action: {
                        saveUserIntent(intent: "logger")
                    }
                )
                
                // Goal-based option
                IntentButton(
                    title: "Goal based approach with guided program",
                    description: "Personalized program based on your goals and progress",
                    action: {
                        saveUserIntent(intent: "goalguide")
                    }
                )
                
                Spacer()
            }
            .padding()
            .navigationBarBackButtonHidden(true)
        }
        .fullScreenCover(isPresented: $showProfileSettings) {
            GainLossMaintainView()
        }
        .fullScreenCover(isPresented: $showHealthKitScreen) {
            HealthKitView()
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveUserIntent(intent: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            showError = true
            return
        }
        
        let userData: [String: Any] = [
            "userIntent": intent,
            "intentSelectedAt": Timestamp(),
            "lastUpdated": Timestamp()
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData(userData, merge: true) { error in
            if let error = error {
                errorMessage = "Failed to save preference: \(error.localizedDescription)"
                showError = true
                return
            }
            
            // Save to local storage
            userIntent = intent
            
            // Navigate based on selection
            DispatchQueue.main.async {
                if intent == "logger" {
                    showHealthKitScreen = true
                } else {
                    showProfileSettings = true
                }
            }
        }
    }
}

struct IntentButton: View {
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UserIntentOfApp_Previews: PreviewProvider {
    static var previews: some View {
        UserIntentOfApp()
    }
}
