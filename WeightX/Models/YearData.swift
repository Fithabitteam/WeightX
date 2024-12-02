struct YearData {
    struct WeekData {
        let weekNumber: Int
        let monthName: String
        let average: Double
        let weights: [WeightEntry]
        let startDate: Date
        let endDate: Date
    }
    
    let year: Int
    let weeklyData: [WeekData]
    let weeklyDifferences: [(weekLabel: String, difference: Double)]
    let hasData: Bool
    
    init(year: Int, allWeights: [WeightEntry]) {
        print("Initializing YearData for \(year) with \(allWeights.count) weights")
        self.year = year
        
        // Early exit if no weights
        guard !allWeights.isEmpty else {
            self.weeklyData = []
            self.weeklyDifferences = []
            self.hasData = false
            print("No weights available for year \(year)")
            return
        }
        
        let calendar = Calendar.current
        
        // Get year boundaries
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        
        guard let startOfYear = calendar.date(from: components),
              let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) else {
            self.weeklyData = []
            self.weeklyDifferences = []
            self.hasData = false
            print("Failed to calculate year boundaries")
            return
        }
        
        // Find first Sunday of the year
        var currentDate = startOfYear
        while calendar.component(.weekday, from: currentDate) != 1 { // 1 is Sunday
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        // Helper function to get week range
        func weekRange(from date: Date) -> (start: Date, end: Date) {
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 6, to: start)!
            return (start, calendar.date(byAdding: .day, value: 1, to: end)!)
        }
        
        // Collect all weeks in the year
        var weeklyDataTemp: [WeekData] = []
        while currentDate <= endOfYear {
            let (weekStart, weekEnd) = weekRange(from: currentDate)
            
            let weekWeights = allWeights.filter { entry in
                entry.date >= weekStart && entry.date < weekEnd
            }.sorted { $0.date < $1.date }
            
            if !weekWeights.isEmpty {
                let monthName = calendar.shortMonthSymbols[calendar.component(.month, from: weekStart) - 1]
                let weekOfMonth = calendar.component(.weekOfMonth, from: weekStart)
                let average = Double(String(format: "%.2f", weekWeights.reduce(0.0) { $0 + $1.weight } / Double(weekWeights.count)))!
                
                weeklyDataTemp.append(WeekData(
                    weekNumber: weekOfMonth,
                    monthName: monthName,
                    average: average,
                    weights: weekWeights,
                    startDate: weekStart,
                    endDate: weekEnd
                ))
                
                print("Added week data: \(monthName)/\(weekOfMonth) with \(weekWeights.count) weights, avg: \(average)")
            }
            
            guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: currentDate) else { break }
            currentDate = nextWeek
        }
        
        self.weeklyData = weeklyDataTemp
        
        // Calculate differences only if we have enough weeks
        if weeklyDataTemp.count > 1 {
            var differences: [(String, Double)] = []
            for i in 1..<weeklyDataTemp.count {
                let currentWeek = weeklyDataTemp[i]
                let previousWeek = weeklyDataTemp[i-1]
                let difference = Double(String(format: "%.2f", currentWeek.average - previousWeek.average))!
                let weekLabel = "\(currentWeek.monthName)/\(currentWeek.weekNumber)"
                differences.append((weekLabel, difference))
                print("Added difference for \(weekLabel): \(difference)")
            }
            self.weeklyDifferences = differences
            self.hasData = true
        } else {
            self.weeklyDifferences = []
            self.hasData = false
            print("Not enough weeks to calculate differences")
        }
    }
} 