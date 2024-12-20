struct GoalButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .foregroundColor(.primary)
    }
}

struct GainLossMaintainView: View {
    @State private var selectedGoal: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Progress bar (1/7)
            ProgressView(value: 0.143)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("What's your goal?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    GoalButton(title: "Weight Loss", isSelected: selectedGoal == "Weight Loss") {
                        selectedGoal = "Weight Loss"
                    }
                    
                    GoalButton(title: "Weight Gain", isSelected: selectedGoal == "Weight Gain") {
                        selectedGoal = "Weight Gain"
                    }
                    
                    GoalButton(title: "Maintain Weight", isSelected: selectedGoal == "Maintain Weight") {
                        selectedGoal = "Maintain Weight"
                    }
                }
                .padding()
            }
            
            Spacer()
            
            NavigationLink(destination: UserMotivationView(selectedGoal: selectedGoal)) {
                Text("Next")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedGoal.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedGoal.isEmpty)
            .padding()
        }
        .navigationTitle("Goal Selection (1/7)")
        .navigationBarBackButtonHidden(false)
    }
} 