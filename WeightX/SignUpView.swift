import SwiftUI
import Firebase
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import FirebaseAuth



struct SignUpView: View {
    @State private var userID: String?
    
    var body: some View {
        VStack {
            Text("Sign Up")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 10)
            
            // Mobile Number Authentication Button
            Button(action: {
                signInWithPhoneNumber(phoneNumber: "+91XXXXXXXXXX")
            }) {
                Text("Continue with Phone Number")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding()
            
            // Google Authentication Button
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
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 2)
            }
            .padding(.horizontal)
            
            // Apple Authentication Button
            Button(action: {
                signInWithApple()
            }) {
                HStack {
                    Image(systemName: "applelogo")
                        .font(.title)
                    Text("Continue With Apple")
                        .fontWeight(.medium)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            if let savedUserID = UserDefaults.standard.string(forKey: "userID") {
                self.userID = savedUserID
                print("User ID loaded: \(savedUserID)")
            }
        }
    }
    
    func signInWithPhoneNumber(phoneNumber: String) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            print("Verification ID saved")
            // Prompt user for verification code and continue
        }
    }

    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Error: No Client ID found")
            return
        }

        let signInConfig = GIDConfiguration(clientID: clientID)
        
        // Get the current root view controller to present Google Sign-In
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
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error signing in with Google: \(error.localizedDescription)")
                    return
                }
                if let user = authResult?.user {
                    saveUserID(user.uid)
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
            saveUserID(userID)
        }

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = delegate
        authorizationController.performRequests()
    }

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

    func saveUserID(_ userID: String) {
        self.userID = userID
        UserDefaults.standard.set(userID, forKey: "userID")
        print("User ID saved: \(userID)")
    }
}
