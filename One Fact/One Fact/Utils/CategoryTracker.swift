import Foundation

class CategoryTracker {
    private static let lastOpenedCategoryKey = "lastOpenedCategory"
    private static let lastOpenedDateKey = "lastOpenedDate"
    private static let defaults = UserDefaults.standard
    
    static func canOpenCategory(_ category: String) -> Bool {
        // Always allow if no category has been opened yet
        guard let lastOpenedCategory = getLastOpenedCategory(),
              let lastOpenedDate = getLastOpenedDate() else {
            return true
        }
        
        // If it's a new day, allow any category
        if !Calendar.current.isDate(lastOpenedDate, inSameDayAs: Date()) {
            return true
        }
        
        // If it's the same day, only allow the same category
        return category == lastOpenedCategory
    }
    
    static func trackCategoryOpened(_ category: String) {
        defaults.set(category, forKey: lastOpenedCategoryKey)
        defaults.set(Date(), forKey: lastOpenedDateKey)
    }
    
    static func getLastOpenedCategory() -> String? {
        return defaults.string(forKey: lastOpenedCategoryKey)
    }
    
    static func getLastOpenedDate() -> Date? {
        return defaults.object(forKey: lastOpenedDateKey) as? Date
    }
    
    #if DEBUG
    static func resetForTesting() {
        defaults.removeObject(forKey: lastOpenedCategoryKey)
        defaults.removeObject(forKey: lastOpenedDateKey)
    }
    #endif
}
