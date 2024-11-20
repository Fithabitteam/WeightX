//
//  OTPView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 11/10/24.
//

import SwiftUI
import FirebaseAuth

struct OTPView: View {
    @State private var otpCode: [String] = Array(repeating: "", count: 6)
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showHomeScreen = false
    @FocusState private var focusedField: Int?
    @State private var showProfileSetting1 = false
    @State private var showUserIntent = false
    
    let phoneNumber: String
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Verification Code")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enter the code sent to\n\(phoneNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // OTP Input Fields
                    HStack(spacing: 12) {
                        ForEach(0..<6) { index in
                            OTPTextField(text: $otpCode[index], 
                                       isFocused: focusedField == index,
                                       onCommit: { handleOTPInput(index: index) })
                                .focused($focusedField, equals: index)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Verify Button
                    Button(action: verifyOTP) {
                        Text("Verify")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(otpCode.contains(""))
                    
                    // Resend Code
                    Button(action: resendOTP) {
                        Text("Resend Code")
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: BackButton())
            .fullScreenCover(isPresented: $showProfileSetting1) {
                ProfileSettings1()
            }
            .fullScreenCover(isPresented: $showUserIntent) {
                UserIntentOfApp()
            }
            .fullScreenCover(isPresented: $showHomeScreen) {
                ContentView()
            }
        }
    }
    
    private func handleOTPInput(index: Int) {
        if !otpCode[index].isEmpty {
            if index < 5 {
                focusedField = index + 1
            } else {
                focusedField = nil
                verifyOTP()
            }
        }
    }
    
    private func verifyOTP() {
        let code = otpCode.joined()
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            errorMessage = "Invalid verification session"
            showError = true
            return
        }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
                return
            }
            
            // Check if user is new
            if let isNewUser = authResult?.additionalUserInfo?.isNewUser, isNewUser {
                // If new user, show UserIntentOfApp screen
                showUserIntent = true
            } else {
                // If existing user, show HomeScreen
                showHomeScreen = true
            }
        }
    }
    
    private func resendOTP() {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
                return
            }
            
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            // Reset OTP fields
            otpCode = Array(repeating: "", count: 6)
            focusedField = 0
        }
    }
}

// Helper Views
struct OTPTextField: View {
    @Binding var text: String
    var isFocused: Bool
    var onCommit: () -> Void
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(width: 45, height: 45)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.blue : Color.gray, lineWidth: 1)
            )
            .onChange(of: text) { newValue in
                if newValue.count > 1 {
                    text = String(newValue.prefix(1))
                }
                if !newValue.isEmpty {
                    onCommit()
                }
            }
    }
}

struct BackButton: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(.primary)
        }
    }
}

