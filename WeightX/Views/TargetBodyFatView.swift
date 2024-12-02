struct TargetBodyFatView: View {
    @Binding var currentStep: OnboardingStep
    @AppStorage("targetBodyFat") private var targetBodyFat: Double = 0.0
    @AppStorage("weightGoal") private var weightGoal: String = ""
    @State private var bodyFat: String = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Your goal is \(weightGoal)")
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.top)
            
            Text("What's your target body fat?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("Enter target body fat", text: $bodyFat)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
                .padding()
            
            Text("%")
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: saveTargetBodyFat) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Invalid Body Fat"),
                message: Text("Please enter a valid body fat percentage"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveTargetBodyFat() {
        guard let bodyFatValue = Double(bodyFat),
              bodyFatValue > 0 && bodyFatValue <= 100 else {
            showError = true
            return
        }
        
        targetBodyFat = bodyFatValue
        currentStep = .completed
    }
} 