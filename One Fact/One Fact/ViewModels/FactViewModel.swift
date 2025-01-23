import SwiftUI
import Foundation

@MainActor
class FactViewModel: ObservableObject {
    @Published var currentFact: Fact?
    @Published var relatedArticles: [RelatedArticle] = []
    @Published var chatMessages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSeenFactToday = false
    
    private let factService: FactService
    private let defaults = UserDefaults.standard
    
    init() {
        self.factService = FactService()
        checkDailyFactStatus()
    }
    
    public func checkDailyFactStatus() {
        let lastSeenDate = defaults.object(forKey: "LastSeenFactDate") as? Date ?? Date.distantPast
        hasSeenFactToday = Calendar.current.isDate(lastSeenDate, inSameDayAs: Date())
        
        if !hasSeenFactToday {
            Task {
                await fetchDailyFact()
            }
        }
    }
    
    func fetchDailyFact() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fact = try await factService.fetchDailyFact()
            currentFact = fact
            defaults.set(Date(), forKey: "LastSeenFactDate")
            await fetchRelatedArticles()
        } catch {
            errorMessage = "Failed to fetch daily fact: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func fetchRelatedArticles() async {
        guard let fact = currentFact else { return }
        
        do {
            relatedArticles = try await factService.fetchRelatedArticles(for: fact.id)
        } catch {
            errorMessage = "Failed to fetch related articles"
        }
    }
    
    func sendChatMessage(_ message: String) async {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: message, isUser: true)
        chatMessages.append(userMessage)
        
        do {
            let response = try await factService.sendChatMessage(message)
            let aiMessage = ChatMessage(content: response, isUser: false)
            chatMessages.append(aiMessage)
        } catch {
            errorMessage = "Failed to get AI response"
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
