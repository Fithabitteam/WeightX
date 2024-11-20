import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseAuth

struct SignUpView: View {
    @State private var countryCode: String = "+91" // Default to India
    @State private var phoneNumber: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var showOTPView = false
    @State private var showProfileSetting1 = false
    @State private var showUserIntent = false
    
    // Country code list for picker
    let countryCodes = ["+1", "+91", "+44", "+61", "+49"]
    
    var body: some View {
        ZStack {
            Color(.systemBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                Text("Sign Up")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 32)
                
                // Phone Number Entry
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        // Country Code Menu
                        Menu {
                            ForEach(countryCodes, id: \.self) { code in
                                Button(action: { countryCode = code }) {
                                    Text(code)
                                }
                            }
                        } label: {
                            Text(countryCode)
                                .frame(width: 80, height: 44)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        TextField("Enter phone number", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .textContentType(.telephoneNumber)
                            .frame(height: 44)
                            .padding(.horizontal)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Continue Button
                Button(action: validatePhoneNumber) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(isLoading)
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                    Text("or")
                        .foregroundColor(.secondary)
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                }
                .padding(.horizontal)
                
                // Google Sign In Button
                Button(action: signInWithGoogle) {
                    HStack {
                        Image("google_logo")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Continue with Google")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showOTPView) {
            OTPView(phoneNumber: "\(countryCode)\(phoneNumber)")
        }
        .fullScreenCover(isPresented: $showUserIntent) {
            UserIntentOfApp()
        }
        .fullScreenCover(isPresented: $showProfileSetting1) {
            ContentView()  // Changed from ProfileSettings1 to ContentView for existing users
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // Validate phone number and trigger Firebase OTP
    func validatePhoneNumber() {
        let fullPhoneNumber = "\(countryCode)\(phoneNumber)"
        
        // Basic phone number validation
        if phoneNumber.isEmpty || phoneNumber.count != 10 {
            errorMessage = "Please enter a valid 10-digit phone number."
            showError = true
            return
        }
        
        isLoading = true
        signInWithPhoneNumber(phoneNumber: fullPhoneNumber)
    }
    
    // Firebase Phone Number Authentication
    func signInWithPhoneNumber(phoneNumber: String) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
                return
            }
            
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            showOTPView = true
        }
    }
    
    // Google Sign In
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { 
            print("Error: No Client ID found")
            return 
        }
        
        let signInConfig = GIDConfiguration(clientID: clientID)
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else { 
            print("Error: No root view controller found")
            return 
        }
        
        GIDSignIn.sharedInstance.configuration = signInConfig
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("Google Sign In Error: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.showError = true
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("Error: Failed to get user or ID token")
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { [self] authResult, error in
                if let error = error {
                    print("Firebase Sign In Error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                // Check if user is new
                if let isNewUser = authResult?.additionalUserInfo?.isNewUser {
                    DispatchQueue.main.async {
                        if isNewUser {
                            print("New user detected, showing UserIntentOfApp")
                            self.showUserIntent = true
                        } else {
                            print("Existing user detected, showing HomeScreen")
                            self.showProfileSetting1 = true
                        }
                    }
                }
            }
        }
    }
}
