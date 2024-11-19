import SwiftUI
import Firebase
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import FirebaseAuth

struct SignUpView: View {
    @State private var countryCode: String = "+91" // Default to India
    @State private var phoneNumber: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false // Loading state for OTP request
    @State private var showOTPView = false // Show OTP view after OTP request is sent
    
    // Country code list for picker
    let countryCodes = ["+1", "+91", "+44", "+61", "+49"] // Add more as needed
    @State private var showProfileSetting1 = false
    
    var body: some View {
        ZStack {
            // Background Image (same as Onboarding background)
            Image("onboarding_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width)
                .edgesIgnoringSafeArea(.all)
                .opacity(0.8)
            
            VStack {
                Text("Sign Up")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 10)
                
                // Country Code and Phone Number Entry
                HStack {
                    // Country Code Picker
                    Menu {
                        ForEach(countryCodes, id: \.self) { code in
                            Button(action: {
                                countryCode = code
                            }) {
                                Text(code)
                            }
                        }
                    } label: {
                        HStack {
                            Text(countryCode)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .frame(maxWidth: 100)
                    
                    // Phone Number Input
                    TextField("Mobile Number", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.leading)
                        .onChange(of: phoneNumber) { newValue in
                            if phoneNumber.count >= 10 {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                }
                .padding(.horizontal)
                
                // Continue Button with loading dots
                Button(action: {
                    validatePhoneNumber()
                }) {
                    if isLoading {
                        HStack {
                            Text("• • • • •")
                                .foregroundColor(.white)
                        }
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .disabled(isLoading) // Disable button when loading
                
                // OR Divider
                HStack {
                    Divider()
                        .background(Color.gray)
                    Text("Or")
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                    Divider()
                        .background(Color.gray)
                }
                .padding(.vertical)
                .padding(.horizontal, 20)
                
                // Continue with Google Button
                Button(action: {
                    signInWithGoogle()
                }) {
                    HStack {
                        Image("google_logo")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Continue With Google")
                            .fontWeight(.medium)
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Continue with Apple Button
                Button(action: {
                    signInWithApple()
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.title)
                        Text("Continue With Apple")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Sign Up with Email Button
                Button(action: {
                    // Handle sign-up with email
                }) {
                    Text("Sign Up With Email")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
                
                Spacer()
                
                // Show error if any
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .onTapGesture {
                hideKeyboard()
            }
        }
        .fullScreenCover(isPresented: $showOTPView) {
            OTPView(phoneNumber: "\(countryCode) \(phoneNumber)")
        }
        .fullScreenCover(isPresented: $showProfileSetting1) {
            ProfileSettings1() // Show HomeScreen after successful login
        }
    }
    
    // Validate phone number format and trigger Firebase OTP
    func validatePhoneNumber() {
        let fullPhoneNumber = "\(countryCode)\(phoneNumber)"
        
        // Basic phone number validation
       /* if phoneNumber.isEmpty || phoneNumber.count != 10 {
            errorMessage = "Please enter a valid 10-digit phone number."
            showError = true
            return
        }*/
        
        // Set loading state
        isLoading = true
        
        // Send OTP via Firebase
        signInWithPhoneNumber(phoneNumber: fullPhoneNumber)
    }
    
    // Firebase Phone Number Authentication
    func signInWithPhoneNumber(phoneNumber: String) {
        showError = false
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error as NSError? {
                   print("Error: \(error.localizedDescription) - Code: \(error.code)")
               } else {
                   UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                   print("Verification ID saved")
               }
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false // Stop loading
                return
            }

            // Store verification ID for OTP verification
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            print("Verification ID saved: \(verificationID ?? "")")
            isLoading = false // Stop loading
            
            // Navigate to OTPView
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
            print("No root view controller found")
            return
        }

        GIDSignIn.sharedInstance.configuration = signInConfig
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user else {
                return
            }

            let idToken = user.idToken!.tokenString
            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // Sign in with Firebase using the Google credentials
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error signing in with Google: \(error.localizedDescription)")
                    return
                }
                if let user = authResult?.user {
                    print("Signed in with Google: \(user.uid)")
                    
                    // Navigate to HomeScreenView after successful login
                    DispatchQueue.main.async {
                        // Set flag to navigate to home screen
                        showProfileSetting1 = true
                    }
                }
            }
        }
    }

    
    func signInWithApple() {
         let nonce = randomNonceString()

         let appleIDProvider = ASAuthorizationAppleIDProvider()
         let request = appleIDProvider.createRequest()
         request.requestedScopes = [.fullName, .email]
         request.nonce = sha256(nonce)

         let delegate = SignInWithAppleDelegate(nonce: nonce) { userID in
             // Pass nonce to the function that authenticates with Firebase
             self.firebaseSignInWithApple(userID: userID, nonce: nonce)
         }

         let authorizationController = ASAuthorizationController(authorizationRequests: [request])
         authorizationController.delegate = delegate
         authorizationController.performRequests()
     }
     
     // Authenticate with Firebase using Apple credentials
     func firebaseSignInWithApple(userID: String, nonce: String) {
         let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: userID, rawNonce: nonce)
         
         Auth.auth().signIn(with: credential) { authResult, error in
             if let error = error {
                 print("Error signing in with Apple: \(error.localizedDescription)")
                 return
             }
             if let user = authResult?.user {
                 print("Signed in with Apple: \(user.uid)")
                 
                 // Navigate to HomeScreenView after successful login
                 DispatchQueue.main.async {
                     showProfileSetting1 = true
                 }
             }
         }
     }
    
    // Helper functions for Apple Sign-In
    func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    // Dismiss keyboard when tapping outside
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
