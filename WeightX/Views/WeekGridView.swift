//
//  WeekGridView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 24/11/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class EditState: ObservableObject {
    @Published var entry: WeightLog?
    @Published var date: Date?
    @Published var isReady = false
    
    func reset() {
        entry = nil
        date = nil
        isReady = false
    }
    
    func setEntry(_ log: WeightLog) {
        entry = log
        date = nil
        isReady = true
    }
    
    func setDate(_ newDate: Date) {
        entry = nil
        date = newDate
        isReady = true
    }
}

struct WeeklyWeightGrid: View {
    let week: Week
    let weights: [Date: WeightEntry]
    @StateObject private var editState = EditState()
    @State private var showingEditSheet = false
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16) {
            ForEach(week.days, id: \.self) { date in
                let entry = findWeight(for: date)
                DayCell(date: date, weightEntry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleDayTap(date: date, entry: entry)
                    }
            }
        }
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            editState.reset()
        }) {
            if editState.isReady {
                if let entry = editState.entry {
                    EditWeightView(log: entry) {
                        editState.reset()
                    }
                } else if let date = editState.date {
                    AddWeightView(preselectedDate: date)
                }
            }
        }
    }
    
    private func handleDayTap(date: Date, entry: WeightEntry?) {
        print("\nHandling day tap...")
        
        // Don't allow weight entry for future dates
        if date > Calendar.current.startOfDay(for: Date()) {
            print("Cannot add weight for future date")
            return
        }
        
        // Reset state and sheet
        showingEditSheet = false
        editState.reset()
        
        if let entry = entry {
            print("Found existing entry: weight=\(entry.weight), id=\(entry.id)")
            
            // Create WeightLog
            let log = WeightLog(
                id: entry.id,
                userId: entry.userId,
                weight: entry.weight,
                weightUnit: entry.weightUnit,
                date: entry.date,
                tags: entry.tags,
                notes: entry.notes,
                createdAt: entry.createdAt
            )
            
            // Set entry in state object
            editState.setEntry(log)
            print("Created and set WeightLog: id=\(log.id), weight=\(log.weight)")
        } else {
            print("No existing entry, setting up for new entry")
            editState.setDate(date)
            print("Selected date set: \(date)")
        }
        
        showingEditSheet = true
    }
    
    private func findWeight(for date: Date) -> WeightEntry? {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        for (entryDate, entry) in weights {
            let entryDay = calendar.startOfDay(for: entryDate)
            if calendar.isDate(entryDay, inSameDayAs: targetDay) {
                print("Found weight for \(targetDay): \(entry.weight) \(entry.weightUnit)")
                return entry
            }
        }
        return nil
    }
}

struct DayCell: View {
    let date: Date
    let weightEntry: WeightEntry?
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    
    private var isFutureDate: Bool {
        date > Calendar.current.startOfDay(for: Date())
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(date.formatted(.dateTime.day()))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if let entry = weightEntry {
                VStack(spacing: 0) {
                    let displayWeight = weightUnit.convert(entry.weight, from: .kg)
                    let wholePart = Int(floor(displayWeight))
                    let decimalPart = Int(round((displayWeight - Double(wholePart)) * 100))
                    
                    Text("\(wholePart)")
                        .font(.system(size: 20, weight: .medium))
                    
                    Text(String(format: ".%02d", decimalPart))
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("-")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 90)
        .frame(maxWidth: .infinity)
        .background(isFutureDate ? Color(.systemGray5) : Color(.systemGray6))
        .opacity(isFutureDate ? 0.7 : 1.0)
        .cornerRadius(8)
    }
}
