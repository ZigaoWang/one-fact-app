import SwiftUI

struct FactCardView: View {
    let fact: Fact
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    
    var categoryIcon: String {
        switch fact.category {
        case "Science": return "🧬"
        case "History": return "📜"
        case "Technology": return "💻"
        case "Space": return "🌌"
        case "Nature": return "🌿"
        case "Art": return "🎨"
        case "Literature": return "📚"
        default: return "💡"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Header
            HStack {
                Text(categoryIcon)
                    .font(.title2)
                Text(fact.category)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(fact.displayDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Fact Content
            Text(fact.content)
                .font(.body)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .padding(.horizontal)
            
            // Source Footer
            HStack {
                Text("Source: \(fact.source)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let url = fact.url {
                    Link("Learn More", destination: URL(string: url)!)
                        .font(.caption)
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .offset(cardOffset)
        .rotationEffect(.degrees(cardRotation))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    cardOffset = gesture.translation
                    cardRotation = Double(gesture.translation.width / 20)
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
                        cardOffset = .zero
                        cardRotation = 0
                    }
                }
        )
    }
}
