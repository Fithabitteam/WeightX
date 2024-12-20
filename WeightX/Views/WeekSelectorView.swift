import SwiftUI

struct WeekSelectorView: View {
    @Binding var currentWeek: Week
    var onWeekChange: () -> Void
    
    var body: some View {
        HStack {
            Button(action: previousWeek) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
                    .imageScale(.large)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(weekRangeText)
                    .font(.headline)
                
                if !isCurrentWeek {
                    Button("Go to Current Week") {
                        let currentWeekDates = Week.getCurrentWeek()
                        currentWeek = currentWeekDates
                        onWeekChange()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Button(action: nextWeek) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
                    .imageScale(.large)
            }
        }
    }
    
    private var isCurrentWeek: Bool {
        Calendar.current.isDate(currentWeek.startDate, equalTo: Week.getCurrentWeek().startDate, toGranularity: .weekOfYear)
    }
    
    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startText = formatter.string(from: currentWeek.startDate)
        let endText = formatter.string(from: currentWeek.endDate)
        return "\(startText) - \(endText)"
    }
    
    private func previousWeek() {
        if let newStartDate = Calendar.current.date(byAdding: .day, value: -7, to: currentWeek.startDate),
           let newEndDate = Calendar.current.date(byAdding: .day, value: 6, to: newStartDate) {
            currentWeek = Week(startDate: newStartDate, endDate: newEndDate)
            onWeekChange()
        }
    }
    
    private func nextWeek() {
        if let newStartDate = Calendar.current.date(byAdding: .day, value: 7, to: currentWeek.startDate),
           let newEndDate = Calendar.current.date(byAdding: .day, value: 6, to: newStartDate) {
            currentWeek = Week(startDate: newStartDate, endDate: newEndDate)
            onWeekChange()
        }
    }
}
