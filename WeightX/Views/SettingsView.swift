struct SettingsView: View {
    @Binding var isShowing: Bool
    @Binding var isUserLoggedIn: Bool
    @State private var selectedUnit: WeightUnit = UserSettings.shared.weightUnit
    @State private var showingSignOutAlert = false
    @State private var showingImport = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink(destination: ProfileView()) {
                        HStack {
                            Image(systemName: "person.circle")
                            Text("Your Profile")
                        }
                    }
                }
                
                Section(header: Text("Weight Unit")) {
                    Picker("Unit", selection: $selectedUnit) {
                        Text("Kilograms (kg)").tag(WeightUnit.kg)
                        Text("Pounds (lbs)").tag(WeightUnit.lbs)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedUnit) { newValue in
                        UserSettings.shared.setWeightUnit(newValue)
                    }
                }
                
                Section {
                    Button(action: { showingImport = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Data")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        HStack {
                            Text("Sign Out")
                            Spacer()
                            Image(systemName: "arrow.right.square")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                isShowing = false
            })
            .sheet(isPresented: $showingImport) {
                ImportView()
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            isUserLoggedIn = false
        } catch {
            print("Error signing out: \(error)")
        }
    }
} 