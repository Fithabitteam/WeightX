import SwiftUI
import Charts
import FirebaseFirestore
import FirebaseAuth

struct WeightDifferenceGraphView: View {
    let monthData: MonthData
    @State private var showingFullScreen = false
    @State private var selectedPoint: (weekLabel: String, difference: Double)?
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    @State private var userGoal: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Weekly Average Difference")
                    .font(.headline)
                Spacer()
                Button(action: { showingFullScreen = true }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
            }
            
            differenceChart
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .fullScreenCover(isPresented: $showingFullScreen) {
            FullScreenGraphView(title: "Weekly Average Difference") {
                differenceChart
            }
        }
        .onAppear {
            fetchUserGoal()
        }
    }
    
    private var differenceChart: some View {
        Group {
            if !monthData.weeklyDifferences.isEmpty {
                let maxDiff = monthData.weeklyDifferences.map { abs($0.difference) }.max() ?? 0
                let yScale = maxDiff * 1.2 // 20% padding
                
                Chart {
                    ForEach(monthData.weeklyDifferences, id: \.weekNumber) { diff in
                        BarMark(
                            x: .value("Week", getWeekLabel(diff.weekNumber)),
                            y: .value("Difference", diff.difference)
                        )
                        .foregroundStyle(getBarColor(for: diff.difference))
                        .annotation(position: .overlay) {
                            Text(formatDifference(diff.difference))
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 4)
                        }
                    }
                    
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(Color.gray.opacity(0.5))
                }
                .frame(height: 200)
                .chartYScale(domain: -yScale...yScale)
            } else {
                Text("Need at least two weeks of data to show differences")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
            }
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
    
    private func formatDifference(_ difference: Double) -> String {
        switch weightUnit {
        case .kg:
            // Convert to grams
            let grams = difference * 1000
            return String(format: "%.0fg", grams)
        case .lbs:
            // Keep in lbs with more precision
            return String(format: "%.2f lbs", weightUnit.convert(difference, from: .kg))
        }
    }
    
    private func getWeekLabel(_ weekNumber: Int) -> String {
        return "Week \(weekNumber)"
    }
    
    private var weeklyAverageChart: some View {
        Group {
            if !monthData.weeklyData.isEmpty {
                let minAvg = monthData.weeklyData.map { $0.average }.min() ?? 0
                let maxAvg = monthData.weeklyData.map { $0.average }.max() ?? 0
                let padding = (maxAvg - minAvg) * 0.1 // 10% padding
                let yMin = weightUnit.convert(minAvg - padding, from: .kg)
                let yMax = weightUnit.convert(maxAvg + padding, from: .kg)
                
                Chart {
                    ForEach(monthData.weeklyData, id: \.weekNumber) { week in
                        LineMark(
                            x: .value("Week", "Week \(week.weekNumber)"),
                            y: .value("Average", weightUnit.convert(week.average, from: .kg))
                        )
                        .foregroundStyle(Color.blue)  // Change line color to blue
                        
                        PointMark(
                            x: .value("Week", "Week \(week.weekNumber)"),
                            y: .value("Average", weightUnit.convert(week.average, from: .kg))
                        )
                        .foregroundStyle(Color.blue)  // Change point color to blue
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: yMin...yMax)
            } else {
                Text("No data available")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
            }
        }
    }
} 

