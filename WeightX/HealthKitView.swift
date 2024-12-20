import SwiftUI
import Firebase
import HealthKit
import FirebaseAuth

struct HealthKitView: View {
    @State private var progress: Double = 1.0 // 100% for the last screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 7
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
            .navigationTitle("Profile Setup (7/7)")
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $showHomeScreen) {
                ContentView()
            }
        }
    }
    
    private func requestHealthKitPermission() {
        Task {
            do {
                let success = try await HealthKitManager.shared.requestAuthorization()
                DispatchQueue.main.async {
                    if success {
                        lastCompletedPage = 7
                        showHomeScreen = true
                    }
                }
            } catch {
                print("HealthKit authorization failed: \(error)")
            }
        }
    }
    
    private func skipToHome() {
        lastCompletedPage = 7
        showHomeScreen = true
    }
} 