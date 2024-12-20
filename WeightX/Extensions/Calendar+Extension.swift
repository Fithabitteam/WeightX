import Foundation

extension Calendar {
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