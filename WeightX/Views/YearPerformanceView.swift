import SwiftUI
import Charts
import FirebaseFirestore
import FirebaseAuth

struct YearPerformanceView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedYear: Int
    @State private var yearData: YearData?
    @State private var isLoading = false
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    @State private var userGoal: String?
    
    init() {
        let calendar = Calendar.current
        _selectedYear = State(initialValue: calendar.component(.year, from: Date()))
    }
    
    private func calculateYearSummary() -> (cutWeeks: Int, gainWeeks: Int) {
        guard let yearData = yearData else { return (0, 0) }
        
        var cutWeeks = 0
        var gainWeeks = 0
        
        for i in 1..<yearData.weeklyData.count {
            let currentAverage = yearData.weeklyData[i].average
            let previousAverage = yearData.weeklyData[i-1].average
            if currentAverage > previousAverage {
                gainWeeks += 1
            } else if currentAverage < previousAverage {
                cutWeeks += 1
            }
        }
        
        return (cutWeeks, gainWeeks)
    }
    
    private func summaryView(_ summary: (cutWeeks: Int, gainWeeks: Int)) -> some View {
        VStack(spacing: 8) {
            Text("This year you have been on")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Cut for")
                        .foregroundColor(getSummaryColor(isGain: false))
                    Text("\(summary.cutWeeks)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getSummaryColor(isGain: false))
                    Text("weeks")
                        .foregroundColor(getSummaryColor(isGain: false))
                }
                
                VStack {
                    Text("Gain for")
                        .foregroundColor(getSummaryColor(isGain: true))
                    Text("\(summary.gainWeeks)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getSummaryColor(isGain: true))
                    Text("weeks")
                        .foregroundColor(getSummaryColor(isGain: true))
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private func getSummaryColor(isGain: Bool) -> Color {
        guard let goal = userGoal else { return .secondary }
        
        if goal == "Weight Gain" {
            return isGain ? .green : .red  // Green for gain weeks, red for cut weeks
        } else {
            return isGain ? .red : .green  // Red for gain weeks, green for cut weeks
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                yearPicker
                
                if isLoading {
                    loadingView
                } else if let yearData = yearData, yearData.hasData {
                    mainContentView(yearData)
                } else {
                    noDataView
                }
            }
            .navigationTitle("Year Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: selectedYear) { _ in fetchYearData() }
        .onAppear {
            fetchYearData()
            fetchUserGoal()
        }
    }
    
    // MARK: - Subviews
    
    private var yearPicker: some View {
        Picker("Year", selection: $selectedYear) {
            ForEach((2020...Calendar.current.component(.year, from: Date())), id: \.self) { year in
                Text(String(year)).tag(year)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    private var loadingView: some View {
        ProgressView("Loading data...")
            .frame(maxHeight: .infinity)
    }
    
    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No data available for \(selectedYear)")
                .font(.headline)
            Text("Try selecting a different year")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func mainContentView(_ yearData: YearData) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryView(calculateYearSummary())
                chartView(yearData)
            }
        }
    }
    
    // MARK: - Chart Components
    
    private struct ChartTooltip: View {
        let weekLabel: String
        let difference: Double
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
                Text(weekLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f %@", difference, weightUnit == .kg ? "kg" : "lbs"))
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
    }
    
    private struct ChartOverlayView: View {
        let proxy: ChartProxy
        let geometry: GeometryProxy
        let yearData: YearData
        let weightUnit: WeightUnit
        @State private var selectedIndex: Int?
        
        var body: some View {
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleTouch(at: value.location)
                        }
                        .onEnded { _ in
                            selectedIndex = nil
                        }
                )
                .overlay {
                    if let index = selectedIndex {
                        tooltipView(for: index)
                    }
                }
        }
        
        private func handleTouch(at point: CGPoint) {
            let xPosition = point.x - geometry.frame(in: .local).origin.x
            guard let index = proxy.value(atX: xPosition, as: Int.self),
                  index >= 0 && index < yearData.weeklyData.count else {
                selectedIndex = nil
                return
            }
            selectedIndex = index
        }
        
        private func tooltipView(for index: Int) -> some View {
            let difference = index > 0 ? yearData.weeklyData[index].average - yearData.weeklyData[index - 1].average : 0
            let convertedDifference = weightUnit.convert(difference, from: .kg)
            let weekLabel = formatWeekLabel(for: index, in: yearData)
            
            return GeometryReader { geo in
                if let xPos = proxy.position(forX: Double(index)) {
                    let yPos = difference >= 0 ? 
                        geo.frame(in: .local).minY + 20 : // For positive values, show above
                        geo.frame(in: .local).maxY - 20   // For negative values, show below
                    
                    ChartTooltip(
                        weekLabel: weekLabel,
                        difference: convertedDifference,
                        weightUnit: weightUnit
                    )
                    .position(x: xPos, y: yPos)
                }
            }
        }
        
        private func formatWeekLabel(for index: Int, in yearData: YearData) -> String {
            let weekData = yearData.weeklyData[index]
            let weekNumber = index + 1
            return "\(weekData.monthName)/Week\(weekNumber)"
        }
    }
    
    private func chartView(_ yearData: YearData) -> some View {
        Chart {
            weightBars(yearData)
            monthLines(yearData)
            
            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(Color.gray.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1))
        }
        .frame(height: 300)
        .padding()
        .chartXScale(domain: 0...yearData.weeklyData.count - 1)
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine()
                    .foregroundStyle(.clear)
                AxisTick()
                    .foregroundStyle(.clear)
                AxisValueLabel { 
                    Text("")
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                if let yValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text(String(format: "%.1f", yValue))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.2))
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                ChartOverlayView(
                    proxy: proxy,
                    geometry: geometry,
                    yearData: yearData,
                    weightUnit: weightUnit
                )
            }
        }
    }
    
    private func weightBars(_ yearData: YearData) -> some ChartContent {
        ForEach(yearData.weeklyData.indices.dropFirst(), id: \.self) { index in
            let currentWeek = yearData.weeklyData[index]
            let previousWeek = yearData.weeklyData[index - 1]
            let difference = currentWeek.average - previousWeek.average
            
            BarMark(
                x: .value("Week", index),
                y: .value("Difference", weightUnit.convert(difference, from: .kg))
            )
            .foregroundStyle(getBarColor(for: difference))
        }
    }
    
    private func monthLines(_ yearData: YearData) -> some ChartContent {
        ForEach(yearData.weeklyData.indices, id: \.self) { index in
            if index > 0 && yearData.weeklyData[index].monthName != yearData.weeklyData[index - 1].monthName {
                RuleMark(x: .value("Month", index))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(Color.gray.opacity(0.5))
            }
        }
    }
    
    private func fetchYearData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        yearData = nil  // Clear existing data
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = selectedYear
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let startOfYear = calendar.date(from: components),
              let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("weights")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfYear))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endOfYear))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching year data: \(error)")
                    DispatchQueue.main.async {
                        isLoading = false
                    }
                    return
                }
                
                let weights = snapshot?.documents.compactMap { WeightEntry(from: $0) } ?? []
                
                DispatchQueue.main.async {
                    self.yearData = YearData(year: selectedYear, allWeights: weights)
                    self.isLoading = false
                }
            }
    }
    
    private func fetchUserGoal() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        print("Fetching user goal for ID:", userId)
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user goal:", error)
                return
            }
            
            if let data = snapshot?.data() {
                print("Fetched user data:", data)
                if let goal = data["weightGoal"] as? String {
                    print("Found goal:", goal)
                    DispatchQueue.main.async {
                        self.userGoal = goal
                    }
                }
            }
        }
    }
    
    private func getBarColor(for difference: Double) -> Color {
        guard let goal = userGoal else {
            print("No goal set, returning secondary color")
            return .secondary 
        }
        
        print("Calculating color for difference: \(difference) with goal: \(goal)")
        
        if goal == "Weight Gain" {
            let color = difference > 0 ? Color.green : Color.red
            print("Goal is Weight Gain, difference is \(difference), returning \(difference > 0 ? "green" : "red")")
            return color
        } else {
            let color = difference > 0 ? Color.red : Color.green
            print("Goal is not Weight Gain, difference is \(difference), returning \(difference > 0 ? "red" : "green")")
            return color
        }
    }
}
