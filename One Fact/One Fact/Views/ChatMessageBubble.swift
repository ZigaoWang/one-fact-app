import SwiftUI

struct MessageBubble: View {
    let message: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(message)
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
        MessageBubble(message: "Hello! How does honey never spoil?", isUser: true)
        MessageBubble(message: "That's a great question! Honey's unique chemical properties...", isUser: false)
    }
    .padding()
}
