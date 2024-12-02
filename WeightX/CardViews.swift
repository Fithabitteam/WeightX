import SwiftUI

struct SexOptionCard: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct GoalOptionCard: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct MotivationCard: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// Preview Provider
struct CardViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SexOptionCard(title: "Male", isSelected: true)
            SexOptionCard(title: "Female", isSelected: false)
            
            GoalOptionCard(title: "Weight Loss", isSelected: true)
            GoalOptionCard(title: "Weight Gain", isSelected: false)
            
            MotivationCard(title: "Better Health", isSelected: true)
            MotivationCard(title: "More Energy", isSelected: false)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 