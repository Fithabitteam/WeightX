struct MonthData {
    struct WeekData {
        let weekNumber: Int
        let average: Double
        let weights: [WeightEntry]
        let startDate: Date
        let endDate: Date
    }
    
    let month: Date
    let dailyWeights: [WeightEntry]
    let weeklyData: [WeekData]
    let weeklyDifferences: [(weekNumber: Int, difference: Double)]
    
    init(month: Date, weights: [WeightEntry], previousMonthWeights: [WeightEntry]) {
        print("\n=== MonthData Initialization Started ===")
        print("Initializing for month: \(month)")
        self.month = month
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // Helper function to get start of day
        func startOfDay(for date: Date) -> Date {
            return calendar.startOfDay(for: date)
        }
        
        // Helper function to get end of day
        func endOfDay(for date: Date) -> Date {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay(for: date))!
            return calendar.date(byAdding: .second, value: -1, to: nextDay)!
        }
        
        // Helper function to get week range (Sunday to Saturday)
        func weekRange(startingFrom sunday: Date) -> (start: Date, end: Date) {
            let start = startOfDay(for: sunday)
            let saturday = calendar.date(byAdding: .day, value: 6, to: start)!
            return (start, endOfDay(for: saturday))
        }
        
        // Helper function to get previous week range
        func previousWeekRange(forWeek weekStart: Date) -> (start: Date, end: Date) {
            let prevSunday = calendar.date(byAdding: .day, value: -7, to: weekStart)!
            return weekRange(startingFrom: prevSunday)
        }
        
        // Get month boundaries
        let monthComponents = calendar.dateComponents([.year, .month], from: month)
        guard let firstDayOfMonth = calendar.date(from: monthComponents),
              let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth),
              let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth) else {
            print("Failed to calculate month boundaries")
            self.dailyWeights = []
            self.weeklyData = []
            self.weeklyDifferences = []
            return
        }
        
        // Filter weights for daily view only
        self.dailyWeights = weights.filter { weight in
            calendar.isDate(weight.date, equalTo: month, toGranularity: .month)
        }.sorted { $0.date < $1.date }
        print("Found \(dailyWeights.count) weights for current month")
        
        // Get next month's weights
        let nextMonthWeights = weights.filter { weight in
            calendar.isDate(weight.date, equalTo: nextMonthStart, toGranularity: .month)
        }
        
        // Get previous month for logging
        let prevMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth)!
        
        // Combine all weights for calculations
        let allWeights = previousMonthWeights + weights + nextMonthWeights
        
        // Log available weights
        print("\nAvailable weights by month:")
        print("Previous month: \(previousMonthWeights.count) weights")
        print("Current month: \(weights.count) weights")
        print("Next month: \(nextMonthWeights.count) weights")
        print("Total weights: \(allWeights.count)")
        
        // Find first Sunday
        var currentDate = startOfDay(for: firstDayOfMonth)
        while calendar.component(.weekday, from: currentDate) != 1 { // 1 is Sunday
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        // Collect all Sundays in the month
        var weekStarts: [Date] = []
        while currentDate <= lastDayOfMonth {
            let (weekStart, weekEnd) = weekRange(startingFrom: currentDate)
            
            // Only include weeks that don't end in the next month
            if !calendar.isDate(weekEnd, equalTo: nextMonthStart, toGranularity: .month) {
                weekStarts.append(currentDate)
                print("Added week: \(weekStart) to \(weekEnd)")
            } else {
                print("Skipped week ending in next month: \(weekStart) to \(weekEnd)")
            }
            
            currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate)!
        }
        
        // Calculate weekly data
        print("\n=== Calculating Weekly Averages ===")
        self.weeklyData = weekStarts.enumerated().compactMap { index, sunday in
            let (weekStart, weekEnd) = weekRange(startingFrom: sunday)
            print("\nProcessing Week \(index + 1): \(weekStart) (Sunday) to \(weekEnd) (Saturday)")
            
            // Get all weights for this week from any month
            let weekWeights = allWeights.filter { entry in
                entry.date >= weekStart && entry.date <= weekEnd
            }.sorted { $0.date < $1.date }
            
            guard !weekWeights.isEmpty else {
                print("No weights found for week \(index + 1)")
                return nil
            }
            
            // Calculate average
            let totalWeight = weekWeights.reduce(0.0) { $0 + $1.weight }
            let average = Double(String(format: "%.2f", totalWeight / Double(weekWeights.count)))!
            
            // Log weights
            print("Week \(index + 1) weights:")
            for weight in weekWeights {
                let monthType = if calendar.isDate(weight.date, equalTo: month, toGranularity: .month) {
                    "current"
                } else if calendar.isDate(weight.date, equalTo: prevMonth, toGranularity: .month) {
                    "prev"
                } else {
                    "next"
                }
                print("- Weight: \(weight.weight) on \(weight.date) (\(monthType))")
            }
            print("Week \(index + 1) average: \(average) from \(weekWeights.count) weights")
            
            return WeekData(
                weekNumber: index + 1,
                average: average,
                weights: weekWeights,
                startDate: weekStart,
                endDate: weekEnd
            )
        }
        
        // Calculate weekly differences
        print("\n=== Calculating Weekly Differences ===")
        var differences: [(Int, Double)] = []
        
        for weekData in weeklyData {
            let (prevStart, prevEnd) = previousWeekRange(forWeek: weekData.startDate)
            
            print("\nCalculating difference for Week \(weekData.weekNumber)")
            print("Current week: Sunday \(weekData.startDate) to Saturday \(weekData.endDate)")
            print("Current week average: \(weekData.average) from \(weekData.weights.count) weights")
            
            // Log current week weights
            for weight in weekData.weights {
                let monthType = if calendar.isDate(weight.date, equalTo: month, toGranularity: .month) {
                    "current"
                } else if calendar.isDate(weight.date, equalTo: prevMonth, toGranularity: .month) {
                    "prev"
                } else {
                    "next"
                }
                print("- Current weight: \(weight.weight) on \(weight.date) (\(monthType))")
            }
            
            print("Previous week: Sunday \(prevStart) to Saturday \(prevEnd)")
            
            let previousWeekWeights = allWeights.filter { entry in
                entry.date >= prevStart && entry.date <= prevEnd
            }.sorted { $0.date < $1.date }
            
            if !previousWeekWeights.isEmpty {
                let totalPrevWeight = previousWeekWeights.reduce(0.0) { $0 + $1.weight }
                let previousAverage = Double(String(format: "%.2f", totalPrevWeight / Double(previousWeekWeights.count)))!
                let difference = Double(String(format: "%.2f", weekData.average - previousAverage))!
                
                print("Previous week average: \(previousAverage) from \(previousWeekWeights.count) weights")
                
                // Log previous week weights
                for weight in previousWeekWeights {
                    let monthType = if calendar.isDate(weight.date, equalTo: month, toGranularity: .month) {
                        "current"
                    } else if calendar.isDate(weight.date, equalTo: prevMonth, toGranularity: .month) {
                        "prev"
                    } else {
                        "next"
                    }
                    print("- Previous weight: \(weight.weight) on \(weight.date) (\(monthType))")
                }
                
                print("Difference: \(difference)")
                differences.append((weekData.weekNumber, difference))
            } else {
                print("No weights found for previous week")
            }
        }
        
        self.weeklyDifferences = differences
        print("\n=== MonthData Initialization Complete ===")
        print("Weekly differences: \(weeklyDifferences)")
    }
} 