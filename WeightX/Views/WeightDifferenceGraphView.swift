import SwiftUI
import Charts
import FirebaseFirestore
import FirebaseAuth
/*
struct WeightDifferenceGraphView: View {
    let monthData: MonthData
    @State private var selectedWeek: Int?
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Average Difference")
                .font(.headline)
                .padding(.bottom, 4)
            
            Chart {
                ForEach(monthData.weeklyDifferences, id: \.weekNumber) { week in
                    BarMark(
                        x: .value("Week", "Week \(week.weekNumber)"),
                        y: .value("Difference", week.difference)
                    )
                    .foregroundStyle(getBarColor(for: week.difference))
                    .annotation(position: week.difference > 0 ? .top : .bottom) {
                        if selectedWeek == week.weekNumber {
                            Text(formatDifference(week.difference))
                                .font(.caption)
                                .foregroundColor(getBarColor(for: week.difference))
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
            .chartYScale(domain: yAxisRange)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let currentX = value.location.x
                                    let barWidth = geometry.size.width / CGFloat(monthData.weeklyDifferences.count)
                                    let selectedIndex = Int(currentX / barWidth) + 1
                                    
                                    if selectedIndex >= 1 && selectedIndex <= monthData.weeklyDifferences.count {
                                        selectedWeek = selectedIndex
                                    }
                                }
                                .onEnded { _ in
                                    selectedWeek = nil
                                }
                        )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var yAxisRange: ClosedRange<Double> {
        let maxAbs = monthData.weeklyDifferences.map { abs($0.difference) }.max() ?? 0
        return -maxAbs...maxAbs
    }
    
    private func getBarColor(for difference: Double) -> Color {
        WeightGoalColor.getDifferenceColor(for: difference, goal: UserDefaults.standard.string(forKey: "selectedGoal"))
    }
    
    private func formatDifference(_ value: Double) -> String {
        let absValue = abs(value)
        let convertedValue = weightUnit.convert(absValue, from: .kg)
        let sign = value > 0 ? "+" : "-"
        return String(format: "%@%.2f %@", sign, convertedValue, weightUnit.rawValue)
    }
}
*/
