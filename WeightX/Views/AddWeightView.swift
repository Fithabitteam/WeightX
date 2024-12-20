//
//  AddWeightView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 20/11/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct AddWeightView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var weight: String = ""
    @State private var date: Date
    @State private var notes: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var newTag: String = ""
    @State private var showingUnitInfo = false
    @State private var showingSettings = false
    @FocusState private var isWeightFieldFocused: Bool
    @State private var existingEntry: WeightEntry?
    @State private var isLoadingEntry = false
    private let initialDate: Date?
    
    init(preselectedDate: Date? = nil, initialWeight: String = "") {
        self.initialDate = preselectedDate
        _date = State(initialValue: preselectedDate ?? Date())
        _weight = State(initialValue: initialWeight)
    }
    
    let availableTags = [
        "Morning",
        "Evening",
        "Post-Workout",
        "Pre-Workout",
        "Fasted"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Weight Entry")) {
                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                            .onChange(of: weight) { newValue in
                                // Only allow up to 2 decimal places
                                if let dotIndex = newValue.firstIndex(of: ".") {
                                    let decimals = newValue[newValue.index(after: dotIndex)...]
                                    if decimals.count > 2 {
                                        weight = String(newValue[..<newValue.index(dotIndex, offsetBy: 3)])
                                    }
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(height: 56)
                            .focused($isWeightFieldFocused)
                        
                        Text(UserSettings.shared.weightUnit.rawValue)
                            .foregroundColor(.secondary)
                        
                        Button(action: { showingUnitInfo = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    DatePicker("Date", selection: $date)
                        .onChange(of: date) { newDate in
                            Task {
                                await fetchExistingEntry(for: newDate)
                            }
                        }
                }
                
                Section(header: Text("Tags")) {
                    HStack {
                        TextField("Add custom tag", text: $newTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: addCustomTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newTag.isEmpty)
                    }
                    
                    if !selectedTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(selectedTags), id: \.self) { tag in
                                    TagView(tag: tag) {
                                        selectedTags.remove(tag)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(availableTags, id: \.self) { tag in
                                TagView(
                                    tag: tag,
                                    isSelected: selectedTags.contains(tag)
                                ) {
                                    toggleTag(tag)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Weight")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveWeightEntry()
                }
            )
            .alert("Weight Unit", isPresented: $showingUnitInfo) {
                Button("Go to Settings") {
                    showingSettings = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You can change the weight unit in Settings.")
            }
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView(isShowing: $showingSettings, isUserLoggedIn: .constant(true))
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            if let date = initialDate {
                Task {
                    await fetchExistingEntry(for: date)
                }
            }
        }
    }
    
    private func saveWeightEntry() {
        Task {
            do {
                try await saveWeight()
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Error saving weight: \(error)")
                errorMessage = "Error saving weight. Please try again."
                showError = true
            }
        }
    }
    
    private func saveWeight() async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let weightValue = Double(weight) else {
            throw NSError(domain: "", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Invalid weight value"])
        }
        
        let weightInKg = UserSettings.shared.weightUnit == .kg ? 
            weightValue : 
            weightValue * 0.45359237
        
        let data: [String: Any] = [
            "userId": userId,
            "weight": weightInKg,
            "weightUnit": UserSettings.shared.weightUnit.rawValue,
            "date": date,
            "tags": Array(selectedTags),
            "notes": notes,
            "createdAt": existingEntry?.createdAt ?? Date(),
            "updatedAt": Date()
        ]
        
        let db = Firestore.firestore()
        if let existingEntry = existingEntry {
            try await db.collection("weights").document(existingEntry.id).updateData(data)
        } else {
            try await db.collection("weights").addDocument(data: data)
        }
        
        if HealthKitManager.shared.isHealthKitAvailable {
            try await HealthKitManager.shared.saveWeight(weightInKg, date: date)
        }
    }
    
    private func addCustomTag() {
        guard !newTag.isEmpty else { return }
        selectedTags.insert(newTag.trimmingCharacters(in: .whitespaces))
        newTag = ""
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private func fetchExistingEntry(for date: Date) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoadingEntry = true
        
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("weights")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: dayStart)
                .whereField("date", isLessThan: dayEnd)
                .getDocuments()
            
            if let doc = snapshot.documents.first,
               let entry = WeightEntry(from: doc) {
                DispatchQueue.main.async {
                    self.existingEntry = entry
                    self.weight = String(format: "%.2f", 
                        UserSettings.shared.weightUnit.convert(entry.weight, from: .kg))
                    self.selectedTags = Set(entry.tags)
                    self.notes = entry.notes
                }
            }
        } catch {
            print("Error fetching weight: \(error)")
        }
        isLoadingEntry = false
    }
}

// Helper Views
struct TagView: View {
    let tag: String
    var isSelected: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(tag)
                    .font(.subheadline)
                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.trailing, 4)
    }
}

struct AddWeightView_Previews: PreviewProvider {
    static var previews: some View {
        AddWeightView()
    }
}

