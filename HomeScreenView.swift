//
//  HomeScreenView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 11/10/24.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeScreenView: View {
    @AppStorage("userName") private var username: String = ""
    @State private var currentWeek: Week = Week.getCurrentWeek()
    @State private var showingAddWeight = false
    @Binding var isUserLoggedIn: Bool
    @State private var weeklyWeights: [Date: WeightEntry] = [:]
    @State private var weeklyAverage: Double = 0.0
    @State private var previousWeekAverage: Double = 0.0
    @State private var hasPreviousWeekData: Bool = false
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    @StateObject private var goalViewModel = GoalViewModel()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 16) {
                        WeekSelectorView(
                            currentWeek: $currentWeek,
                            onWeekChange: fetchWeekData
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Stats Cards
                        HStack(spacing: 12) {
                            // Goal Box (moved to left)
                            if let goalWeight = goalViewModel.goalWeight {
                                VStack(spacing: 12) {
                                    Text("Goal")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(String(format: "%.1f %@", 
                                         UserSettings.shared.weightUnit.convert(goalWeight, from: .kg),
                                         UserSettings.shared.weightUnit.rawValue))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    if let goal = goalViewModel.userGoal {
                                        Text(goal)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let pace = goalViewModel.goalPace {
                                        Text(pace)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .frame(width: 100)
                                .frame(height: 125)
                                .padding(.vertical, 16)
                                .padding(.horizontal)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // Weekly Average Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Weekly Average")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: { goalViewModel.showingInfoPopup = true }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if weeklyAverage > 0 {
                                    Text(String(format: "%.2f %@",
                                         UserSettings.shared.weightUnit.convert(weeklyAverage, from: .kg),
                                         UserSettings.shared.weightUnit.rawValue))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    if hasPreviousWeekData {
                                        let difference = weeklyAverage - previousWeekAverage
                                        Text(String(format: "%+.3f %@",
                                             UserSettings.shared.weightUnit.convert(difference, from: .kg),
                                             UserSettings.shared.weightUnit.rawValue))
                                            .font(.headline)
                                            .foregroundColor(goalViewModel.getDifferenceColor(for: difference))
                                    }
                                } else {
                                    Text("-")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 125)
                            .padding(.vertical, 16)
                            .padding(.horizontal)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        WeeklyWeightGrid(
                            week: currentWeek,
                            weights: weeklyWeights
                        )
                        .padding()
                    }
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddWeight = true }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 55, height: 55)
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                // Info Popup Overlay
                if goalViewModel.showingInfoPopup {
                    GoalInfoPopup(
                        goal: goalViewModel.userGoal ?? "",
                        onDismiss: { goalViewModel.showingInfoPopup = false }
                    )
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
                }
            }
            .navigationTitle("Weight Log")
            .sheet(isPresented: $showingAddWeight) {
                AddWeightView()
            }
            .onAppear {
                fetchWeekData()
                goalViewModel.fetchUserData()
            }
            .animation(.easeInOut, value: goalViewModel.showingInfoPopup)
        }
    }
    
    private func fetchWeekData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let weekStart = calendar.startOfDay(for: currentWeek.startDate)
        let weekEnd = calendar.date(byAdding: .day, value: 1, to: currentWeek.endDate)!
        
        // Use snapshot listener for real-time updates
        db.collection("weights")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: weekStart))
            .whereField("date", isLessThan: Timestamp(date: weekEnd))
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching weights: \(error)")
                    return
                }
                
                weeklyWeights.removeAll()
                
                snapshot?.documents.forEach { doc in
                    if let entry = WeightEntry(from: doc) {
                        let entryDate = calendar.startOfDay(for: entry.date)
                        weeklyWeights[entryDate] = entry
                    }
                }
                
                // Calculate average if we have weights
                let weights = Array(weeklyWeights.values)
                if !weights.isEmpty {
                    weeklyAverage = weights.reduce(0) { $0 + $1.weight } / Double(weights.count)
                    fetchPreviousWeekAverage(userId: userId)
                } else {
                    weeklyAverage = 0
                    previousWeekAverage = 0
                    hasPreviousWeekData = false
                }
            }
    }
    
    private func fetchPreviousWeekAverage(userId: String) {
        let previousWeek = currentWeek.previous()
        
        let db = Firestore.firestore()
        db.collection("weights")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: previousWeek.startDate))
            .whereField("date", isLessThan: Timestamp(date: Calendar.current.date(byAdding: .day, value: 1, to: previousWeek.endDate)!))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching previous week: \(error)")
                    return
                }
                
                let weights = snapshot?.documents.compactMap { doc -> Double? in
                    guard let weight = doc.data()["weight"] as? Double else { return nil }
                    return weight
                } ?? []
                
                DispatchQueue.main.async {
                    hasPreviousWeekData = !weights.isEmpty
                    if !weights.isEmpty {
                        previousWeekAverage = weights.reduce(0, +) / Double(weights.count)
                    } else {
                        previousWeekAverage = 0
                        hasPreviousWeekData = false
                    }
                }
            }
    }
}

