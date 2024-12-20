import SwiftUI
import Charts
import FirebaseFirestore
import Foundation

struct BodyFatGuideView: View {
    let userSex: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Image(userSex == "Male" ? "male_bodyfat_guide" : "female_bodyfat_guide")
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
// Preview
struct BodyFatGuideView_Previews: PreviewProvider {
    static var previews: some View {
        BodyFatGuideView(userSex: "male")
    }
} 
