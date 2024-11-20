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
    @State private var selectedDate = Date()
    @State private var showingAddWeight = false
    @State private var showingSettings = false
    @Binding var isUserLoggedIn: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Week Selector
                WeekSelectorView(selectedDate: $selectedDate)
                    .padding(.horizontal)
                
                // Stats Cards
                HStack(spacing: 16) {
                    StatCard(title: "Weekly Average",
                            value: "75.5 kg",
                            trend: "+0.5 kg")
                    
                    StatCard(title: "vs Last Week",
                            value: "74.8 kg",
                            trend: "-0.7 kg")
                }
                .padding(.horizontal)
                
                // Weight Log Grid
                WeeklyWeightGrid(selectedDate: selectedDate)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Weight Log")
            .navigationBarItems(
                leading: Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .font(.title2)
                },
                trailing: AddWeightButton(showingAddWeight: $showingAddWeight)
            )
            .sheet(isPresented: $showingAddWeight) {
                AddWeightView()
            }
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView(isShowing: $showingSettings, isUserLoggedIn: $isUserLoggedIn)
            }
        }
    }
}

// Settings View
struct SettingsView: View {
    @Binding var isShowing: Bool
    @Binding var isUserLoggedIn: Bool
    @State private var showingLogoutAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                // Settings Options
                Section {
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(
                leading: Button(action: { isShowing = false }) {
                    Text("Done")
                }
            )
        }
        .alert(isPresented: $showingLogoutAlert) {
            Alert(
                title: Text("Logout"),
                message: Text("Are you sure you want to logout?"),
                primaryButton: .destructive(Text("Logout")) {
                    logout()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "authVerificationID")
            isUserLoggedIn = false
            isShowing = false
            // Force UI update
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("LogoutSuccess"), object: nil)
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

// Helper Views
struct WeekSelectorView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        HStack {
            Button(action: { moveWeek(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }
            
            Text(weekRangeString)
                .font(.headline)
            
            Button(action: { moveWeek(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var weekRangeString: String {
        // Format the week range string
        // Implementation needed
        return "Oct 1 - Oct 7"
    }
    
    private func moveWeek(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: amount, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(trend)
                .font(.caption)
                .foregroundColor(trend.hasPrefix("+") ? .red : .green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WeeklyWeightGrid: View {
    let selectedDate: Date
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16) {
            ForEach(0..<7) { index in
                DayWeightCell(day: "Mon", weight: "75.5")
            }
        }
    }
}

struct DayWeightCell: View {
    let day: String
    let weight: String?
    
    var body: some View {
        VStack(spacing: 4) {
            Text(day)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let weight = weight {
                Text(weight)
                    .font(.callout)
                    .fontWeight(.medium)
            } else {
                Text("-")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AddWeightButton: View {
    @Binding var showingAddWeight: Bool
    
    var body: some View {
        Button(action: { showingAddWeight = true }) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
        }
    }
}

struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView(isUserLoggedIn: .constant(true))
    }
}

