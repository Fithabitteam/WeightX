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
    @State private var date = Date()
    @State private var notes: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Predefined tags for weight entries
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
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                    
                    DatePicker("Date",
                             selection: $date,
                             displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Tags")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(availableTags, id: \.self) { tag in
                                TagButton(
                                    title: tag,
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
                        .frame(minHeight: 100)
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
                .disabled(!isValidInput)
            )
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var isValidInput: Bool {
        guard let weightValue = Double(weight) else { return false }
        return weightValue > 0
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private func saveWeightEntry() {
        guard let weightValue = Double(weight) else {
            errorMessage = "Please enter a valid weight"
            showError = true
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            showError = true
            return
        }
        
        let weightEntry: [String: Any] = [
            "weight": weightValue,
            "date": Timestamp(date: date),
            "tags": Array(selectedTags),
            "notes": notes,
            "userId": userId,
            "createdAt": Timestamp()
        ]
        
        let db = Firestore.firestore()
        db.collection("weightEntries").addDocument(data: weightEntry) { error in
            if let error = error {
                errorMessage = "Failed to save: \(error.localizedDescription)"
                showError = true
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// Helper Views
struct TagButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.trailing, 8)
    }
}

struct AddWeightView_Previews: PreviewProvider {
    static var previews: some View {
        AddWeightView()
    }
}
