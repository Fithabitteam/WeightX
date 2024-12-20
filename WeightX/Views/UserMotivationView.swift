import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct MotivationButton: View {
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

struct UserMotivationView: View {
    let selectedGoal: String
    @State private var selectedMotivations: Set<String> = []
    
    let motivationOptions = [
        "Prepare for social event",
        "Keeping up with friends",
        "Improving overall health",
        "To look and feel good",
        "Training for a sport",
        "To make fitness your hobby"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Progress bar (2/7)
            ProgressView(value: 0.286)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("What motivates you?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ForEach(motivationOptions, id: \.self) { motivation in
                        MotivationButton(
                            title: motivation,
                            isSelected: selectedMotivations.contains(motivation)
                        ) {
                            if selectedMotivations.contains(motivation) {
                                selectedMotivations.remove(motivation)
                            } else {
                                selectedMotivations.insert(motivation)
                            }
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
            
            NavigationLink(
                destination: PersonalInfoView(
                    selectedGoal: selectedGoal,
                    motivations: Array(selectedMotivations)
                )
            ) {
                Text("Next")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(!selectedMotivations.isEmpty ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedMotivations.isEmpty)
            .padding()
        }
        .navigationTitle("Motivation (2/7)")
        .navigationBarBackButtonHidden(false)
    }
}

// Preview
struct UserMotivationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserMotivationView(selectedGoal: "Weight Loss")
        }
    }
}
