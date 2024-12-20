import SwiftUI
import Charts
import FirebaseFirestore
import Foundation

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
    
    init(month: Date, allWeights: [WeightEntry]) {
        let result = MonthData.processData(month: month, allWeights: allWeights)
        self.month = month
        self.dailyWeights = result.dailyWeights
        self.weeklyData = result.weeklyData
        self.weeklyDifferences = result.weeklyDiffs
    }
    
    private static func processData(month: Date, allWeights: [WeightEntry]) -> (
        dailyWeights: [WeightEntry],
        weeklyData: [WeekData],
        weeklyDiffs: [(weekNumber: Int, difference: Double)]
    ) {
        let calendar = Calendar.current
        let uniqueWeights = getUniqueDailyWeights(from: allWeights)
        
        // Get daily weights
        let filteredDailyWeights = uniqueWeights.filter { weight in
            calendar.isDate(weight.date, equalTo: month, toGranularity: .month)
        }.sorted { $0.date < $1.date }
        
        print("Found \(filteredDailyWeights.count) weights for current month")
        
        // Get weekly data
        let monthBoundaries = getMonthBoundaries(for: month, calendar: calendar)
        
        if let boundaries = monthBoundaries {
            let (firstDayOfMonth, lastDayOfMonth, nextMonthStart) = boundaries
            let results = processWeeklyData(
                uniqueWeights: uniqueWeights,
                firstDay: firstDayOfMonth,
                lastDay: lastDayOfMonth,
                nextMonthStart: nextMonthStart,
                calendar: calendar
            )
            return (filteredDailyWeights, results.weeklyData, results.differences)
        } else {
            return (filteredDailyWeights, [], [])
        }
    }
    
    // Move all helper functions to be static
    private static func getUniqueDailyWeights(from weights: [WeightEntry]) -> [WeightEntry] {
        let calendar = Calendar.current
        var dailyWeights: [Date: WeightEntry] = [:]
        
        let sortedWeights = weights.sorted { $0.date > $1.date }
        
        for weight in sortedWeights {
            let dayStart = calendar.startOfDay(for: weight.date)
            if dailyWeights[dayStart] == nil {
                dailyWeights[dayStart] = weight
            }
        }
        
        return dailyWeights.values.sorted { $0.date > $1.date }
    }
    
    private static func getMonthBoundaries(for month: Date, calendar: Calendar) -> (firstDay: Date, lastDay: Date, nextMonth: Date)? {
        let monthComponents = calendar.dateComponents([.year, .month], from: month)
        guard let firstDayOfMonth = calendar.date(from: monthComponents),
              let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth),
              let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth) else {
            return nil
        }
        return (firstDayOfMonth, lastDayOfMonth, nextMonthStart)
    }
    
    private static func processWeeklyData(
        uniqueWeights: [WeightEntry],
        firstDay: Date,
        lastDay: Date,
        nextMonthStart: Date,
        calendar: Calendar
    ) -> (weeklyData: [WeekData], differences: [(weekNumber: Int, difference: Double)]) {
        var processedWeeklyData: [WeekData] = []
        var weeklyDiffs: [(weekNumber: Int, difference: Double)] = []
        var weekNumber = 1
        
        // Get first Sunday of the month
        var currentDate = getFirstSunday(for: firstDay, calendar: calendar)
        
        // If first Sunday is before the month starts, move to next Sunday
        if currentDate < firstDay {
            currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate)!
        }
        
        // Process weeks that start in this month
        while currentDate < nextMonthStart {
            // Get start and end of week in the same timezone
            let weekStart = calendar.startOfDay(for: currentDate)
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            
            // Get weights for current week
            let weekWeights = uniqueWeights.filter { weight in
                let weightDate = calendar.startOfDay(for: weight.date)
                return weightDate >= weekStart && weightDate < weekEnd
            }.sorted { $0.date < $1.date }
            
            print("\nProcessing week starting \(weekStart):")
            weekWeights.forEach { weight in
                print("Including weight: \(weight.weight) on \(weight.date)")
            }
            
            if !weekWeights.isEmpty {
                let weekTotal = weekWeights.reduce(0.0) { $0 + $1.weight }
                // Round week average to 2 decimal places
                let weekAverage = (weekTotal / Double(weekWeights.count)).rounded(toPlaces: 2)
                
                let weekData = WeekData(
                    weekNumber: weekNumber,
                    average: weekAverage,
                    weights: weekWeights,
                    startDate: weekStart,
                    endDate: weekEnd
                )
                
                processedWeeklyData.append(weekData)
                
                // Get previous week's weights
                let prevWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
                let prevWeekEnd = weekStart
                
                let prevWeekWeights = uniqueWeights.filter { weight in
                    let weightDate = calendar.startOfDay(for: weight.date)
                    return weightDate >= prevWeekStart && weightDate < prevWeekEnd
                }
                
                print("Previous week weights:")
                prevWeekWeights.forEach { weight in
                    print("Including weight: \(weight.weight) on \(weight.date)")
                }
                
                if !prevWeekWeights.isEmpty {
                    let prevTotal = prevWeekWeights.reduce(0.0) { $0 + $1.weight }
                    // Round previous week average to 2 decimal places
                    let prevAverage = (prevTotal / Double(prevWeekWeights.count)).rounded(toPlaces: 2)
                    // Calculate difference between 2-decimal averages and round to 3 decimals for display
                    let difference = (weekAverage - prevAverage).rounded(toPlaces: 3)
                    weeklyDiffs.append((weekNumber, difference))
                }
                
                weekNumber += 1
            }
            
            currentDate = weekEnd
        }
        
        // Debug print for verification
        for (index, weekData) in processedWeeklyData.enumerated() {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d, yyyy"
            
            print("\nWeek \(index + 1):")
            print("Start (Sunday): \(formatter.string(from: weekData.startDate))")
            print("End (Saturday): \(formatter.string(from: weekData.endDate))")
            print("Average: \(String(format: "%.2f", weekData.average))")
            print("Weights count: \(weekData.weights.count)")
            if let diff = weeklyDiffs.first(where: { $0.weekNumber == index + 1 }) {
                print("Difference: \(String(format: "%.3f", diff.difference))")
            }
        }
        
        return (processedWeeklyData, weeklyDiffs)
    }
    
    private static func getFirstSunday(for date: Date, calendar: Calendar) -> Date {
        var currentDate = calendar.startOfDay(for: date)
        while calendar.component(.weekday, from: currentDate) != 1 { // 1 is Sunday
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        return currentDate
    }
}

// Add this extension for consistent rounding
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
} 
