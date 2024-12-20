import Foundation

extension Array where Element == WeightEntry {
    func uniqueDailyWeights() -> [WeightEntry] {
        let calendar = Calendar.current
        
        // Group weights by date (day)
        var dailyWeights: [Date: WeightEntry] = [:]
        
        // Sort weights by date (newest first) so latest entry for each day is kept
        let sortedWeights = self.sorted { $0.date > $1.date }
        
        for weight in sortedWeights {
            let dayStart = calendar.startOfDay(for: weight.date)
            // Only add if no entry exists for this day (since weights are sorted, first entry is latest)
            if dailyWeights[dayStart] == nil {
                dailyWeights[dayStart] = weight
            }
        }
        
        // Return sorted array of unique daily weights
        return dailyWeights.values.sorted { $0.date > $1.date }
    }
} 