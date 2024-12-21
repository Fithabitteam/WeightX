import SwiftUI
import Firebase
import FirebaseAuth

struct EditWeightView: View {
    let log: WeightLog
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var weight: String
    @State private var date: Date
    @State private var notes: String
    @State private var selectedTags: Set<String>
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var newTag: String = ""
    @State private var showingUnitInfo = false
    @State private var showingSettings = false
    @StateObject private var tagManager = TagManager.shared
    @State private var settingsNavigationPath = NavigationPath()
    
    var availableTags: [String] {
        let defaultTags = [
            "Morning",
            "Evening",
            "Post-Workout",
            "Pre-Workout",
            "Fasted"
        ]
        return defaultTags + tagManager.userTags.reversed()
    }
    
    init(log: WeightLog, onSave: @escaping () -> Void) {
        self.log = log
        self.onSave = onSave
        
        // Initialize with the display weight (converted to user's preferred unit)
        _weight = State(initialValue: String(format: "%.2f", log.displayWeight))
        _date = State(initialValue: log.date)
        _notes = State(initialValue: log.notes)
        _selectedTags = State(initialValue: Set(log.tags))
        
        print("EditWeightView initialized with weight: \(log.weight)kg, display weight: \(log.displayWeight) \(UserSettings.shared.weightUnit.rawValue)")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Weight Entry")) {
                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(height: 56)
                        
                        Text(UserSettings.shared.weightUnit.rawValue)
                            .foregroundColor(.secondary)
                        
                        Button(action: { showingUnitInfo = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    DatePicker("Date", selection: $date)
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
                    
                    TagGridView(
                        tags: availableTags,
                        selectedTags: selectedTags,
                        onTagTap: toggleTag
                    )
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Weight")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
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
                SettingsView(
                    isShowing: $showingSettings, 
                    isUserLoggedIn: .constant(true),
                    navigationPath: $settingsNavigationPath
                )
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func saveChanges() {
        guard let weightValue = Double(weight) else {
            errorMessage = "Please enter a valid weight"
            showError = true
            return
        }
        
        // Convert to kg for storage if needed
        let weightInKg = UserSettings.shared.weightUnit == .kg ? weightValue : WeightUnit.kg.convert(weightValue, from: .lbs)
        
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "weight": weightInKg,  // Always store in kg
            "date": Timestamp(date: date),
            "notes": notes,
            "tags": Array(selectedTags),
            "updatedAt": Timestamp()
        ]
        
        db.collection("weights").document(log.id).updateData(data) { error in
            if let error = error {
                errorMessage = "Failed to update: \(error.localizedDescription)"
                showError = true
                return
            }
            
            onSave()
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func addCustomTag() {
        guard !newTag.isEmpty else { return }
        let trimmedTag = newTag.trimmingCharacters(in: .whitespaces)
        
        Task {
            do {
                try await tagManager.addTag(trimmedTag)
                selectedTags.insert(trimmedTag)
                newTag = ""
            } catch {
                errorMessage = "Failed to save custom tag"
                showError = true
            }
        }
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}