struct StatCard: View {
    let selectedDate: Date
    @State private var weeklyAverage: Double = 0.0
    @State private var weekDifference: Double = 0.0
    @State private var hasCurrentWeekData: Bool = false
    @State private var hasPreviousWeekData: Bool = false
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if title == "Weekly Average" {
                if hasCurrentWeekData {
                    Text(String(format: "%.1f kg", weeklyAverage))
                        .font(.title2)
                        .fontWeight(.bold)
                } else {
                    Text("-")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            } else {
                if hasCurrentWeekData && hasPreviousWeekData {
                    Text(weekDifferenceString)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(weekDifference >= 0 ? .red : .green)
                } else {
                    Text("-")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            calculateWeeklyStats()
        }
        .onChange(of: selectedDate) { newDate in
            print("\nStats card detected date change to: \(newDate)")
            // Reset states before recalculating
            weeklyAverage = 0.0
            weekDifference = 0.0
            hasCurrentWeekData = false
            hasPreviousWeekData = false
            calculateWeeklyStats()
        }
    }
    
    private func calculateWeeklyStats() {
        guard let user = Auth.auth().currentUser else { return }
        
        let weekStart = getWeekStartDate(for: selectedDate)
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
        
        print("\n=== Weekly Stats Calculation ===")
        print("Selected date for calculation: \(selectedDate)")
        print("Using week start: \(weekStart)")
        print("Using week end: \(weekEnd)")
        
        let db = Firestore.firestore()
        db.collection("weights")
            .whereField("userId", isEqualTo: user.uid)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: weekStart))
            .whereField("date", isLessThan: Timestamp(date: weekEnd))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting selected week data: \(error)")
                    return
                }
                
                let weights = snapshot?.documents.compactMap { doc -> Double? in
                    let data = doc.data()
                    guard let weight = data["weight"] as? Double,
                          let timestamp = data["date"] as? Timestamp else {
                        return nil
                    }
                    print("Found weight entry: \(weight) for date: \(timestamp.dateValue())")
                    return weight
                } ?? []
                
                DispatchQueue.main.async {
                    self.hasCurrentWeekData = !weights.isEmpty
                    if !weights.isEmpty {
                        self.weeklyAverage = weights.reduce(0, +) / Double(weights.count)
                        print("Calculated average for week starting \(weekStart): \(self.weeklyAverage)")
                    } else {
                        print("No weights found for week starting \(weekStart)")
                    }
                    
                    // Get previous week's weights
                    self.fetchPreviousWeekStats(db: db, user: user, previousWeekStart: previousWeekStart, weekStart: weekStart)
                }
            }
    }
    
    private func fetchPreviousWeekStats(db: Firestore, user: User, previousWeekStart: Date, weekStart: Date) {
        print("Fetching previous week stats from \(previousWeekStart) to \(weekStart)")
        
        db.collection("weights")
            .whereField("userId", isEqualTo: user.uid)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: previousWeekStart))
            .whereField("date", isLessThan: Timestamp(date: weekStart))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting previous week data: \(error)")
                    return
                }
                
                let previousWeights = snapshot?.documents.compactMap { doc -> Double? in
                    let data = doc.data()
                    guard let weight = data["weight"] as? Double else { return nil }
                    return weight
                } ?? []
                
                DispatchQueue.main.async {
                    self.hasPreviousWeekData = !previousWeights.isEmpty
                    if !previousWeights.isEmpty {
                        let previousAverage = previousWeights.reduce(0, +) / Double(previousWeights.count)
                        print("Previous week average: \(previousAverage)")
                        if self.hasCurrentWeekData {
                            self.weekDifference = self.weeklyAverage - previousAverage
                            print("Week difference: \(self.weekDifference)")
                        }
                    } else {
                        print("No weights found for previous week")
                    }
                }
            }
    }
    
    private var weekDifferenceString: String {
        let prefix = weekDifference >= 0 ? "+" : ""
        if abs(weekDifference) >= 1 {
            return "\(prefix)\(String(format: "%.1f kg", weekDifference))"
        } else {
            return "\(prefix)\(String(format: "%.0f g", weekDifference * 1000))"
        }
    }
    
    private func getWeekStartDate(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        calendar.firstWeekday = 1 // Sunday
        
        // Get the start of the day for the given date
        let startOfDay = calendar.startOfDay(for: date)
        
        // Get the weekday component (1 = Sunday, 2 = Monday, etc.)
        let weekday = calendar.component(.weekday, from: startOfDay)
        
        // Calculate how many days to subtract to get to Sunday
        let daysToSubtract = weekday - 1
        
        // Get the start of the week (Sunday)
        if let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfDay) {
            print("\nWeek Calculation Debug:")
            print("Input date: \(date)")
            print("Start of day: \(startOfDay)")
            print("Week start: \(weekStart)")
            return weekStart
        }
        
        return startOfDay
    }
}

