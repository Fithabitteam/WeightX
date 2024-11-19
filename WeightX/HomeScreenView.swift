//
//  HomeScreenView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 11/10/24.
//

//
//  HomeScreenView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 11/10/24.
//

import Foundation
import SwiftUI
import FirebaseAuth

struct HomeScreenView: View {
    @AppStorage("userName") private var username: String = ""

    var body: some View {
        VStack {
            if !username.isEmpty {
                Text("Hi, \(username)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
            } else {
                Text("Hi")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
            }
            
            Button(action: {
                do {
                    try Auth.auth().signOut()
                    // Navigate to Onboarding or Sign-In screen after logout
                    if let window = UIApplication.shared.windows.first {
                        window.rootViewController = UIHostingController(rootView: OnboardingView())
                        window.makeKeyAndVisible()
                    }
                } catch let signOutError as NSError {
                    print("Error signing out: %@", signOutError)
                }
            }) {
                Text("Logout")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .onAppear {
            // Get the current user's display name
            if let user = Auth.auth().currentUser {
                username = user.displayName ?? "User"
            }
        }
    }
}

struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView()
    }
}

