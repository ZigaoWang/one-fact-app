import Foundation
import Combine

enum ChatRole: String, Codable {
    case user
    case assistant
    case system
}

struct Message: Identifiable, Codable {
    let id: UUID
    let role: ChatRole
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: ChatRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

enum ChatError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

@MainActor
class ChatService {
    private let baseURL: String
    
    init(baseURL: String? = nil) {
        // Always use the deployed API endpoint for reliability
        self.baseURL = baseURL ?? "https://one-fact-api.fly.dev/api/v1/chat"
    }
    
    func sendMessage(factId: String, messages: [Message]) async throws -> Message {
        guard let url = URL(string: baseURL) else {
            throw ChatError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Filter out system messages from the API request
        let apiMessages = messages.filter { $0.role != .system }
        
        // Prepare request body
        struct ChatRequest: Codable {
            let factId: String
            let messages: [MessageRequest]
            
            enum CodingKeys: String, CodingKey {
                case factId = "fact_id"
                case messages
            }
        }
        
        struct MessageRequest: Codable {
            let role: String
            let content: String
        }
        
        let requestMessages = apiMessages.map { MessageRequest(role: $0.role.rawValue, content: $0.content) }
        let chatRequest = ChatRequest(factId: factId, messages: requestMessages)
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(chatRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ChatError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to parse error message if available
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorResponse["error"] {
                    throw ChatError.apiError(errorMessage)
                }
                throw ChatError.apiError("Server returned status code \(httpResponse.statusCode)")
            }
            
            struct ChatResponse: Codable {
                let role: String
                let content: String
            }
            
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            
            return Message(
                role: chatResponse.role == "assistant" ? .assistant : .user,
                content: chatResponse.content
            )
        } catch let error as ChatError {
            throw error
        } catch {
            throw ChatError.networkError(error)
        }
    }
    
    // Use this method for local testing when API is not available
    func simulateResponse(to message: String) async -> Message {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Simple response patterns
        let lowercaseMessage = message.lowercased()
        let response: String
        
        if lowercaseMessage.contains("what") || lowercaseMessage.contains("how") || lowercaseMessage.contains("why") {
            if lowercaseMessage.contains("honey") {
                response = "Honey can last indefinitely without spoiling because it has a very low water content and high acidity. These properties make it impossible for most bacteria and microorganisms to survive. Ancient honey found in Egyptian tombs was still perfectly edible after thousands of years!"
            } else if lowercaseMessage.contains("sky") || lowercaseMessage.contains("blue") {
                response = "The sky appears blue because molecules in the air scatter blue light from the sun more than they scatter red light. This is called Rayleigh scattering. When we look at the sky, we're seeing this scattered blue light."
            } else if lowercaseMessage.contains("deep") || lowercaseMessage.contains("more") {
                response = "That's an interesting question! Would you like me to explore this topic in more depth? I can explain the scientific principles, historical context, or practical applications related to this fact."
            } else {
                response = "That's a great question! The answer involves several fascinating concepts. Would you like me to focus on the scientific explanation, historical background, or practical applications of this phenomenon?"
            }
        } else if lowercaseMessage.contains("thank") {
            response = "You're welcome! I'm happy to help you explore interesting facts. Is there anything else you'd like to know about this topic?"
        } else if lowercaseMessage.contains("hello") || lowercaseMessage.contains("hi") {
            response = "Hello! I'm your AI assistant for exploring today's fact. What would you like to know more about?"
        } else {
            response = "That's an interesting point! Would you like me to provide more context about this fact, explore related concepts, or discuss its practical implications in our daily lives?"
        }
        
        return Message(role: .assistant, content: response)
    }
}
