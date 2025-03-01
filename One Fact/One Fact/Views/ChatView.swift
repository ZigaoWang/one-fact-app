import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    let fact: Fact
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                chatHeader
                
                // Messages
                chatMessages
                
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
                Text("AI Knowledge Explorer")
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
                                .background(Color.blue.gradient)
                                .clipShape(Circle())
                            
                            Text("How can I help you learn about today's fact?")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Text("Ask me anything about \(fact.content.prefix(50))...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .lineLimit(2)
                            
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
                    
                    // Loading indicator
                    if viewModel.isLoading {
                        HStack(alignment: .top, spacing: 8) {
                            // AI avatar
                            Image(systemName: "brain")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Color.blue.gradient)
                                .clipShape(Circle())
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 8, height: 8)
                                    .opacity(1.0)
                                    .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.0), value: viewModel.isLoading)
                                
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 8, height: 8)
                                    .opacity(0.5)
                                    .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.2), value: viewModel.isLoading)
                                
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 8, height: 8)
                                    .opacity(0.2)
                                    .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.4), value: viewModel.isLoading)
                            }
                            .padding(.vertical, 12)
                            
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Input area at the bottom
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Text field with placeholder
                TextField("Message", text: $viewModel.inputMessage)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if !viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
                        .background(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .clipShape(Circle())
                }
                .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .disabled(viewModel.isLoading)
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
