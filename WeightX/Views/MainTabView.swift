struct MainTabView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var selectedTab = 0
    @State private var showingAddWeight = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                ZStack(alignment: .bottomTrailing) {
                    HomeScreenView(isUserLoggedIn: $isUserLoggedIn)
                    
                    // Floating Action Button
                    Button(action: { showingAddWeight = true }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 70)
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationView {
                WeightLogHistoryView()
            }
            .tabItem {
                Label("History", systemImage: "list.bullet")
            }
            .tag(1)
        }
        .sheet(isPresented: $showingAddWeight) {
            AddWeightView()
        }
        .onAppear {
            UserSettings.shared.loadWeightUnitFromFirestore()
        }
    }
} 