struct YearPerformanceView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedYear: Int
    @State private var yearData: YearData?
    @State private var isLoading = false
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg
    
    init() {
        let calendar = Calendar.current
        _selectedYear = State(initialValue: calendar.component(.year, from: Date()))
    }
    
    private var yearSummary: (cutWeeks: Int, gainWeeks: Int) {
        guard let yearData = yearData else { return (0, 0) }
        let cutWeeks = yearData.weeklyDifferences.filter { $0.difference < 0 }.count
        let gainWeeks = yearData.weeklyDifferences.filter { $0.difference > 0 }.count
        return (cutWeeks, gainWeeks)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Year Picker
                Picker("Year", selection: $selectedYear) {
                    ForEach((2020...Calendar.current.component(.year, from: Date())), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if isLoading {
                    ProgressView("Loading data...")
                        .frame(maxHeight: .infinity)
                } else if let yearData = yearData, yearData.hasData {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Year Summary
                            VStack(spacing: 8) {
                                Text("This year you have been on")
                                    .font(.headline)
                                
                                HStack(spacing: 20) {
                                    VStack {
                                        Text("Cut for")
                                            .foregroundColor(.green)
                                        Text("\(yearSummary.cutWeeks)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                        Text("weeks")
                                            .foregroundColor(.green)
                                    }
                                    
                                    VStack {
                                        Text("Gain for")
                                            .foregroundColor(.red)
                                        Text("\(yearSummary.gainWeeks)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.red)
                                        Text("weeks")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            // Weekly Difference Chart
                            Chart {
                                ForEach(yearData.weeklyDifferences, id: \.weekLabel) { diff in
                                    BarMark(
                                        x: .value("Week", diff.weekLabel),
                                        y: .value("Difference", weightUnit.convert(diff.difference, from: .kg))
                                    )
                                    .foregroundStyle(diff.difference >= 0 ? Color.red : Color.green)
                                }
                                
                                RuleMark(y: .value("Zero", 0))
                                    .foregroundStyle(Color.gray.opacity(0.5))
                            }
                            .frame(height: 300)
                            .padding()
                            .chartXAxis {
                                AxisMarks(preset: .aligned) { value in
                                    AxisValueLabel {
                                        if let label = value.as(String.self) {
                                            Text(label)
                                                .font(.caption)
                                                .rotationEffect(.degrees(-45))
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No data available for \(selectedYear)")
                            .font(.headline)
                        Text("Try selecting a different year")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .navigationTitle("Year Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedYear) { _ in
            fetchYearData()
        }
        .onAppear {
            fetchYearData()
        }
    }
    
    private func fetchYearData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        yearData = nil  // Clear existing data
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = selectedYear
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let startOfYear = calendar.date(from: components),
              let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) else {
            isLoading = false
            return
        }
        
        print("Fetching data for year \(selectedYear): \(startOfYear) to \(endOfYear)")
        
        let db = Firestore.firestore()
        db.collection("weights")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfYear))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endOfYear))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching year data: \(error)")
                    DispatchQueue.main.async {
                        isLoading = false
                    }
                    return
                }
                
                let weights = snapshot?.documents.compactMap { WeightEntry(from: $0) } ?? []
                print("Found \(weights.count) weights for year \(selectedYear)")
                
                DispatchQueue.main.async {
                    self.yearData = YearData(year: selectedYear, allWeights: weights)
                    self.isLoading = false
                }
            }
    }
} 