struct UserTargetView: View {
    let selectedGoal: String
    let userSex: String
    let motivations: [String]
    @State private var targetWeight: String = ""
    @State private var targetBodyFat: String = ""
    @State private var isKg: Bool = true
    @State private var showingBFGuide = false
    @State private var showNextScreen = false
    @State private var progress: Double = 0.833 // 83.3% for fifth screen
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 5
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Goal Text
                        Text("Your goal is \(selectedGoal)")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.top)
                        
                        Text("Now let's talk about where we want to be")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Target Weight Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Weight")
                                .font(.headline)
                            
                            HStack {
                                TextField("Enter target weight", text: $targetWeight)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Picker("Unit", selection: $isKg) {
                                    Text("kg").tag(true)
                                    Text("lbs").tag(false)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 100)
                            }
                        }
                        
                        // Target Body Fat Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Body Fat %")
                                .font(.headline)
                            
                            HStack {
                                TextField("Enter target body fat", text: $targetBodyFat)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Text("%")
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: { showingBFGuide = true }) {
                                Text("See body fat percentage reference guide")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .padding()
                }
                
                // Continue Button
                Button(action: saveAndContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(isInputValid ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .disabled(!isInputValid)
            }
            .navigationTitle("Profile Setup (5/6)")
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showingBFGuide) {
                BodyFatGuideView(userSex: userSex)
            }
            .fullScreenCover(isPresented: $showNextScreen) {
                GoalTimelineView(selectedGoal: selectedGoal, userMotivations: motivations)
            }
        }
    }
    
    private func saveAndContinue() {
        // Implementation for saving targets and continuing to the next screen
    }
} 