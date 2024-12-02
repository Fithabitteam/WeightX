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
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // App Title
                    Text("WeightX")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Subtitle
                    Text("Track your weight progress with ease")
                        .font(.title3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Get Started Button
                    NavigationLink(destination: SignUpView()) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 44) // Minimum touch target
                            .background(Color.blue)
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
