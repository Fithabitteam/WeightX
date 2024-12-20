import SwiftUI
import Charts

// Simple struct for graph data points
private struct GraphPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

struct WeightTrendGraphView: View {
    let monthData: MonthData
    let showWeeklyAverage: Bool
    @State private var showingFullScreen = false
    @State private var selectedPoint: (date: Date, value: Double)?
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(showWeeklyAverage ? "Weekly Average Trend" : "Daily Weight Trend")
                    .font(.headline)
                Spacer()
                Button(action: { showingFullScreen = true }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
            }
            
            if monthData.dailyWeights.isEmpty {
                Text("No weight data available for this month")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                if showWeeklyAverage {
                    weeklyAverageChart
                } else {
                    dailyWeightChart
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .fullScreenCover(isPresented: $showingFullScreen) {
            FullScreenGraphView(
                title: showWeeklyAverage ? "Weekly Average Trend" : "Daily Weight Trend"
            ) {
                if showWeeklyAverage {
                    weeklyAverageChart
                } else {
                    dailyWeightChart
                }
            }
        }
    }
    
    private var dailyWeightChart: some View {
        Group {
            if !monthData.dailyWeights.isEmpty {
                let minWeight = monthData.dailyWeights.map { $0.weight }.min() ?? 0
                let maxWeight = monthData.dailyWeights.map { $0.weight }.max() ?? 0
                let padding = (maxWeight - minWeight) * 0.1 // 10% padding
                let yMin = weightUnit.convert(minWeight - padding, from: .kg)
                let yMax = weightUnit.convert(maxWeight + padding, from: .kg)
                
                Chart {
                    ForEach(monthData.dailyWeights, id: \.id) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", weightUnit.convert(entry.weight, from: .kg))
                        )
                        .foregroundStyle(Color.blue)
                        
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", weightUnit.convert(entry.weight, from: .kg))
                        )
                        .foregroundStyle(Color.blue)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: yMin...yMax)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                Text("\(Calendar.current.component(.day, from: date))")
                            }
                        }
                    }
                }
            } else {
                Text("No data available")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
            }
        }
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
                        .foregroundStyle(Color.blue)
                        
                        PointMark(
                            x: .value("Week", "Week \(week.weekNumber)"),
                            y: .value("Average", weightUnit.convert(week.average, from: .kg))
                        )
                        .foregroundStyle(Color.blue)
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
