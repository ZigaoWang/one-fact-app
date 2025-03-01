import SwiftUI

struct MessageBubble: View {
    let message: String
    let isUser: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !isUser {
                // AI avatar
                Image(systemName: "brain")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.blue.gradient)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Sender label
                Text(isUser ? "You" : "AI Assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                // Message content
                Text(message)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(isUser ? Color(.systemGray6) : .white)
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            
            if isUser {
                // User avatar
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.green.gradient)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

#Preview {
    VStack {
        MessageBubble(message: "Hello! How does honey never spoil?", isUser: true)
        MessageBubble(message: "That's a great question! Honey's unique chemical properties...", isUser: false)
    }
    .padding()
}
