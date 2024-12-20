import SwiftUI

struct MonthSelectorView: View {
    @Binding var selectedDate: Date
    let calendar = Calendar.current
    
    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
                    .imageScale(.large)
            }
            
            Spacer()
            
            Menu {
                ForEach(-12...0, id: \.self) { monthOffset in
                    let date = calendar.date(byAdding: .month, value: monthOffset, to: Date())!
                    Button(action: {
                        selectedDate = date
                    }) {
                        Text(formatDate(date))
                            .foregroundColor(calendar.isDate(date, equalTo: selectedDate, toGranularity: .month) ? .blue : .primary)
                    }
                }
            } label: {
                Text(formatDate(selectedDate))
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(minWidth: 120)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
                    .imageScale(.large)
            }
            .disabled(isFutureMonth)
        }
        .padding(.horizontal)
    }
    
    private var isFutureMonth: Bool {
        let currentMonth = calendar.startOfDay(for: Date())
        let selectedMonth = calendar.startOfDay(for: selectedDate)
        return calendar.compare(selectedMonth, to: currentMonth, toGranularity: .month) == .orderedDescending
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate),
           !isFutureMonth {
            selectedDate = newDate
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}


