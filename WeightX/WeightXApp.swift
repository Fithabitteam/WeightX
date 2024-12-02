//
//  WeightXApp.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 02/10/24.
//

import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseAuth

@main
struct WeightXApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isUserSignedIn = false

    var body: some Scene {
        WindowGroup {
                // Otherwise, show the onboarding/sign-in view
                ContentView()
        }
    }
}

