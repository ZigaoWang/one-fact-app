import SwiftUI
import Foundation

@MainActor
class FactViewModel: ObservableObject {
    @Published var currentFact: Fact?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSeenFactToday = false
    
    private let factService = FactService()
    private let userDefaults = UserDefaults.standard
    
    let categories = [
        Category(name: "Science", icon: "🧬", color: .blue),
        Category(name: "History", icon: "📜", color: .brown),
        Category(name: "Technology", icon: "💻", color: .purple),
        Category(name: "Space", icon: "🌌", color: .indigo),
        Category(name: "Nature", icon: "🌿", color: .green),
        Category(name: "Art", icon: "🎨", color: .pink),
        Category(name: "Literature", icon: "📚", color: .orange)
    ]
    
    init() {
        checkDailyFactStatus()
    }
    
    func checkDailyFactStatus() {
        let lastSeenDate = userDefaults.object(forKey: "LastSeenFactDate") as? Date
        let today = Calendar.current.startOfDay(for: Date())
        hasSeenFactToday = lastSeenDate != nil && Calendar.current.isDate(lastSeenDate!, inSameDayAs: today)
    }
    
    func fetchFactByCategory(_ category: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let fact = try await factService.fetchFactByCategory(category)
            currentFact = fact
            
            // Mark as seen for today
            userDefaults.set(Date(), forKey: "LastSeenFactDate")
            hasSeenFactToday = true
        } catch {
            errorMessage = "Cannot connect to server"
        }
        
        isLoading = false
    }
    
    func clearCurrentFact() {
        currentFact = nil
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
