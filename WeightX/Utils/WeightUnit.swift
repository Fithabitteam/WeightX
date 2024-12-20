// Update conversion to preserve decimal places
func convert(_ value: Double, from unit: WeightUnit) -> Double {
    switch (self, unit) {
    case (.kg, .kg), (.lbs, .lbs):
        return value
    case (.kg, .lbs):
        return value * 0.45359237
    case (.lbs, .kg):
        return value * 2.20462262
    }
} 