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
    @State private var showingInfoPopup = false
    @State private var showProfileSettings3 = false
    @State private var progress: Double = 0.333 // 33.3% for second screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 2
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress Bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                Form {
                    Section(header: Text("Body Composition")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What's your body fat percentage?")
                                .font(.headline)
                            
                            HStack {
                                TextField("Body Fat %", text: $bodyFatPercentage)
                                    .keyboardType(.decimalPad)
                                
                                Text("%")
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: { showingInfoPopup = true }) {
                                Label("How to measure body fat?", systemImage: "info.circle")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
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
            .navigationTitle("Profile Setup (2/6)")
            .sheet(isPresented: $showingInfoPopup) {
                BodyFatInfoView()
            }
            .fullScreenCover(isPresented: $showProfileSettings3) {
                ProfileSettings3()
            }
        }
    }
    
    private func saveAndContinue() {
        // Validate input
        guard let _ = Double(bodyFatPercentage) else { return }
        
        // Save to Firebase
        saveToFirebase()
        
        // Update completion status
        lastCompletedPage = 2
        
        // Navigate to next screen
        showProfileSettings3 = true
    }
    
    private func saveToFirebase() {
        guard let user = Auth.auth().currentUser else { return }
        
        let userData: [String: Any] = [
            "bodyFatPercentage": Double(bodyFatPercentage) ?? 0,
            "lastCompletedPage": 2
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData(userData, merge: true)
    }
}

// Helper View for Body Fat Information
struct BodyFatInfoView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Measure Body Fat")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Add measurement methods and information here
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(trailing: DismissButton())
        }
    }
}

struct DismissButton: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
}
