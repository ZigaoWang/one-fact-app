import SwiftUI

struct TypingIndicator: View {
    @State private var showFirstDot = false
    @State private var showSecondDot = false
    @State private var showThirdDot = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
                .scaleEffect(showFirstDot ? 1.0 : 0.5)
                .opacity(showFirstDot ? 1.0 : 0.5)
            
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
                .scaleEffect(showSecondDot ? 1.0 : 0.5)
                .opacity(showSecondDot ? 1.0 : 0.5)
            
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
                .scaleEffect(showThirdDot ? 1.0 : 0.5)
                .opacity(showThirdDot ? 1.0 : 0.5)
        }
        .padding(.vertical, 12)
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        // Animate first dot
        withAnimation(Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            showFirstDot = true
        }
        
        // Animate second dot with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                showSecondDot = true
            }
        }
        
        // Animate third dot with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                showThirdDot = true
            }
        }
    }
}

#Preview {
    TypingIndicator()
        .padding()
        .background(Color.white)
        .previewLayout(.sizeThatFits)
}
