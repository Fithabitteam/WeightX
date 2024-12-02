//
//  WeightLogHistoryView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 30/11/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// First, create the EditState class if not already defined
class EditState2: ObservableObject {
    @Published var entry: WeightLog?
    @Published var isReady = false
    
    func reset() {
        entry = nil
        isReady = false
    }
    
    func setEntry(_ log: WeightLog) {
        entry = log
        isReady = true
    }
}

struct WeightLogHistoryView: View {
    @State private var weightLogs: [WeightLog] = []
    @State private var showingDeleteAlert = false
    @State private var logToDelete: WeightLog?
    @State private var showingEditSheet = false
    @StateObject private var editState = EditState2()
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    
    var body: some View {
        NavigationView {
            List {
                ForEach(weightLogs) { log in
                    WeightLogCell(log: log)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleLogTap(log)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                logToDelete = log
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .navigationTitle("Your Logs")
            .alert("Delete Entry", isPresented: $showingDeleteAlert, presenting: logToDelete) { log in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteWeightLog(log)
                }
            } message: { log in
                Text("Are you sure you want to delete this entry?")
            }
            .sheet(isPresented: $showingEditSheet, onDismiss: {
                editState.reset()
            }) {
                if editState.isReady, let log = editState.entry {
                    //print("Presenting EditWeightView with log: \(log.id), weight: \(log.weight)")
                    EditWeightView(log: log) {
                        fetchWeightLogs()
                        editState.reset()
                    }
                }
            }
            .onAppear {
                fetchWeightLogs()
            }
            .onChange(of: weightUnit) { _ in
                fetchWeightLogs()
            }
        }
    }
    
    private func handleLogTap(_ log: WeightLog) {
        print("\nHandling log tap...")
        
        // Reset state and sheet
        showingEditSheet = false
        editState.reset()
        
        // Set entry in state object
        editState.setEntry(log)
        print("Set log for editing: \(log.id), weight: \(log.weight)")
        
        // Show sheet only if state is ready
        if editState.isReady {
            print("State is ready, showing edit sheet")
            showingEditSheet = true
        } else {
            print("ERROR: State not ready")
        }
    }
    
    private func deleteWeightLog(_ log: WeightLog) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("weights").document(log.id).delete { error in
            if let error = error {
                print("Error deleting log: \(error)")
                return
            }
            fetchWeightLogs()
        }
    }
    
    private func fetchWeightLogs() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("weights")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching logs: \(error)")
                    return
                }
                
                print("Found \(snapshot?.documents.count ?? 0) logs")
                weightLogs = snapshot?.documents.compactMap { doc in
                    if let log = WeightLog(from: doc) {
                        print("Parsed log: \(log.weight) \(log.weightUnit) for date: \(log.date)")
                        return log
                    }
                    return nil
                } ?? []
            }
    }
}

struct WeightLogCell: View {
    let log: WeightLog
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formattedDate)
                    .font(.headline)
                Spacer()
                Text(formattedWeight)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            if !log.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(log.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            if !log.notes.isEmpty {
                Text(log.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: log.date)
    }
    
    private var formattedWeight: String {
        let convertedWeight = weightUnit.convert(log.weight, from: .kg)
        return String(format: "%.1f %@", convertedWeight, weightUnit.rawValue)
    }
}
