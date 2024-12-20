import SwiftUI
import Charts
import FirebaseFirestore
import FirebaseAuth

struct WeeklyAverageDifferenceView: View {
    @State private var weeklyDifferences: [Double] = []
    @State private var isLoading = false
    @State private var userGoal: String?
    @State private var selectedIndex: Int?
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading data...")
            } else if weeklyDifferences.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(weeklyDifferences.indices, id: \.self) { index in
                        let difference = weeklyDifferences[index]
                        BarMark(
                            x: .value("Week", index + 1),
                            y: .value("Difference", difference)
                        )
                        .foregroundStyle(getBarColor(for: difference))
                    }
                    
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(Color.blue.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks { value in
                        if let yValue = value.as(Double.self) {
                            AxisValueLabel {
                                Text(String(format: "%.1f", yValue))
                            }
                            AxisGridLine()
                                .foregroundStyle(Color.gray.opacity(0.2))
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let xPosition = value.location.x - geometry.frame(in: .local).origin.x
                                        guard let index = proxy.value(atX: xPosition, as: Int.self),
                                              index >= 0 && index < weeklyDifferences.count else {
                                            selectedIndex = nil
                                            return
                                        }
                                        selectedIndex = index
                                    }
                                    .onEnded { _ in
                                        selectedIndex = nil
                                    }
                            )
                            .overlay {
                                if let index = selectedIndex {
                                    let difference = weeklyDifferences[index]
                                    if let xPosition = proxy.position(forX: Double(index + 1)) {
                                        let yPosition = difference >= 0 ?
                                            geometry.frame(in: .local).minY + 20 :
                                            geometry.frame(in: .local).maxY - 20
                                        
                                        DifferenceTooltip(
                                            difference: difference,
                                            weekNumber: index + 1,
                                            weightUnit: weightUnit
                                        )
                                        .position(x: xPosition, y: yPosition)
                                    }
                                }
                            }
                    }
                }
            }
        }
        .onAppear {
            fetchUserGoal()
            fetchData()
        }
    }
    
    private func fetchData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        let calendar = Calendar.current
        
        // Get start of current week
        let currentWeek = calendar.startOfWeek(for: Date())
        
        // Get data for the last 12 weeks
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -11, to: currentWeek) else {
            isLoading = false
            return
        }
        
        db.collection("weights")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching weights: \(error)")
                    isLoading = false
                    return
                }
                
                let weights = snapshot?.documents.compactMap { WeightEntry(from: $0) } ?? []
                calculateWeeklyDifferences(from: weights)
                isLoading = false
            }
    }
    
    private func calculateWeeklyDifferences(from weights: [WeightEntry]) {
        let calendar = Calendar.current
        var weeklyData: [Date: [WeightEntry]] = [:]
        
        // Get unique daily weights first
        let uniqueWeights = weights.uniqueDailyWeights()
        
        // Sort weights by date first
        let sortedWeights = uniqueWeights.sorted(by: { $0.date > $1.date })
        
        // Get current week start
        let currentWeekStart = calendar.startOfWeek(for: Date())
        
        // Group weights by week, starting from the current week
        var currentDate = currentWeekStart
        for _ in 0..<12 {  // Last 12 weeks
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
            
            // Get weights for this week
            let weekWeights = sortedWeights.filter { weight in
                weight.date >= currentDate && weight.date < weekEnd
            }
            
            if !weekWeights.isEmpty {
                weeklyData[currentDate] = weekWeights
            }
            
            currentDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate)!
        }
        
        // Calculate weekly averages
        let sortedWeeks = weeklyData.keys.sorted(by: >)  // Sort weeks in descending order
        var weeklyAverages: [Double] = []
        
        for week in sortedWeeks {
            let weekWeights = weeklyData[week]!
            let weekTotal = weekWeights.reduce(0.0) { $0 + $1.weight }
            let weekAverage = (weekTotal / Double(weekWeights.count)).rounded(toPlaces: 3)
            weeklyAverages.append(weekAverage)
        }
        
        // Calculate differences between consecutive weeks
        weeklyDifferences = []
        for i in 0..<(weeklyAverages.count - 1) {
            // Current week minus previous week
            let difference = (weeklyAverages[i] - weeklyAverages[i + 1]).rounded(toPlaces: 3)
            weeklyDifferences.append(difference)
        }
        
        // Reverse the differences array to show oldest to newest
        weeklyDifferences = weeklyDifferences.reversed()
    }
    
    private func formatDifference(_ difference: Double) -> String {
        switch weightUnit {
        case .kg:
            // Show exact grams with 3 decimal precision (32g instead of 30g)
            let grams = (difference * 1000)
            return String(format: "%.0fg", grams)
        case .lbs:
            return String(format: "%.3f lbs", weightUnit.convert(difference, from: .kg))
        }
    }
    
    private func getBarColor(for difference: Double) -> Color {
        guard let goal = userGoal else { return .secondary }
        
        if goal == "Weight Gain" {
            return difference > 0 ? .green : .red
        } else {
            return difference > 0 ? .red : .green
        }
    }
    
    private func fetchUserGoal() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let goal = data["weightGoal"] as? String {
                DispatchQueue.main.async {
                    self.userGoal = goal
                }
            }
        }
    }
    
    struct DifferenceTooltip: View {
        let difference: Double
        let weekNumber: Int
        let weightUnit: WeightUnit
        
        var body: some View {
            VStack(spacing: 4) {
                if difference >= 0 {
                    tooltipContent
                    tooltipArrow
                } else {
                    tooltipArrow
                    tooltipContent
                }
            }
        }
        
        private var tooltipContent: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Week \(weekNumber)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(formatDifference(difference))
                    .font(.caption)
                    .foregroundColor(difference >= 0 ? .red : .green)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 4)
        }
        
        private var tooltipArrow: some View {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 8, y: difference >= 0 ? 8 : -8))
                path.addLine(to: CGPoint(x: -8, y: difference >= 0 ? 8 : -8))
                path.closeSubpath()
            }
            .fill(Color(.systemBackground))
            .frame(width: 16, height: 8)
        }
        
        private func formatDifference(_ value: Double) -> String {
            switch weightUnit {
            case .kg:
                return String(format: "%.0fg", value * 1000)
            case .lbs:
                return String(format: "%.3f lbs", weightUnit.convert(value, from: .kg))
            }
        }
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}