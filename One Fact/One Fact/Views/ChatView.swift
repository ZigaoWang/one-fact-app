import SwiftUI
import Combine

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    let fact: Fact
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            Color(.systemGray6)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                chatHeader
                
                // Messages
                chatMessages
                    .dismissKeyboardOnTap()
                
                // Input area
                inputArea
            }
        }
        .onAppear {
            viewModel.setCurrentFact(fact)
        }
        .alert(isPresented: $viewModel.showError, content: {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        })
    }
    
    // Chat header
    private var chatHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Fact Explorer")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
        }
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // Chat messages area
    private var chatMessages: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Welcome message if no messages yet
                    if viewModel.messages.filter({ $0.role != .system }).isEmpty && !viewModel.isLoading {
                        VStack(spacing: 16) {
                            Spacer().frame(height: 40)
                            
                            Image(systemName: "brain")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .padding(20)
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), 
                                                  startPoint: .topLeading, 
                                                  endPoint: .bottomTrailing)
                                )
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            Text("How can I help you learn about today's fact?")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Text("Ask me anything about \(fact.content.prefix(50))...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .lineLimit(2)
                            
                            // Example questions
                            VStack(spacing: 10) {
                                Text("Try asking:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 16)
                                
                                ForEach(["Tell me more about this fact", "Why is this important?", "How does this relate to everyday life?"], id: \.self) { question in
                                    Button(action: {
                                        viewModel.inputMessage = question
                                        Task {
                                            await viewModel.sendMessage()
                                        }
                                    }) {
                                        Text(question)
                                            .font(.caption)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(16)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 30)
                    }
                    
                    // Message bubbles
                    ForEach(viewModel.messages.filter { $0.role != .system }) { message in
                        MessageBubble(
                            message: message.content,
                            isUser: message.role == .user
                        )
                        .id(message.id)
                    }
                    
                    // Streaming message bubble
                    if viewModel.isStreaming && !viewModel.streamingMessage.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            // AI avatar
                            Image(systemName: "brain")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.blue.gradient)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                // Sender label
                                Text("AI Assistant")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                                
                                // Streaming content
                                Text(viewModel.streamingMessage)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [Color.white, Color.white.opacity(0.9)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .animation(.easeInOut(duration: 0.1), value: viewModel.streamingMessage)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .id("streaming") // ID for scrolling
                    }
                    // Loading indicator (only show if no streaming message yet)
                    else if viewModel.isLoading {
                        HStack(alignment: .top, spacing: 8) {
                            // AI avatar
                            Image(systemName: "brain")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.blue.gradient)
                                .clipShape(Circle())
                            
                            TypingIndicator()
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                    
                    // Spacer at the bottom to ensure content can scroll up when keyboard appears
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal)
            }
            .background(Color.white)
            .onChange(of: viewModel.messages.count) { _ in
                if let lastMessage = viewModel.messages.last(where: { $0.role != .system }) {
                    withAnimation {
                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.streamingMessage) { _ in
                // Auto-scroll when streaming message updates
                if !viewModel.streamingMessage.isEmpty {
                    // Use a slight delay to ensure UI has updated before scrolling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation {
                            scrollView.scrollTo("streaming", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Input area at the bottom
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Text field with placeholder
                TextField("Message", text: $viewModel.inputMessage, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .disabled(viewModel.isLoading)
                    .onSubmit {
                        if !viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading {
                            Task {
                                await viewModel.sendMessage()
                            }
                        }
                    }
                
                // Send button
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .padding(2)
                        .background(
                            Group {
                                if viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading {
                                    Color.gray
                                } else {
                                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                }
                            }
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: -1)
            // Individual components are already disabled when loading
        }
    }
}

struct ChatViewPreview: PreviewProvider {
    static var previews: some View {
        let fact = Fact(
            id: "1", 
            content: "The backend API is properly integrated with OpenAI to provide AI-powered responses.", 
            category: "Technology", 
            source: "One Fact App", 
            tags: ["ai", "openai", "backend"], 
            verified: true, 
            createdAt: Date(), 
            updatedAt: Date(), 
            relatedURLs: ["https://openai.com"], 
            metadata: FactMetadata(
                language: "en", 
                difficulty: "medium", 
                references: [], 
                keywords: ["ai", "integration", "backend"], 
                popularity: 5, 
                lastServed: Date(), 
                serveCount: 1
            )
        )
        
        return ChatView(fact: fact)
    }
}
