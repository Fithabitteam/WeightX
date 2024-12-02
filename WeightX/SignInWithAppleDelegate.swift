//
//  SignInWithAppleDelegate.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 09/10/24.
//

import Foundation
import AuthenticationServices
import FirebaseAuth

class SignInWithAppleDelegate: NSObject, ASAuthorizationControllerDelegate {
    var saveUserID: ((String) -> Void)?
    private var nonce: String

    init(nonce: String, saveUserID: @escaping (String) -> Void) {
        self.nonce = nonce
        self.saveUserID = saveUserID
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let identityToken = appleIDCredential.identityToken else {
                print("Failed to fetch identity token")
                return
            }

            guard let tokenString = String(data: identityToken, encoding: .utf8) else {
                print("Failed to decode identity token")
                return
            }

            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error signing in with Apple: \(error.localizedDescription)")
                    return
                }
                if let user = authResult?.user {
                    self.saveUserID?(user.uid)
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Authorization failed: \(error.localizedDescription)")
    }
}
