import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct GoalTimelineView: View {
    let selectedGoal: String
    let userMotivations: [String]
    @State private var selectedPace: String = ""
    @State private var targetDate: Date = Date()
    @State private var showNextScreen = false
    @State private var progress: Double = 0.858 // 6/7
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 6
    @State private var showDatePicker = false
    @State private var hasSetTargetDate = false
    
    var primaryMotivation: String {
        guard let first = userMotivations.first else { return "" }
        let words = first.split(separator: " ")
        let limitedWords = words.prefix(10)
        let result = limitedWords.joined(separator: " ")
        return result + (words.count > 10 ? "..." : "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Let's set your goal timeline")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        // Goal Summary Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your motivation:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(primaryMotivation)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .cornerRadius(12)
                        }
                        .padding(.vertical, 8)
                        
                        // Pace Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Choose your pace:")
                                .font(.headline)
                            
                            VStack(spacing: 16) {
                                TimeframeButton(
                                    title: "Advanced (1-2 months)",
                                    description: "750-1000gms change per week",
                                    isSelected: selectedPace == "Advanced"
                                ) {
                                    selectedPace = "Advanced"
                                }
                                
                                TimeframeButton(
                                    title: "Intermediate (2-4 months)",
                                    description: "500-750gms change per week",
                                    isSelected: selectedPace == "Intermediate"
                                ) {
                                    selectedPace = "Intermediate"
                                }
                                
                                TimeframeButton(
                                    title: "Beginner (4+ months)",
                                    description: "250-500gms change per week",
                                    isSelected: selectedPace == "Beginner"
                                ) {
                                    selectedPace = "Beginner"
                                }
                            }
                        }
                        
                        // Target Date Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Set a target date (optional):")
                                .font(.headline)
                            
                            Button(action: { showDatePicker = true }) {
                                HStack {
                                    Text(hasSetTargetDate ? formatDate(targetDate) : "Select target date")
                                        .foregroundColor(hasSetTargetDate ? .primary : .secondary)
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding()
                }
                
                // Continue Button
                Button(action: saveAndContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(!selectedPace.isEmpty ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .disabled(selectedPace.isEmpty)
            }
            .navigationTitle("Profile Setup (6/7)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showDatePicker) {
                NavigationView {
                    DatePicker("Select Date", selection: $targetDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .navigationBarItems(
                            leading: Button("Cancel") {
                                showDatePicker = false
                            },
                            trailing: Button("Done") {
                                hasSetTargetDate = true
                                showDatePicker = false
                            }
                        )
                }
            }
            .fullScreenCover(isPresented: $showNextScreen) {
                HealthKitView()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func saveAndContinue() {
        guard !selectedPace.isEmpty else { return }
        guard let user = Auth.auth().currentUser else { return }
        
        var userData: [String: Any] = [
            "goalTimeframe": selectedPace,
            "primaryMotivation": primaryMotivation,
            "lastCompletedPage": 6
        ]
        
        // Only save target date if user has set one
        if hasSetTargetDate {
            userData["targetDate"] = Timestamp(date: targetDate)
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData(userData, merge: true) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
                return
            }
            
            lastCompletedPage = 6
            showNextScreen = true
        }
    }
} 