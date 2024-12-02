import SwiftUI

struct MonthSelectorView: View {
    @Binding var selectedDate: Date
    @State private var showingMonthPicker = false
    
    var body: some View {
        Button(action: { showingMonthPicker = true }) {
            HStack {
                Text(monthYearString(from: selectedDate))
                    .font(.headline)
                Image(systemName: "chevron.down")
            }
            .foregroundColor(.primary)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showingMonthPicker) {
            MonthPickerView(selectedDate: $selectedDate)
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}


