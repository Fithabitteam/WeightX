struct WeeklyAverageCard: View {
    let average: Double
    let difference: Double
    let hasPreviousWeekData: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Average")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if average > 0 {
                Text(String(format: "%.1f kg", average))
                    .font(.title2)
                    .fontWeight(.bold)
                
                if difference != 0 && hasPreviousWeekData {
                    Text(differenceString)
                        .font(.caption)
                        .foregroundColor(difference > 0 ? .red : .green)
                }
            } else {
                Text("-")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var differenceString: String {
        let prefix = difference > 0 ? "+" : ""
        if abs(difference) >= 1 {
            return "\(prefix)\(String(format: "%.1f kg", difference))"
        } else {
            return "\(prefix)\(String(format: "%.0f g", difference * 1000))"
        }
    }
} 