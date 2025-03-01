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
    @Published var streamingMessage: String = ""
    @Published var isStreaming = false
    
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
        isStreaming = true
        streamingMessage = ""
        errorMessage = nil
        showError = false
        
        // Use the real API if we have a factId
        if let factId = currentFactId {
            // Try streaming first
            streamChat(factId: factId, userMessage: userMessage)
        } else {
            // Fallback to simulation if we don't have a factId for some reason
            do {
                let response = await chatService.simulateResponse(to: userMessage.content)
                messages.append(response)
            } catch {
                errorMessage = "An unexpected error occurred"
                showError = true
                print("Unexpected error: \(error.localizedDescription)")
            }
            isLoading = false
            isStreaming = false
        }
    }
    
    private func streamChat(factId: String, userMessage: Message) {
        // Start streaming response
        chatService.streamMessage(factId: factId, messages: messages) { [weak self] chunk in
            guard let self = self else { return }
            // Append each chunk to the streaming message on the main thread
            DispatchQueue.main.async {
                self.streamingMessage += chunk
            }
        } onComplete: { [weak self] result in
            guard let self = self else { return }
            
            // Handle completion
            switch result {
            case .success(let message):
                // Add the complete message to the conversation
                self.messages.append(message)
            case .failure(let error):
                if let chatError = error as? ChatError {
                    self.errorMessage = chatError.errorMessage
                } else {
                    self.errorMessage = error.localizedDescription
                }
                self.showError = true
                print("Chat Error: \(error.localizedDescription)")
                
                // Fallback to non-streaming API if streaming fails
                Task {
                    do {
                        let response = try await self.chatService.sendMessage(factId: factId, messages: self.messages)
                        self.messages.append(response)
                    } catch let error {
                        self.errorMessage = "Failed to get response: \(error.localizedDescription)"
                        self.showError = true
                    }
                }
            }
            
            // Reset streaming state after a small delay to ensure smooth transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isLoading = false
                self.isStreaming = false
                self.streamingMessage = ""
            }
        }
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
