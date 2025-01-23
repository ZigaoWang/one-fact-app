import SwiftUI
import Foundation

@MainActor
class FactViewModel: ObservableObject {
    @Published var currentFact: Fact?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSeenFactToday = false
    @Published var todaysCategory: Category?
    @Published var seenCategories: Set<String> = []
    
    private let factService: FactService
    private let defaults = UserDefaults.standard
    
    let categories: [Category] = [
        Category(name: "Science", icon: "🔬", color: .blue),
        Category(name: "History", icon: "📜", color: .brown),
        Category(name: "Technology", icon: "💻", color: .purple),
        Category(name: "Nature", icon: "🌿", color: .green),
        Category(name: "Space", icon: "🚀", color: .indigo),
        Category(name: "Art", icon: "🎨", color: .pink)
    ]
    
    init() {
        self.factService = FactService()
        loadSeenCategories()
        checkDailyFactStatus()
    }
    
    private func loadSeenCategories() {
        if let savedDate = defaults.object(forKey: "LastSeenFactsDate") as? Date,
           Calendar.current.isDate(savedDate, inSameDayAs: Date()) {
            seenCategories = Set(defaults.stringArray(forKey: "TodaysSeenCategories") ?? [])
        } else {
            // Reset seen categories for new day
            seenCategories.removeAll()
            defaults.set(Date(), forKey: "LastSeenFactsDate")
            defaults.set([], forKey: "TodaysSeenCategories")
        }
    }
    
    func checkDailyFactStatus() {
        loadSeenCategories()
        
        if let categoryName = defaults.string(forKey: "LastSeenCategoryName"),
           seenCategories.contains(categoryName) {
            todaysCategory = categories.first { $0.name == categoryName }
            hasSeenFactToday = true
        } else {
            todaysCategory = nil
            hasSeenFactToday = false
        }
    }
    
    func fetchFactByCategory(_ category: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let fact = try await factService.fetchFactByCategory(category)
            currentFact = fact
            
            // Update seen categories
            seenCategories.insert(category)
            defaults.set(Array(seenCategories), forKey: "TodaysSeenCategories")
            defaults.set(category, forKey: "LastSeenCategoryName")
            
            hasSeenFactToday = true
            todaysCategory = categories.first { $0.name == category }
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch fact: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func canViewCategory(_ category: Category) -> Bool {
        // Can view if we haven't seen any facts today
        if seenCategories.isEmpty {
            return true
        }
        
        // Can only view categories we've already seen today
        return seenCategories.contains(category.name)
    }
    
    // Call this when app becomes active
    func refreshDailyStatus() {
        loadSeenCategories()
        checkDailyFactStatus()
        
        // Clear cache if it's a new day
        if seenCategories.isEmpty {
            factService.clearCache()
        }
    }
}

struct Category: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
}

extension Color {
    static let categoryColors: [Color] = [.blue, .purple, .green, .orange, .pink, .indigo, .brown]
}
