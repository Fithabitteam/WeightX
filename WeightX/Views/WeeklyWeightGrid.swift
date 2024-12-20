//
//  WeeklyWeightGrid.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 26/11/24.
//

/*import Foundation
import SwiftUI
import FirebaseFirestore

struct WeeklyWeightGrid: View {
    let week: Week
    let weights: [Date: WeightEntry]
    @State private var selectedEntry: WeightLog?
    @State private var showingEditSheet = false
    @State private var selectedDate: Date?
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16) {
            ForEach(week.days, id: \.self) { date in
                let entry = findWeight(for: date)
                DayCell(date: date, weightEntry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("Tapped date: \(date)")
                        selectedDate = date
                        if let entry = entry {
                            selectedEntry = WeightLog(
                                id: entry.id,
                                userId: entry.userId,
                                weight: entry.weight,
                                weightUnit: entry.weightUnit,
                                date: entry.date,
                                tags: entry.tags,
                                notes: entry.notes,
                                createdAt: entry.createdAt
                            )
                        }
                        showingEditSheet = true
                    }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let log = selectedEntry {
                EditWeightView(log: log) {
                    selectedEntry = nil
                }
            } else if let date = selectedDate {
                AddWeightView(preselectedDate: date)
            }
        }
    }
    
    private func findWeight(for date: Date) -> WeightEntry? {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return weights.first { entryDate, _ in
            calendar.isDate(calendar.startOfDay(for: entryDate), inSameDayAs: targetDay)
        }?.value
    }
}*/
