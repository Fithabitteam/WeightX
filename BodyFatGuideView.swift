// First, add this enum at the top level of your file
enum UserGender: String {
    case male = "Male"
    case female = "Female"
    
    var bodyFatImage: String {
        switch self {
        case .male:
            return "MenBF"  // Update this to match your asset name
        case .female:
            return "WomenBF"  // Update this to match your asset name
        }
    }
}

// Update BodyFatGuideView to use the enum
struct BodyFatGuideView: View {
    let userSex: String
    @Environment(\.presentationMode) var presentationMode
    
    private var gender: UserGender {
        UserGender(rawValue: userSex) ?? .male // Default to male if invalid string
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Image(gender.bodyFatImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
                
                Text("Body Fat Percentage Reference Guide")
                    .font(.headline)
                    .padding()
                
                Text("This is a visual guide to help estimate your body fat percentage. For accurate measurements, consider using professional methods like DEXA scan or calipers.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationBarItems(
                trailing: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
} 