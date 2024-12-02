import Foundation

struct Week {
    let startDate: Date
    let endDate: Date
    
    static func getCurrentWeek() -> Week {
        let calendar = Calendar.current
        let today = Date()
        
        // Get start of today
        let startOfToday = calendar.startOfDay(for: today)
        
        // Calculate back to Sunday
        let weekday = calendar.component(.weekday, from: startOfToday)
        let daysToSubtract = weekday - 1
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfToday),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return Week(startDate: today, endDate: today)
        }
        
        return Week(startDate: weekStart, endDate: weekEnd)
    }
    
    func previous() -> Week {
        let calendar = Calendar.current
        guard let newStart = calendar.date(byAdding: .day, value: -7, to: startDate),
              let newEnd = calendar.date(byAdding: .day, value: -7, to: endDate) else {
            return self
        }
        return Week(startDate: newStart, endDate: newEnd)
    }
    
    func next() -> Week {
        let calendar = Calendar.current
        guard let newStart = calendar.date(byAdding: .day, value: 7, to: startDate),
              let newEnd = calendar.date(byAdding: .day, value: 7, to: endDate) else {
            return self
        }
        return Week(startDate: newStart, endDate: newEnd)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var days: [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return dates
    }
} 