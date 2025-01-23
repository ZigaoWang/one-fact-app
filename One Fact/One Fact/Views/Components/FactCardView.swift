import SwiftUI

struct FactCardView: View {
    let fact: Fact
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var isImageLoaded = false
    
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
    
    var categoryColor: Color {
        switch fact.category {
        case "Science": return .blue
        case "History": return .brown
        case "Technology": return .purple
        case "Space": return .indigo
        case "Nature": return .green
        case "Art": return .pink
        case "Literature": return .orange
        default: return .blue
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Header with Gradient
            HStack {
                Text(categoryIcon)
                    .font(.title)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(categoryColor.opacity(0.2))
                    )
                
                VStack(alignment: .leading) {
                    Text(fact.category)
                        .font(.headline)
                        .foregroundColor(categoryColor)
                    Text(fact.displayDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 8)
            
            // Image Placeholder
            ZStack {
                Rectangle()
                    .fill(categoryColor.opacity(0.1))
                    .frame(height: 200)
                
                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(categoryColor.opacity(0.3))
                    Text("Fact Image")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            
            // Fact Content
            Text(fact.content)
                .font(.body)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Related Articles Preview
            if !fact.relatedArticles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Related Articles")
                        .font(.headline)
                        .foregroundColor(categoryColor)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(fact.relatedArticles) { article in
                                RelatedArticleCard(article: article, color: categoryColor)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Divider()
                .padding(.horizontal)
            
            // Footer with Source
            HStack {
                Text("Source: \(fact.source)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let url = fact.url {
                    Link("Learn More", destination: URL(string: url)!)
                        .font(.caption.bold())
                        .foregroundColor(categoryColor)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
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
