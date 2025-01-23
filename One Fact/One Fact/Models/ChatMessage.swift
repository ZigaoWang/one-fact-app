import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date = Date()
}

struct ChatResponse: Codable {
    let message: String
    let context: String?
}
