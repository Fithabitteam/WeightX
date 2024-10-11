//
//  OnboardingView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 02/10/24.
//

import Foundation
import SwiftUI

struct OnboardingView: View {
    @State private var showSignUp = false
    var body: some View {
        VStack {
            Spacer()
            
            // Background Image
            Image("onboarding_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width)
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    VStack {
                        
                        //App Title
                       Text("Weightx")
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.bottom, 16)
                            .padding(.top,12)
                        
                        // Subtitle
                        Spacer()
                        Text("Track your weight progress with ease")
                            .font(.title3).bold()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                        // Get Started Button
                        Button(action: {
                            showSignUp = true
                        }) {
                          
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(12)
                                .padding(.horizontal, 24)
                                .padding(.top,100)
                        }
                        
                        // Login Link
                        Button(action: {
                            // Handle Login action
                        }) {
                            HStack{
                                Text("Already have an account?")
                                    .font(.headline).bold()
                                    .foregroundColor(.white).shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                                    .padding(.top, 1)
                                Text("Login")
                                    .font(.headline).bold()
                                    .foregroundColor(.white).shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                                    .underline()
                                    .padding(.top, 1)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 32)
                )
            
            if showSignUp {
                            SignUpView()
                                .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.7)
                                .background(Color.black.opacity(0.5))
                                .onTapGesture {
                                    showSignUp = false
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
