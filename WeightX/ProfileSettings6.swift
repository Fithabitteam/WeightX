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
    @State private var showHomeScreen = false
    private var healthStore = HKHealthStore()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                Form {
                    Section {
                        Text("Connect WeightX to Apple Health")
                            .font(.headline)
                            .padding(.vertical)
                        
                        Text("Sync your fitness data seamlessly with Apple Health")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom)
                        
                        Button(action: requestHealthKitPermission) {
                            Text("Connect to Health")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        
                        Button(action: skipToHome) {
                            Text("Skip")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Profile Setup (6/6)")
            .fullScreenCover(isPresented: $showHomeScreen) {
                ContentView()
            }
        }
    }
    
    private func requestHealthKitPermission() {
        // Request HealthKit authorization
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    lastCompletedPage = 6
                    showHomeScreen = true
                }
            }
        }
    }
    
    private func skipToHome() {
        lastCompletedPage = 6
        showHomeScreen = true
    }
}

