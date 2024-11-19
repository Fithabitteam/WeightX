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
        var body: some View {
            VStack {
                if Auth.auth().currentUser != nil {
                    HomeScreenView()
                }
                else{
                    OnboardingView()                        
                }
            }
            
        }
    }
