//
//  MainTabView.swift
//  WeightX
//
//  Created by Keerthanaa Vm on 21/11/24.
//

import Foundation
import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainTabView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var selectedTab = 0
    @State private var settingsNavigationPath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreenView(isUserLoggedIn: $isUserLoggedIn)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            WeightLogHistoryView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Logs")
                }
                .tag(1)
            
            InsightsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Insights")
                }
                .tag(2)
            
            SettingsView(isShowing: .constant(false), 
                        isUserLoggedIn: $isUserLoggedIn,
                        navigationPath: $settingsNavigationPath)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 3 {
                settingsNavigationPath = NavigationPath()
            }
        }
    }
}
