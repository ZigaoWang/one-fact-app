import SwiftUI
import Foundation

@MainActor
class FactViewModel: ObservableObject {
    @Published var currentFact: Fact?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSeenFactToday = false
    @Published var todaysCategory: Category?
    
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
        checkDailyFactStatus()
    }
    
    func checkDailyFactStatus() {
        let lastSeenDate = defaults.object(forKey: "LastSeenFactDate") as? Date ?? Date.distantPast
        let categoryName = defaults.string(forKey: "TodaysCategoryName")
        
        hasSeenFactToday = Calendar.current.isDate(lastSeenDate, inSameDayAs: Date())
        
        if hasSeenFactToday, let categoryName = categoryName {
            todaysCategory = categories.first { $0.name == categoryName }
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
            defaults.set(Date(), forKey: "LastSeenFactDate")
            defaults.set(category, forKey: "TodaysCategoryName")
            hasSeenFactToday = true
            todaysCategory = categories.first { $0.name == category }
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch fact: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func canViewCategory(_ category: Category) -> Bool {
        if !hasSeenFactToday {
            return true
        }
        return todaysCategory?.name == category.name
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
