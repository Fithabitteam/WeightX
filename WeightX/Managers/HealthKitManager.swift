import HealthKit

enum HealthKitError: Error {
    case notAvailable
    case unauthorized
    case syncFailed(Error)
}

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws -> Bool {
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        
        let typesToRead: Set<HKObjectType> = [weightType]
        let typesToWrite: Set<HKSampleType> = [weightType]
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: success)
            }
        }
    }
    
    func saveWeight(_ weight: Double, date: Date) async throws {
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weight)
        let sample = HKQuantitySample(type: weightType,
                                    quantity: weightQuantity,
                                    start: date,
                                    end: date)
        
        try await healthStore.save(sample)
    }
    
    func readWeights(from startDate: Date, to endDate: Date) async throws -> [(date: Date, weight: Double)] {
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                   end: endDate,
                                                   options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: weightType,
                                    predicate: predicate,
                                    limit: HKObjectQueryNoLimit,
                                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let weights = (samples as? [HKQuantitySample])?.map { sample in
                    (date: sample.startDate,
                     weight: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)))
                } ?? []
                
                continuation.resume(returning: weights)
            }
            
            healthStore.execute(query)
        }
    }
    
    func hasHealthKitAuthorization() async -> Bool {
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let status = healthStore.authorizationStatus(for: weightType)
        return status == .sharingAuthorized
    }
    
    func syncWeights(from weights: [WeightEntry]) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        // Get existing weights from HealthKit for comparison
        let calendar = Calendar.current
        let oldestWeightDate = weights.map { $0.date }.min() ?? Date.distantPast
        let latestWeightDate = weights.map { $0.date }.max() ?? Date()
        
        let existingWeights = try await fetchHealthKitWeights(
            from: oldestWeightDate,
            to: latestWeightDate
        )
        
        // Create a dictionary of existing weights by date for quick lookup
        var existingWeightsByDay: [Date: Double] = [:]
        for (date, weight) in existingWeights {
            let dayStart = calendar.startOfDay(for: date)
            existingWeightsByDay[dayStart] = weight
        }
        
        // Only sync weights that are different or don't exist
        for weight in weights {
            let dayStart = calendar.startOfDay(for: weight.date)
            let existingWeight = existingWeightsByDay[dayStart]
            
            // Only save if weight doesn't exist or is different
            if existingWeight == nil || abs(existingWeight! - weight.weight) > 0.001 {
                try await saveWeight(weight.weight, date: weight.date)
                print("Synced weight \(weight.weight) for date \(weight.date)")
            } else {
                print("Skipped syncing weight \(weight.weight) for date \(weight.date) - no change")
            }
        }
    }
    
    private func fetchHealthKitWeights(from startDate: Date, to endDate: Date) async throws -> [(Date, Double)] {
        let weightType = HKQuantityType(.bodyMass)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let weights = samples?.compactMap { sample -> (Date, Double)? in
                    guard let sample = sample as? HKQuantitySample else { return nil }
                    let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    return (sample.startDate, weightInKg)
                } ?? []
                
                continuation.resume(returning: weights)
            }
            
            healthStore.execute(query)
        }
    }
} 