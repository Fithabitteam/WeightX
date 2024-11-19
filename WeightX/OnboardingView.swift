//
//  OnboardingView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 02/10/24.
//

import SwiftUI

struct OnboardingView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Background Image
                Image("onboarding_background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    // App Title
                    Text("Weightx")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.bottom, 16)
                    
                    // Subtitle
                    Text("Track your weight progress with ease")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Spacer()
                    Spacer()
                    
                    // Get Started Button (Navigates to SignUpView)
                    NavigationLink(destination: SignUpView()) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 32)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
