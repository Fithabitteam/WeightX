import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditGoalView: View {
    @State private var selectedGoal: String
    @Environment(\.dismiss) var dismiss
    
    private let goalOptions = [
        (title: "Weight Loss", description: "Reduce body weight and fat", icon: "arrow.down.circle"),
        (title: "Weight Gain", description: "Build muscle and increase weight", icon: "arrow.up.circle"),
        (title: "Maintain Weight", description: "Keep current weight stable", icon: "circle")
    ]
    
    init(currentGoal: String) {
        _selectedGoal = State(initialValue: currentGoal)
    }
    
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
                    
                    ForEach(goalOptions, id: \.title) { goal in
                        GoalButton(
                            title: goal.title,
                            description: goal.description,
                            icon: goal.icon,
                            isSelected: selectedGoal == goal.title
                        ) {
                            selectedGoal = goal.title
                        }
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
        .navigationTitle("Edit Goal (1/7)")
        .navigationBarBackButtonHidden(false)
    }
}
