//
//  UserIntentOfApp.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 20/11/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth

struct UserIntentOfApp: View {
    @State private var showProfileSettings = false
    @State private var showHealthKitScreen = false
    @AppStorage("userIntent") private var userIntent: String = ""
    @Environment(\.presentationMode) var presentationMode
    
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
                        userIntent = "basic"
                        showHealthKitScreen = true
                    }
                )
                
                // Goal-based option
                IntentButton(
                    title: "Goal based approach with guided program",
                    description: "Personalized program based on your goals and progress",
                    action: {
                        userIntent = "guided"
                        showProfileSettings = true
                    }
                )
                
                Spacer()
            }
            .padding()
            .navigationBarBackButtonHidden(true)
        }
        .fullScreenCover(isPresented: $showProfileSettings) {
            ProfileSettings1()
        }
        .fullScreenCover(isPresented: $showHealthKitScreen) {
            ProfileSettings6()
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
