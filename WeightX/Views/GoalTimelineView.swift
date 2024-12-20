import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct GoalTimelineView: View {
    let selectedGoal: String
    let userMotivations: [String]
    let currentWeight: Double
    let targetWeight: Double
    @State private var selectedPace: String = ""
    @State private var targetDate: Date = Date()
    @State private var showNextScreen = false
    @State private var progress: Double = 0.858
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
    
    private var weeksToGoal: Int {
        let weightDifference = abs(targetWeight - currentWeight)
        let weeklyRate: Double
        
        switch selectedPace {
        case "Beginner":
            weeklyRate = 0.25 // 250g per week
        case "Intermediate":
            weeklyRate = 0.5 // 500g per week
        case "Advanced":
            weeklyRate = 0.75 // 750g per week
        default:
            weeklyRate = 0.25
        }
        
        return Int(ceil(weightDifference / weeklyRate))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none  // Remove time from display
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Progress bar (6/7)
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Let's set your goal timeline")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Pace Selection
                    VStack(spacing: 16) {
                        PaceButton(
                            title: "Beginner",
                            subtitle: "250g-500g/week",
                            isSelected: selectedPace == "Beginner"
                        ) {
                            selectedPace = "Beginner"
                            updateTargetDate()
                        }
                        
                        PaceButton(
                            title: "Intermediate",
                            subtitle: "500g-750g/week",
                            isSelected: selectedPace == "Intermediate"
                        ) {
                            selectedPace = "Intermediate"
                            updateTargetDate()
                        }
                        
                        PaceButton(
                            title: "Advanced",
                            subtitle: "750g-1000g/week",
                            isSelected: selectedPace == "Advanced"
                        ) {
                            selectedPace = "Advanced"
                            updateTargetDate()
                        }
                    }
                    
                    if !selectedPace.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Date")
                                .font(.headline)
                            
                            Text("With this pace you will reach your goal weight of \(String(format: "%.1f", targetWeight))kg in \(weeksToGoal) weeks")
                                .foregroundColor(.secondary)
                            
                            DatePicker("Target Date", 
                                selection: $targetDate,
                                in: Date()...,
                                displayedComponents: [.date]  // Only show date, no time
                            )
                            .datePickerStyle(.compact)
                        }
                        .padding(.top)
                    }
                }
                .padding()
            }
            
            // Continue Button
            Button(action: saveGoal) {
                Text("Save Goal")
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
                DatePicker("Target Date",
                    selection: $targetDate,
                    in: Date()...,
                    displayedComponents: [.date]  // Only show date, no time
                )
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
    
    private func updateTargetDate() {
        let calendar = Calendar.current
        targetDate = calendar.date(byAdding: .weekOfYear, value: weeksToGoal, to: Date()) ?? Date()
    }
    
    private func saveGoal() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "goalTimeframe": selectedPace,
            "targetDate": Timestamp(date: targetDate),
            "lastCompletedPage": 6
        ]) { error in
            if let error = error {
                print("Error saving goal timeline: \(error)")
                return
            }
            
            lastCompletedPage = 6
            showNextScreen = true
        }
    }
}

struct PaceButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
    }
}

struct TimeframeButton: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Preview
struct GoalTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GoalTimelineView(
                selectedGoal: "Weight Loss",
                userMotivations: ["Losing weight for health"],
                currentWeight: 80.0,
                targetWeight: 70.0
            )
        }
    }
} 
