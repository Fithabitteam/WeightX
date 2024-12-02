import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @State private var userData: [String: Any] = [:]
    @State private var showingGoalFlow = false
    @State private var showingEditSheet = false
    @State private var editingField = ""
    @State private var editValue = ""
    @State private var editDate = Date()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            Section(header: Text("Personal Information")) {
                EditableRow(
                    title: "Name",
                    value: userData["name"] as? String ?? "Not set",
                    onEdit: { startEditing("name", value: userData["name"] as? String ?? "") }
                )
                
                EditableRow(
                    title: "Date of Birth",
                    value: (userData["dateOfBirth"] as? Timestamp)?.dateValue().formatted(date: .medium, time: .omitted) ?? "Not set",
                    onEdit: {
                        editDate = (userData["dateOfBirth"] as? Timestamp)?.dateValue() ?? Date()
                        editingField = "dateOfBirth"
                        showingEditSheet = true
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
                
                NavigationLink(destination: UserCurrentView(
                    selectedGoal: userData["weightGoal"] as? String ?? "",
                    userSex: userData["sex"] as? String ?? "",
                    motivations: userData["motivations"] as? [String] ?? []
                )) {
                    HStack {
                        Text("Current Weight & Body Fat")
                        Spacer()
                        if let weight = userData["currentWeight"] as? Double {
                            Text("\(String(format: "%.1f", weight)) kg")
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not set")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section(header: Text("Goals")) {
                if let goal = userData["weightGoal"] as? String {
                    NavigationLink(destination: GoalGuideView()) {
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
                
                if let timeframe = userData["goalTimeframe"] as? String {
                    EditableRow(
                        title: "Goal Timeframe",
                        value: timeframe,
                        onEdit: { startEditing("goalTimeframe", value: timeframe) }
                    )
                }
                
                if let targetWeight = userData["targetWeight"] as? Double {
                    NavigationLink(destination: UserTargetView(
                        selectedGoal: userData["weightGoal"] as? String ?? "",
                        userSex: userData["sex"] as? String ?? "",
                        motivations: userData["motivations"] as? [String] ?? []
                    )) {
                        HStack {
                            Text("Target Weight & Body Fat")
                            Spacer()
                            Text("\(String(format: "%.1f", targetWeight)) kg")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section(header: Text("Timeline")) {
                if let goalSetDate = userData["goalSetDate"] as? Timestamp {
                    EditableRow(
                        title: "Goal Set Date",
                        value: formatDate(goalSetDate.dateValue()),
                        onEdit: {
                            editDate = goalSetDate.dateValue()
                            editingField = "goalSetDate"
                            showingEditSheet = true
                        }
                    )
                }
                
                if let targetDate = userData["targetDate"] as? Timestamp {
                    EditableRow(
                        title: "Target Date",
                        value: formatDate(targetDate.dateValue()),
                        onEdit: {
                            editDate = targetDate.dateValue()
                            editingField = "targetDate"
                            showingEditSheet = true
                        }
                    )
                }
            }
            
            Section(header: Text("Motivations")) {
                if let motivations = userData["motivations"] as? [String] {
                    ForEach(motivations, id: \.self) { motivation in
                        Text(motivation)
                    }
                }
                NavigationLink(destination: UserMotivationView()) {
                    Text("Update Motivations")
                }
            }
        }
        .navigationTitle("Your Profile")
        .onAppear(perform: loadUserData)
        .fullScreenCover(isPresented: $showingGoalFlow) {
            GoalGuideView()
        }
        .sheet(isPresented: $showingEditSheet) {
            EditSheet(
                field: editingField,
                value: $editValue,
                date: $editDate,
                onSave: saveEdit
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
    
    private func startEditing(_ field: String, value: String) {
        editingField = field
        editValue = value
        showingEditSheet = true
    }
    
    private func saveEdit() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var value: Any
        switch editingField {
        case "dateOfBirth", "goalSetDate", "targetDate":
            value = Timestamp(date: editDate)
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
    
    var body: some View {
        NavigationView {
            Form {
                if ["dateOfBirth", "goalSetDate", "targetDate"].contains(field) {
                    DatePicker(
                        field.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).capitalized,
                        selection: $date,
                        displayedComponents: .date
                    )
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
                    onSave()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
} 