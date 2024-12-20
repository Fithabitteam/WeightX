struct UserIntentOfApp: View {
    @State private var selectedIntent: String?
    
    var body: some View {
        NavigationView {
            VStack {
                // Existing content...
            }
            .navigationTitle("Get Started")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 