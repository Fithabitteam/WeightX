//
//  ContentView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 02/11/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth

struct ContentView: View {
    @State private var isUserLoggedIn = false
    
    var body: some View {
        Group {
            if isUserLoggedIn || Auth.auth().currentUser != nil {
                HomeScreenView(isUserLoggedIn: $isUserLoggedIn)
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            isUserLoggedIn = Auth.auth().currentUser != nil
        }
    }
}
