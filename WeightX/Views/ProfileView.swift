import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class DateEditState: ObservableObject {
    @Published var date: Date
    @Published var field: String
    @Published var isReady = false
    
    init() {
        self.date = Date()
        self.field = ""
    }
    
    func reset() {
        date = Date()
        field = ""
        isReady = false
    }
    
    func setDate(_ newDate: Date, field: String) {
        self.date = newDate
        self.field = field
        self.isReady = true
    }
}

struct ProfileView: View {
    @State private var userData: [String: Any] = [:]
    @State private var showingGoalFlow = false
    @State private var showingEditSheet = false
    @State private var editingField = ""
    @State private var editValue = ""
    @StateObject private var dateEditState = DateEditState()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            // Personal Information Section
            Section {
                          EditableRow(
                              title: "Name",
                              value: userData["name"] as? String ?? "Not set",
                              onEdit: { startEditing("name", value: userData["name"] as? String ?? "") }
                          )
                          
                          // Add email row (non-editable)
                          HStack {
                              Text("Email")
                              Spacer()
                              Text(Auth.auth().currentUser?.email ?? "Not set")
                                  .foregroundColor(.secondary)
                          }
                
                EditableRow(
                    title: "Date of Birth",
                    value: (userData["dateOfBirth"] as? Timestamp)?.dateValue().formatted(.dateTime.day().month().year()) ?? "Not set",
                    onEdit: {
                        handleDateEdit(
                            field: "dateOfBirth",
                            currentDate: (userData["dateOfBirth"] as? Timestamp)?.dateValue()
                        )
                    }
                )
                
                EditableRow(
                    title: "Height",
                    value: (userData["height"] as? Double).map { "\(String(format: "%.1f", $0)) cm" } ?? "Not set",
                    onEdit: { startEditing("height", value: userData["height"] as? String ?? "") }
                )
                
                NavigationLink(destination: UserSexView()) {
                    HStack {
                        Text("Sex")
                        Spacer()
                        Text(userData["sex"] as? String ?? "Not set")
                            .foregroundColor(.secondary)
                    }
                }
                
                NavigationLink(destination: EditCurrentWeightView(
                    currentWeight: userData["currentWeight"] as? Double ?? 0.0,
                    currentBodyFat: userData["currentBodyFat"] as? Double ?? 0.0
                )) {
                    HStack {
                        Text("Current Weight & Body Fat")
                        Spacer()
                        if let weight = userData["currentWeight"] as? Double {
                            let displayWeight = UserSettings.shared.weightUnit.convert(weight, from: .kg)
                            Text("\(String(format: "%.1f", displayWeight)) \(UserSettings.shared.weightUnit.rawValue)")
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not set")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Personal Information")
            }
            
            // Goals Section
            Section {
                if let goal = userData["weightGoal"] as? String {
                    NavigationLink(destination: EditGoalView(currentGoal: goal)) {
                        HStack {
                            Text("Weight Goal")
                            Spacer()
                            Text(goal)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Button(action: { showingGoalFlow = true }) {
                        Text("Set Weight Goal")
                            .foregroundColor(.blue)
                    }
                }
                
                NavigationLink(destination: EditPaceView(currentPace: userData["goalTimeframe"] as? String ?? "Beginner")) {
                    HStack {
                        Text("Goal Pace")
                        Spacer()
                        if let pace = userData["goalTimeframe"] as? String {
                            VStack(alignment: .trailing) {
                                Text(pace)
                                    .foregroundColor(.secondary)
                                Text(getPaceDetail(for: pace))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Select pace")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                EditableRow(
                    title: "Target Date",
                    value: (userData["targetDate"] as? Timestamp).flatMap { formatDate($0.dateValue()) } ?? "Set target date",
                    onEdit: {
                        handleDateEdit(
                            field: "targetDate",
                            currentDate: (userData["targetDate"] as? Timestamp)?.dateValue()
                        )
                    }
                )
                
                if let targetWeight = userData["targetWeight"] as? Double {
                    NavigationLink(destination: EditTargetView(
                        currentWeight: targetWeight,
                        currentBodyFat: userData["targetBodyFat"] as? Double ?? 0.0
                    )) {
                        HStack {
                            Text("Target Weight & Body Fat")
                            Spacer()
                            let displayWeight = UserSettings.shared.weightUnit.convert(targetWeight, from: .kg)
                            Text("\(String(format: "%.1f", displayWeight)) \(UserSettings.shared.weightUnit.rawValue)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Goals")
            }
            
            // Motivations Section
            Section {
                // Update Motivations Button
                NavigationLink(destination: UserMotivationView(selectedGoal: userData["weightGoal"] as? String ?? "")) {
                    Text("Update Motivations")
                        .foregroundColor(.blue)
                }
                
                // Show existing motivations if any
                if let motivations = userData["motivations"] as? [String], !motivations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Motivations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        ForEach(motivations, id: \.self) { motivation in
                            HStack {
                                Text(motivation)
                                    .font(.body)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            } header: {
                Text("Motivations")
            }
        }
                .navigationTitle("Your Profile")
                .onAppear(perform: loadUserData)
                .fullScreenCover(isPresented: $showingGoalFlow) {
                    GoalGuideView()
                }
                .sheet(isPresented: $showingEditSheet, onDismiss: {
                    dateEditState.reset()
                }) {
                    if dateEditState.isReady && ["dateOfBirth", "goalSetDate", "targetDate"].contains(dateEditState.field) {
                        NavigationView {
                            Form {
                                if dateEditState.field == "dateOfBirth" {
                                    DatePicker(
                                        "Select Date",
                                        selection: $dateEditState.date,
                                        in: ...Date(),  // Past dates for DOB
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.graphical)
                                    .frame(maxHeight: 400)
                                } else {
                                    DatePicker(
                                        "Select Date",
                                        selection: $dateEditState.date,
                                        in: Date()...,  // Future dates for other date fields
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.graphical)
                                    .frame(maxHeight: 400)
                                }
                            }
                            .navigationTitle("Edit \(dateEditState.field.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).capitalized)")
                            .navigationBarItems(
                                leading: Button("Cancel") {
                                    showingEditSheet = false
                                },
                                trailing: Button("Save") {
                                    saveDateEdit()
                                    showingEditSheet = false
                                }
                            )
                        }
                    } else {
                        EditSheet(
                            field: editingField,
                            value: $editValue,
                            date: $dateEditState.date,
                            onSave: saveEdit
                        )
                    }
                }
            }
    private func getPaceDetail(for pace: String) -> String {
        switch pace {
        case "Beginner":
            return "250-500gms per week"
        case "Intermediate":
            return "500-750gms per week"
        case "Advanced":
            return "750-1000gms per week"
        default:
            return ""
        }
    }
    private func handleDateEdit(field: String, currentDate: Date?) {
            print("\nHandling date edit for field: \(field)")
            
            showingEditSheet = false
            dateEditState.reset()
            
            let initialDate = currentDate ?? Date()
            dateEditState.setDate(initialDate, field: field)
            print("Set date for editing: \(initialDate)")
            
            if dateEditState.isReady {
                print("State is ready, showing date edit sheet")
                showingEditSheet = true
            } else {
                print("ERROR: Date edit state not ready")
            }
        }
        
        private func saveDateEdit() {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            let db = Firestore.firestore()
            db.collection("users").document(userId).updateData([
                dateEditState.field: Timestamp(date: dateEditState.date)
            ]) { error in
                if let error = error {
                    print("Error updating \(dateEditState.field): \(error)")
                } else {
                    print("Successfully updated \(dateEditState.field)")
                    loadUserData()
                }
            }
        }
        
        private func startEditing(_ field: String, value: String) {
            editingField = field
            editValue = value
            showingEditSheet = true
        }
        
        private func saveEdit() {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            var value: Any
            switch editingField {
            case "height":
                value = Double(editValue) ?? 0.0
            default:
                value = editValue
            }
            
            let db = Firestore.firestore()
            db.collection("users").document(userId).updateData([
                editingField: value
            ]) { error in
                if let error = error {
                    print("Error updating \(editingField): \(error)")
                } else {
                    loadUserData()
                }
            }
            
            showingEditSheet = false
        }
        
        private func loadUserData() {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            let db = Firestore.firestore()
            db.collection("users").document(userId).getDocument { snapshot, error in
                if let error = error {
                    print("Error loading user data: \(error)")
                    return
                }
                
                if let data = snapshot?.data() {
                    userData = data
                    print("Loaded user data: \(data)")
                }
            }
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    private func debugPrint(_ message: String) {
        #if DEBUG
        print("ProfileView: \(message)")
        #endif
    }

}

struct EditableRow: View {
    let title: String
    let value: String
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
        }
    }
}

struct EditSheet: View {
    let field: String
    @Binding var value: String
    @Binding var date: Date
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    // Add this computed property to determine if it's a date field
    private var isDateField: Bool {
        ["dateOfBirth", "goalSetDate", "targetDate"].contains(field)
    }
    
    var body: some View {
        NavigationView {
            Form {
                if isDateField {
                    if field == "dateOfBirth" {
                        DatePicker(
                            "Select Date",
                            selection: $date,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .frame(maxHeight: 400)
                    } else {
                        DatePicker(
                            "Select Date",
                            selection: $date,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .frame(maxHeight: 400)
                    }
                } else {
                    TextField(field.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).capitalized, text: $value)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .navigationTitle("Edit \(field.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).capitalized)")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    if isDateField {
                        // For date fields, format the date before saving
                        value = formatDate(date)
                    }
                    onSave()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

