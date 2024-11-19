//
//  OTPView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 11/10/24.
//

import SwiftUI
import FirebaseAuth

struct OTPView: View {
    @State private var otpCode: [String] = Array(repeating: "", count: 6) // Store each digit separately
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showHomeScreen = false // Navigate to HomeScreen after OTP verification
    @FocusState private var focusedField: Int? // Track focused text field
    
    var phoneNumber: String
    
    var body: some View {
        ZStack {
            // Background Image
            Image("onboarding_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width)
                .edgesIgnoringSafeArea(.all)
                .opacity(0.8)
            
            VStack {
                HStack {
                    Button(action: {
                        // Navigate back to sign-up screen
                        goBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding()
                    }
                    Spacer()
                }
                
                Text("Verify your phone number")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter OTP sent to \(phoneNumber)")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.top, 2)
                
                // OTP input
                HStack(spacing: 10) {
                    ForEach(0..<6) { index in
                        OTPTextFieldView(otpCode: $otpCode[index])
                            .focused($focusedField, equals: index) // Focus on specific field
                            .onChange(of: otpCode[index]) { newValue in
                                if newValue.count == 1 { // Move to the next field when a character is entered
                                    focusedField = index + 1
                                }
                            }
                    }
                }
                .padding(.top, 20)
                
                // Verify Button
                Button(action: {
                    verifyOTP()
                }) {
                    Text("Verify")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showHomeScreen) {
            HomeScreenView()
        }
        .onTapGesture {
            // Collapse the keyboard when tapping outside
            hideKeyboard()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard() // Collapse the keyboard when "Done" is tapped
                }
            }
        }
    }
    
    // Navigate back to the SignUpView
    func goBack() {
        // You can navigate back using a dismiss method or pop to the previous view
        // It depends on your navigation architecture
    }
    
    // Verify OTP using Firebase
    func verifyOTP() {
        let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") ?? ""
        let otpString = otpCode.joined() // Concatenate the 6 digits
        guard otpString.count == 6 else {
            errorMessage = "Please enter a valid 6-digit OTP"
            showError = true
            return
        }
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: otpString)
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
                return
            }
            
            // Successful OTP verification, navigate to HomeScreen
            showHomeScreen = true
        }
    }
    
    // Hide the keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct OTPTextFieldView: View {
    @Binding var otpCode: String
    
    var body: some View {
        TextField("", text: $otpCode)
            .frame(width: 40, height: 40)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .background(Color.white.opacity(0.3))
            .cornerRadius(5)
            .textFieldStyle(PlainTextFieldStyle())
            .onChange(of: otpCode) { newValue in
                // Limit the text to a single character
                if newValue.count > 1 {
                    otpCode = String(newValue.prefix(1))
                }
            }
    }
}

