import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PaceOption: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct EditPaceView: View {
    let currentPace: String
    @State private var selectedPace: String
    @Environment(\.presentationMode) var presentationMode
    
    init(currentPace: String) {
        self.currentPace = currentPace
        _selectedPace = State(initialValue: currentPace)
    }
    
    var body: some View {
        List {
            Section {
                PaceOption(
                    title: "Beginner (4+ months)",
                    subtitle: "250-500gms change per week",
                    isSelected: selectedPace == "Beginner",
                    action: { selectedPace = "Beginner" }
                )
                
                PaceOption(
                    title: "Intermediate (2-4 months)",
                    subtitle: "500-750gms change per week",
                    isSelected: selectedPace == "Intermediate",
                    action: { selectedPace = "Intermediate" }
                )
                
                PaceOption(
                    title: "Advanced (1-2 months)",
                    subtitle: "750-1000gms change per week",
                    isSelected: selectedPace == "Advanced",
                    action: { selectedPace = "Advanced" }
                )
            } header: {
                Text("Select your goal pace")
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("Edit Pace")
        .navigationBarItems(trailing: Button("Save") {
            savePace()
        })
    }
    
    private func savePace() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "goalTimeframe": selectedPace
        ]) { error in
            if let error = error {
                print("Error updating pace: \(error)")
                return
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EditPaceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditPaceView(currentPace: "Beginner")
        }
    }
} 