struct AddWeightButton: View {
    @Binding var showingAddWeight: Bool
    
    var body: some View {
        Button(action: { showingAddWeight = true }) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
        }
    }
}

struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView(isUserLoggedIn: .constant(true))
    }
}

class GoalViewModel: ObservableObject {
    @Published var goalWeight: Double?
    @Published var userGoal: String?
    @Published var goalPace: String?
    @Published var showingInfoPopup = false
    
    func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                self?.goalWeight = data["targetWeight"] as? Double
                self?.userGoal = data["weightGoal"] as? String
                if let pace = data["goalTimeframe"] as? String {
                    self?.goalPace = self?.formatPace(pace)
                }
            }
        }
    }
    
    func getDifferenceColor(for difference: Double) -> Color {
        guard let goal = userGoal else { return .secondary }
        
        switch goal {
        case "Weight Gain":
            return difference > 0 ? .green : .red
        case "Weight Loss":
            return difference < 0 ? .green : .red
        case "Maintain Weight":
            return abs(difference) <= 0.2 ? .green : .red
        default:
            return difference > 0 ? .red : .green
        }
    }
    
    private func formatPace(_ pace: String) -> String {
        switch pace {
        case "Advanced":
            return "750-1000g/week"
        case "Intermediate":
            return "500-750g/week"
        case "Beginner":
            return "250-500g/week"
        default:
            return pace
        }
    }
}

struct GoalInfoPopup: View {
    let goal: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Weight Change Indication")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            Text(explanationText)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Button("Got it") {
                onDismiss()
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
        .frame(maxWidth: 250)
    }
    
    private var explanationText: String {
        switch goal {
        case "Weight Gain":
            return "Your goal is to gain weight, so weight increases (positive changes) are shown in green and decreases (negative changes) are shown in red."
        case "Weight Loss":
            return "Your goal is to lose weight, so weight decreases (negative changes) are shown in green and increases (positive changes) are shown in red."
        case "Maintain Weight":
            return "Your goal is to maintain weight, so weight increases are shown in red and decreases are shown in green to help you stay within your target range."
        default:
            return "Weight increases are shown in red and decreases are shown in green."
        }
    }
}

