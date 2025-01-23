import SwiftUI

struct ChatMessageBubble: View {
    let content: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(content)
                .padding()
                .background(isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            if !isUser { Spacer() }
        }
    }
}

#Preview {
    VStack {
        ChatMessageBubble(content: "Hello! How does honey never spoil?", isUser: true)
        ChatMessageBubble(content: "That's a great question! Honey's unique chemical properties...", isUser: false)
    }
    .padding()
}
