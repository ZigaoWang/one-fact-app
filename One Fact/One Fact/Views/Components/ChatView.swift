import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: FactViewModel
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 16) {
                        // Initial fact context
                        if let fact = viewModel.currentFact {
                            ChatMessageBubble(content: fact.content, isUser: false)
                        }
                        
                        // Chat messages
                        ForEach(viewModel.chatMessages) { message in
                            ChatMessageBubble(content: message.content, isUser: message.isUser)
                        }
                    }
                    .padding()
                }
                
                // Message input
                HStack {
                    TextField("Ask a question...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isFocused)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(radius: 1)
            }
            .navigationTitle("Chat with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let message = messageText
        messageText = ""
        
        Task {
            await viewModel.sendChatMessage(message)
        }
    }
}
