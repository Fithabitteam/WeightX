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
    @State private var showingSettings = false
    @Binding var isUserLoggedIn: Bool
    @State private var weeklyWeights: [Date: WeightEntry] = [:]
    @State private var weeklyAverage: Double = 0.0
    @State private var previousWeekAverage: Double = 0.0
    @State private var hasPreviousWeekData: Bool = false
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    @State private var showWeeklyAverage = false
    @State private var selectedMonth: Date = Date()
    @State private var monthData: MonthData?
    @State private var isLoadingData = false
    @State private var showingYearPerformance = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                WeekSelectorView(
                    currentWeek: $currentWeek,
                    onWeekChange: fetchWeekData
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Stats Cards
                HStack(spacing: 16) {
                    // Weekly Average Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weekly Average")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
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
                                    .font(.caption)
                                    .foregroundColor(difference >= 0 ? .red : .green)
                            }
                        } else {
                            Text("-")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
                   .padding(.horizontal)
                   
                   WeeklyWeightGrid(
                       week: currentWeek,
                       weights: weeklyWeights
                   )
                   .padding()
                   
                   // Month Graphs Section
                   VStack(spacing: 16) {
                       MonthSelectorView(selectedDate: $selectedMonth)
                           .padding(.horizontal)
                       
                       // Graph Type Toggle
                       Picker("Graph Type", selection: $showWeeklyAverage) {
                           Text("Daily").tag(false)
                           Text("Weekly Avg").tag(true)
                       }
                       .pickerStyle(SegmentedPickerStyle())
                       .padding(.horizontal)
                       
                       if isLoadingData {
                           ProgressView("Loading data...")
                               .padding()
                       } else if let monthData = monthData {
                           WeightTrendGraphView(
                               monthData: monthData,
                               showWeeklyAverage: showWeeklyAverage
                           )
                           .padding(.horizontal)
                           
                           WeightDifferenceGraphView(monthData: monthData)
                               .padding(.horizontal)
                       } else {
                           Text("No data available")
                               .padding()
                       }
                       Button(action: {
                                           showingYearPerformance = true
                                       }) {
                                           Text("Check Year Performance")
                                               .font(.headline)
                                               .foregroundColor(.white)
                                               .frame(maxWidth: .infinity)
                                               .padding()
                                               .background(Color.blue)
                                               .cornerRadius(12)
                                       }
                                       .padding(.horizontal)
                                       .padding(.bottom)
                                   }
                               }
           .navigationTitle("Weight Log")
           .toolbar {
               ToolbarItem(placement: .navigationBarLeading) {
                   Button(action: { showingSettings = true }) {
                       Image(systemName: "gear")
                           .font(.title2)
                   }
               }
           }
           .fullScreenCover(isPresented: $showingSettings) {
               SettingsView(isShowing: $showingSettings, isUserLoggedIn: $isUserLoggedIn)
           }
           .fullScreenCover(isPresented: $showingYearPerformance) {
                       YearPerformanceView()
                   }
           .onAppear {
               fetchWeekData()
               fetchMonthData()
           }
           .onChange(of: selectedMonth) { _ in
               fetchMonthData()
           }
       }
       
    private func fetchMonthData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user ID available")
            return
        }
        
        isLoadingData = true
        monthData = nil  // Clear existing data
        
        let calendar = Calendar.current
        let currentMonth = selectedMonth
        
        // Get previous month
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else {
            print("Failed to calculate previous month")
            isLoadingData = false
            return
        }
        
        let db = Firestore.firestore()
        
        // Fetch both current and previous month data
        let currentMonthStart = calendar.startOfMonth(for: currentMonth)
        let currentMonthEnd = calendar.endOfMonth(for: currentMonth)
        let previousMonthStart = calendar.startOfMonth(for: previousMonth)
        let previousMonthEnd = calendar.endOfMonth(for: previousMonth)
        
        print("Starting data fetch for month: \(currentMonthStart)")
        print("Current month range: \(currentMonthStart) to \(currentMonthEnd)")
        print("Previous month range: \(previousMonthStart) to \(previousMonthEnd)")
        
        // Use DispatchGroup to handle both fetches
        let group = DispatchGroup()
        var currentWeights: [WeightEntry] = []
        var previousWeights: [WeightEntry] = []
        var fetchError: Error?
        
        // Fetch current month data
        group.enter()
        db.collection("weights")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: currentMonthStart))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: currentMonthEnd))
            .getDocuments { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching current month data: \(error)")
                    fetchError = error
                    return
                }
                
                currentWeights = snapshot?.documents.compactMap { WeightEntry(from: $0) } ?? []
                print("Found \(currentWeights.count) weights for current month")
            }
        
        // Fetch previous month data
        group.enter()
        db.collection("weights")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: previousMonthStart))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: previousMonthEnd))
            .getDocuments { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching previous month data: \(error)")
                    fetchError = error
                    return
                }
                
                previousWeights = snapshot?.documents.compactMap { WeightEntry(from: $0) } ?? []
                print("Found \(previousWeights.count) weights for previous month")
            }
        
        // Handle completion
        group.notify(queue: .main) {
            if let error = fetchError {
                print("Error occurred during fetch: \(error)")
                self.isLoadingData = false
                return
            }
            
            print("Creating MonthData with \(currentWeights.count) current weights and \(previousWeights.count) previous weights")
            
            let newMonthData = MonthData(
                month: currentMonth,
                weights: currentWeights,
                previousMonthWeights: previousWeights
            )
            
            print("MonthData created with:")
            print("- \(newMonthData.dailyWeights.count) daily weights")
            print("- \(newMonthData.weeklyData.count) weekly data points")
            print("- \(newMonthData.weeklyDifferences.count) weekly differences")
            
            self.monthData = newMonthData
            self.isLoadingData = false
        }
    }
            
    private func updateMonthData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let calendar = Calendar.current
        let currentMonth = selectedMonth
        
        // Get previous month
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        
        let db = Firestore.firestore()
        
        // Fetch both current and previous month data
        let currentMonthStart = calendar.startOfMonth(for: currentMonth)
        let currentMonthEnd = calendar.endOfMonth(for: currentMonth)
        let previousMonthStart = calendar.startOfMonth(for: previousMonth)
        let previousMonthEnd = calendar.endOfMonth(for: previousMonth)
        
        // Fetch current month data
        let currentMonthQuery = db.collection("weights")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: currentMonthStart))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: currentMonthEnd))
        
        // Fetch previous month data
        let previousMonthQuery = db.collection("weights")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: previousMonthStart))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: previousMonthEnd))
        
        // Execute both queries
        Task {
            do {
                async let currentMonthDocs = currentMonthQuery.getDocuments()
                async let previousMonthDocs = previousMonthQuery.getDocuments()
                
                let (currentSnapshot, previousSnapshot) = try await (currentMonthDocs, previousMonthDocs)
                
                let currentWeights = currentSnapshot.documents.compactMap { WeightEntry(from: $0) }
                let previousWeights = previousSnapshot.documents.compactMap { WeightEntry(from: $0) }
                
                DispatchQueue.main.async {
                    self.monthData = MonthData(
                        month: currentMonth,
                        weights: currentWeights,
                        previousMonthWeights: previousWeights
                    )
                }
            } catch {
                print("Error fetching data: \(error)")
            }
        }
    }
    
    private func formatDifference(_ difference: Double) -> String {
        let convertedDifference = UserSettings.shared.weightUnit.convert(difference, from: .kg)
        let prefix = difference >= 0 ? "+" : ""
        if abs(convertedDifference) >= 1 {
            return "\(prefix)\(String(format: "%.1f %@", convertedDifference, UserSettings.shared.weightUnit.rawValue))"
        } else {
            return "\(prefix)\(String(format: "%.0f g", convertedDifference * 1000))"
        }
    }
    private func calculateAverages() {
        let currentWeekWeights = weeklyWeights.values.filter { entry in
            Calendar.current.isDate(entry.date, equalTo: currentWeek.startDate, toGranularity: .weekOfYear)
        }
        
        if !currentWeekWeights.isEmpty {
            let avgWeight = currentWeekWeights.reduce(0.0) { $0 + $1.weight } / Double(currentWeekWeights.count)
            weeklyAverage = Double(String(format: "%.2f", avgWeight))!
            
            // Calculate previous week's average
            let previousWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: currentWeek.startDate)!
            let previousWeekWeights = weeklyWeights.values.filter { entry in
                Calendar.current.isDate(entry.date, equalTo: previousWeekStart, toGranularity: .weekOfYear)
            }
            
            if !previousWeekWeights.isEmpty {
                let prevAvg = previousWeekWeights.reduce(0.0) { $0 + $1.weight } / Double(previousWeekWeights.count)
                previousWeekAverage = Double(String(format: "%.2f", prevAvg))!
                hasPreviousWeekData = true
            }
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

struct WeekSelectorView: View {
    @Binding var currentWeek: Week
    let onWeekChange: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                currentWeek = currentWeek.previous()
                onWeekChange()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(currentWeek.dateString)
                .font(.headline)
            
            Spacer()
            
            Button(action: {
                if currentWeek.startDate < Week.getCurrentWeek().startDate {
                    currentWeek = currentWeek.next()
                    onWeekChange()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(currentWeek.startDate < Week.getCurrentWeek().startDate ? .blue : .gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = self.dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    func endOfMonth(for date: Date) -> Date {
        guard let nextMonth = self.date(byAdding: DateComponents(month: 1), to: self.startOfMonth(for: date)) else {
            return date
        }
        return self.date(byAdding: DateComponents(second: -1), to: nextMonth) ?? date
    }
}
