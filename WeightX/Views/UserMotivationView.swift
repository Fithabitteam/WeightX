struct UserMotivationView: View {
    @State private var selectedMotivations: Set<String> = []
    @Environment(\.presentationMode) var presentationMode
    
    let motivationOptions = [
        "Better Health",
        "More Energy",
        "Look Better",
        "Feel Confident",
        "Athletic Performance",
        "Mental Wellbeing",
        "Social Events",
        "Doctor's Recommendation"
    ]
    
    var body: some View {
        List {
            Section {
                ForEach(motivationOptions, id: \.self) { motivation in
                    Button(action: { toggleMotivation(motivation) }) {
                        HStack {
                            Text(motivation)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedMotivations.contains(motivation) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } header: {
                Text("Select your motivations")
            }
        }
        .navigationTitle("Update Motivations")
        .navigationBarItems(trailing: Button("Save") {
            saveMotivations()
        })
        .onAppear(perform: loadCurrentMotivations)
    }
    
    private func toggleMotivation(_ motivation: String) {
        if selectedMotivations.contains(motivation) {
            selectedMotivations.remove(motivation)
        } else {
            selectedMotivations.insert(motivation)
        }
    }
    
    private func loadCurrentMotivations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error loading motivations: \(error)")
                return
            }
            
            if let data = snapshot?.data(),
               let motivations = data["motivations"] as? [String] {
                selectedMotivations = Set(motivations)
            }
        }
    }
    
    private func saveMotivations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "motivations": Array(selectedMotivations)
        ]) { error in
            if let error = error {
                print("Error saving motivations: \(error)")
                return
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
} 