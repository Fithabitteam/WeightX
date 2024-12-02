import SwiftUI
import Firebase
import FirebaseAuth

struct PersonalInfoView: View {
    let selectedGoal: String
    let motivations: [String]
    @State private var name: String = ""
    @State private var birthDate = Date()
    @State private var selectedSex: String = "Male"
    @State private var height: String = ""
    @State private var isHeightInCM: Bool = true
    @State private var showNextScreen = false
    @State private var progress: Double = 0.429 // 3/7
    @AppStorage("lastCompletedPage") private var lastCompletedPage: Int = 3
    @State private var showDatePicker = false
    
    let sexOptions = ["Male", "Female"]
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: birthDate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 24) {
                    // Progress bar
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .padding()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Let's get to know you")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top)
                            
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.headline)
                                TextField("Enter your name", text: $name)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.name)
                            }
                            
                            // Date of Birth
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date of Birth")
                                    .font(.headline)
                                Button(action: { showDatePicker = true }) {
                                    HStack {
                                        Text(formattedDate)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "calendar")
                                            .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // Sex Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sex")
                                    .font(.headline)
                                Picker("Sex", selection: $selectedSex) {
                                    ForEach(sexOptions, id: \.self) { option in
                                        Text(option).tag(option)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            // Height Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Height")
                                    .font(.headline)
                                HStack {
                                    TextField("Enter height", text: $height)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Picker("Unit", selection: $isHeightInCM) {
                                        Text("cm").tag(true)
                                        Text("inch").tag(false)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .frame(width: 100)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Continue Button - Fixed at bottom
                    VStack {
                        Button(action: saveAndContinue) {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(isInputValid ? Color.blue : Color.gray)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .disabled(!isInputValid)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Profile Setup (3/7)")
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $showNextScreen) {
                UserCurrentView(selectedGoal: selectedGoal, userSex: selectedSex, motivations: motivations)
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(birthDate: $birthDate, isPresented: $showDatePicker)
            }
            .onAppear(perform: prefillUserData)
        }
    }
    
    private var isInputValid: Bool {
        !name.isEmpty && !height.isEmpty
    }
    
    private func prefillUserData() {
        if let user = Auth.auth().currentUser {
            name = user.displayName ?? ""
        }
    }
    
    private func saveAndContinue() {
        guard isInputValid else { return }
        
        guard let user = Auth.auth().currentUser else { return }
        
        let userData: [String: Any] = [
            "name": name,
            "dateOfBirth": Timestamp(date: birthDate),
            "sex": selectedSex,
            "height": Double(height) ?? 0,
            "heightUnit": isHeightInCM ? "cm" : "inch",
            "lastCompletedPage": 3
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData(userData, merge: true) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
                return
            }
            
            lastCompletedPage = 3
            showNextScreen = true
        }
    }
}

struct DatePickerSheet: View {
    @Binding var birthDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("", selection: $birthDate,
                          in: ...Date(),
                          displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Done") {
                    isPresented = false
                }
            )
        }
    }
}

struct PersonalInfoView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalInfoView(selectedGoal: "Lose Weight", motivations: ["Motivation 1", "Motivation 2"])
    }
} 