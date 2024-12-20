import SwiftUI
import Charts
import FirebaseAuth
import FirebaseFirestore

struct InsightsView: View {
    @State private var selectedMonth: Date = Date()
    @State private var monthData: MonthData?
    @State private var isLoadingData = false
    @State private var showWeeklyAverage = false
    @State private var showingYearPerformance = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Month Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Month")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        MonthSelectorView(selectedDate: $selectedMonth)
                            .padding(.horizontal)
                        
                        if isLoadingData {
                            ProgressView("Loading data...")
                                .padding()
                        } else if let monthData = monthData {
                            /* Commented graphs */
                            
                            // Weekly Average Difference Graph
                            WeightDifferenceGraphView(monthData: monthData)
                                .padding(.horizontal)
                        } else {
                            Text("No data available")
                                .padding()
                        }
                    }
                    
                    // Year Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Year")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingYearPerformance = true
                        }) {
                            Text("Check Year Performance")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Insights")
            .fullScreenCover(isPresented: $showingYearPerformance) {
                YearPerformanceView()
            }
            .onAppear {
                fetchMonthData()
            }
            .onChange(of: selectedMonth) { _ in
                fetchMonthData()
            }
        }
    }
    
    private func fetchMonthData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user ID available")
            return
        }
        
        isLoadingData = true
        monthData = nil  // Clear existing data
        
        let db = Firestore.firestore()
        
        // Fetch all weights and let MonthData handle the filtering
        db.collection("weights")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching weights: \(error)")
                    isLoadingData = false
                    return
                }
                
                let weights = snapshot?.documents.compactMap { WeightEntry(from: $0) } ?? []
                
                DispatchQueue.main.async {
                    self.monthData = MonthData(month: self.selectedMonth, allWeights: weights)
                    self.isLoadingData = false
                }
            }
    }
}



struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView()
    }
} 
