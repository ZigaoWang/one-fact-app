import Foundation
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputMessage: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let chatService: ChatService
    private var currentFactId: String?
    private var currentFact: Fact?
    
    init(chatService: ChatService? = nil) {
        // Initialize the ChatService on the main actor
        self.chatService = chatService ?? ChatService()
    }
    
    func setCurrentFact(_ fact: Fact) {
        self.currentFactId = fact.id
        self.currentFact = fact
        
        // Reset conversation
        self.messages = []
        
        // Add initial system message with context about the fact
        addSystemMessage(for: fact)
    }
    
    private func addSystemMessage(for fact: Fact) {
        let keywords = fact.metadata.keywords?.joined(separator: ", ") ?? fact.category
        let systemPrompt = """
        You are an educational AI assistant in the "One Fact" app. Today's fact is about: \(fact.content)
        
        Related keywords: \(keywords)
        Category: \(fact.category)
        
        Your goal is to help the user explore this fact in depth. You can:
        1. Explain scientific principles related to the fact
        2. Provide historical context
        3. Suggest practical applications or implications
        4. Connect it to other knowledge domains
        
        Keep responses informative but conversational. If you don't know something, admit it rather than making up information.
        """
        
        // This message won't be shown to users but informs the AI about context
        let systemMessage = Message(role: .system, content: systemPrompt)
        messages.append(systemMessage)
        
        // Don't add a welcome message - we'll show a welcome UI instead
    }
    
    func sendMessage() async {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = Message(role: .user, content: inputMessage)
        messages.append(userMessage)
        
        // Clear input field
        inputMessage = ""
        
        // Show loading state
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            // Use the real API if we have a factId
            if let factId = currentFactId {
                // Get only messages that should be sent to the API (not system messages)
                let response = try await chatService.sendMessage(factId: factId, messages: messages)
                messages.append(response)
            } else {
                // Fallback to simulation if we don't have a factId for some reason
                let response = await chatService.simulateResponse(to: userMessage.content)
                messages.append(response)
            }
        } catch let error as ChatError {
            errorMessage = error.errorMessage
            showError = true
            print("Chat Error: \(error.localizedDescription)")
        } catch {
            errorMessage = "An unexpected error occurred"
            showError = true
            print("Unexpected error: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}

extension ChatError {
    var errorMessage: String {
        switch self {
        case .networkError:
            return "Network error occurred. Please check your connection and try again."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .apiError(let message):
            return "Server error: \(message)"
        }
    }
}
