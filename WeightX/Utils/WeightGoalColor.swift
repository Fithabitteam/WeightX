import SwiftUI

enum WeightGoalColor {
    static func getDifferenceColor(for difference: Double, goal: String?) -> Color {
        guard let goal = goal else { return .secondary }
        
        switch goal {
        case "Weight Gain":
            return difference > 0 ? .green : .red
        case "Weight Loss":
            return difference < 0 ? .green : .red
        case "Maintain Weight":
            return abs(difference) <= 0.2 ? .green : .red
        default:
            return difference > 0 ? .red : .green
        }
    }
}
