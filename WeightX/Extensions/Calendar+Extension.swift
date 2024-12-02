import Foundation

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        guard let startOfWeek = self.date(from: components) else { return date }
        return startOfDay(for: startOfWeek)
    }
    
    func endOfDay(for date: Date) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return self.date(byAdding: components, to: startOfDay(for: date)) ?? date
    }
    
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