//
//  SettingsView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 30/11/24.
//
import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import HealthKit

struct SettingsView: View {
    @Binding var isShowing: Bool
    @Binding var isUserLoggedIn: Bool
    @AppStorage("userName") private var username: String = ""
    @State private var selectedUnit: WeightUnit = UserSettings.shared.weightUnit
    @State private var showingSignOutAlert = false
    @State private var showingImport = false
    @State private var showingHealthKitAuth = false
    @State private var isSyncing = false
    @State private var showingSyncError = false
    @State private var syncErrorMessage = ""
    @State private var showHealthKitSuccess = false
    @State private var showHealthKitError = false
    @State private var healthKitErrorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink(destination: ProfileView()) {
                        HStack {
                            Image(systemName: "person.circle")
                            Text(username.isEmpty ? "Your Profile" : "\(username)'s Profile")
                        }
                    }
                }
                
                Section(header: Text("Weight Unit")) {
                    Picker("Unit", selection: $selectedUnit) {
                        Text("Kilograms (kg)").tag(WeightUnit.kg)
                        Text("Pounds (lbs)").tag(WeightUnit.lbs)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedUnit) { newValue in
                        UserSettings.shared.setWeightUnit(newValue)
                    }
                }
                
                Section {
                    NavigationLink(destination: FeedbackView()) {
                        HStack {
                            Image(systemName: "message")
                            Text("Feedback")
                        }
                    }
                }
                
                Section {
                    Button(action: { showingImport = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Data")
                        }
                    }
                }
                
                Section(header: Text("Health Integration")) {
                    if HealthKitManager.shared.isHealthKitAvailable {
                        Button(action: syncWithHealthKit) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text("Sync with Apple Health")
                                if isSyncing {
                                    Spacer()
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isSyncing)
                    }
                }
                
                Section {
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
                Section {
                    VStack(spacing: 4) {
                        Divider()
                            .background(Color.gray.opacity(0.5))
                            .padding(.vertical, 8)
                        
                        Text("Weight tracker | v1.0.0")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingImport) {
                ImportView()
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("HealthKit Authorization", isPresented: $showingHealthKitAuth) {
                Button("Cancel", role: .cancel) { }
                Button("Allow", role: .destructive) {
                    syncWithHealthKit()
                }
            } message: {
                Text("HealthKit is not authorized. Please allow access to sync weights.")
            }
            .alert("Sync Error", isPresented: $showingSyncError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncErrorMessage)
            }
            .alert("Success", isPresented: $showHealthKitSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Successfully synced weights with Apple Health")
            }
            .alert("Sync Error", isPresented: $showHealthKitError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Failed to sync with Apple Health. Please try again.")
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            isUserLoggedIn = false
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    private func syncWithHealthKit() {
        Task {
            do {
                let hasAuth = await HealthKitManager.shared.hasHealthKitAuthorization()
                if !hasAuth {
                    try await HealthKitManager.shared.requestAuthorization()
                }
                
                // Fetch all weights from Firestore
                let weights = try await fetchAllWeights()
                
                // Sync only different weights
                try await HealthKitManager.shared.syncWeights(from: weights)
                
                DispatchQueue.main.async {
                    showHealthKitSuccess = true
                }
            } catch {
                print("Failed to sync with HealthKit: \(error)")
                DispatchQueue.main.async {
                    healthKitErrorMessage = error.localizedDescription
                    showHealthKitError = true
                }
            }
        }
    }
    
    private func fetchAllWeights() async throws -> [WeightEntry] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let db = Firestore.firestore()
            db.collection("weights")
                .whereField("userId", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    let weights = snapshot?.documents.compactMap { WeightEntry(from: $0) } ?? []
                    continuation.resume(returning: weights)
                }
        }
    }
}
