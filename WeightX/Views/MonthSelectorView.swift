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

struct MonthPickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        let calendar = Calendar.current
        _selectedYear = State(initialValue: calendar.component(.year, from: selectedDate.wrappedValue))
        _selectedMonth = State(initialValue: calendar.component(.month, from: selectedDate.wrappedValue))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Year Picker
                Picker("Year", selection: $selectedYear) {
                    ForEach((2020...Calendar.current.component(.year, from: Date())), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
                
                // Month Picker
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(monthName(month)).tag(month)
                    }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("Select Month")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    updateSelectedDate()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func monthName(_ month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        guard let date = Calendar.current.date(from: DateComponents(year: 2000, month: month)) else {
            return ""
        }
        return dateFormatter.string(from: date)
    }
    
    private func updateSelectedDate() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        if let date = Calendar.current.date(from: components) {
            print("Updating selected date to: \(date)")
            selectedDate = date
        }
    }
} 