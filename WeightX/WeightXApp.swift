//
//  WeightXApp.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 02/10/24.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct WeightXApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            OnboardingView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure() // Configure Firebase only here
        return true
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
         return GIDSignIn.sharedInstance.handle(url)
     }
}

