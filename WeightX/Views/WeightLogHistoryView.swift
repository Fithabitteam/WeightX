//
//  WeightLogHistoryView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 30/11/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct WeightLogHistoryView: View {
    @State private var weights: [WeightEntry] = []
    @State private var isLoading = true
    @State private var showingEditSheet = false
    @StateObject private var editState = EditState()
    
    var body: some View {
        NavigationView {
            ZStack {
                if weights.isEmpty && !isLoading {
                    Text("No weight entries yet")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(weights) { entry in
                            WeightLogRow(entry: entry)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    handleWeightTap(entry: entry)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteWeight(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        handleWeightTap(entry: entry)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .opacity(isLoading ? 0 : 1)
                }
                
                if isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("Weight Log")
            .sheet(isPresented: $showingEditSheet, onDismiss: {
                editState.reset()
            }) {
                Group {
                    if editState.isReady, let entry = editState.entry {
                        EditWeightView(log: entry) {
                            editState.reset()
                            fetchWeights()
                        }
                    } else {
                        // Empty view while state is not ready
                        Color.clear
                    }
                }
            }
            .onAppear {
                fetchWeights()
            }
        }
    }
    
    private func handleWeightTap(entry: WeightEntry) {
        print("\nHandling weight tap...")
        
        // Reset state and sheet
        showingEditSheet = false
        editState.reset()
        
        print("Creating WeightLog for entry: weight=\(entry.weight)kg, id=\(entry.id)")
        
        // Create WeightLog
        let log = WeightLog(
            id: entry.id,
            userId: entry.userId,
            weight: entry.weight,
            weightUnit: UserSettings.shared.weightUnit.rawValue,
            date: entry.date,
            tags: entry.tags,
            notes: entry.notes,
            createdAt: entry.createdAt
        )
        
        // Set entry in state object
        editState.setEntry(log)
        print("Set WeightLog in editState: weight=\(log.weight)kg, isReady=\(editState.isReady)")
        
        // Show sheet after state is set
        print("Showing edit sheet")
        showingEditSheet = true
    }
    
    private func deleteWeight(_ entry: WeightEntry) {
        let db = Firestore.firestore()
        db.collection("weights").document(entry.id).delete { error in
            if let error = error {
                print("Error deleting weight: \(error)")
            }
        }
    }
    
    private func fetchWeights() {
        guard let userId = Auth.auth().currentUser?.uid else { 
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return 
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        let db = Firestore.firestore()
        db.collection("weights")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in  // Use snapshot listener for real-time updates
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching weights: \(error)")
                        self.isLoading = false
                        return
                    }
                    
                    self.weights = snapshot?.documents.compactMap { WeightEntry(from: $0) } ?? []
                    self.isLoading = false
                    
                    // Debug print
                    print("Fetched \(self.weights.count) weights")
                    self.weights.forEach { entry in
                        print("Weight: \(entry.weight) \(entry.weightUnit) on \(entry.date)")
                    }
                }
            }
    }
}

struct WeightLogRow: View {
    let entry: WeightEntry
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(format: "%.2f %@",
                     weightUnit.convert(entry.weight, from: .kg),
                     weightUnit.rawValue))
                    .font(.headline)
                
                Spacer()
                
                Text(formatDate(entry.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entry.tags, id: \.self) { tag in
                            TagChip(tag: tag)
                        }
                    }
                }
            }
            
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TagChip: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
            .foregroundColor(.blue)
    }
}
