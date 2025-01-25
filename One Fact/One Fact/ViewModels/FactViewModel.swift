import SwiftUI
import Foundation

@MainActor
class FactViewModel: ObservableObject {
    @Published var currentFact: Fact?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var hasSeenFactToday = false
    @Published var todaysCategory: Category?
    
    private let factService: FactService
    
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
        checkDailyFactStatus()
    }
    
    func checkDailyFactStatus() {
        if let lastCategory = CategoryTracker.getLastOpenedCategory(),
           let lastDate = CategoryTracker.getLastOpenedDate(),
           Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
            todaysCategory = categories.first { $0.name == lastCategory }
            hasSeenFactToday = true
        } else {
            todaysCategory = nil
            hasSeenFactToday = false
        }
    }
    
    func fetchFactByCategory(_ category: String) async {
        guard CategoryTracker.canOpenCategory(category) else {
            errorMessage = "You can only view one category per day. Today you've already viewed \(CategoryTracker.getLastOpenedCategory() ?? "another category")."
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let facts = try await factService.searchFacts(query: "", category: category)
            guard let fact = facts.first else {
                throw APIError.noData
            }
            
            currentFact = fact
            CategoryTracker.trackCategoryOpened(category)
            
            hasSeenFactToday = true
            todaysCategory = categories.first { $0.name == category }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            showError = true
            print("API Error: \(error.localizedDescription)")
        } catch {
            errorMessage = "An unexpected error occurred"
            showError = true
            print("Unexpected error: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func canViewCategory(_ category: Category) -> Bool {
        return CategoryTracker.canOpenCategory(category.name)
    }
    
    #if DEBUG
    func resetForTesting() {
        CategoryTracker.resetForTesting()
        checkDailyFactStatus()
    }
    #endif
}

extension Color {
    static let categoryColors: [Color] = [.blue, .purple, .green, .orange, .pink, .indigo, .brown]
}
