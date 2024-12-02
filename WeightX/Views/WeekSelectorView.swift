import SwiftUI

struct WeekSelectorView: View {
    @Binding var currentWeek: Week
    let onWeekChange: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                currentWeek = currentWeek.previous()
                onWeekChange()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(currentWeek.dateString)
                .font(.headline)
            
            Spacer()
            
            Button(action: {
                if currentWeek.startDate < Week.getCurrentWeek().startDate {
                    currentWeek = currentWeek.next()
                    onWeekChange()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(currentWeek.startDate < Week.getCurrentWeek().startDate ? .blue : .gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 