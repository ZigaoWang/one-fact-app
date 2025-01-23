import SwiftUI

struct FactCardView: View {
    let fact: Fact
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var isImageLoaded = false
    @State private var showShimmer = true
    @State private var isBookmarked = false
    
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
            // Category Header with Gradient and Shimmer
            HStack {
                Text(categoryIcon)
                    .font(.title)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(categoryColor.opacity(0.2))
                            .overlay(
                                Circle()
                                    .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                            )
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
                
                Button {
                    withAnimation(.spring()) {
                        isBookmarked.toggle()
                    }
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isBookmarked ? categoryColor : .gray)
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 8)
            
            // Image Placeholder with Shimmer Effect
            ZStack {
                Rectangle()
                    .fill(categoryColor.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: showShimmer ? 200 : -200)
                    )
                    .mask(
                        Rectangle()
                            .fill(categoryColor.opacity(0.1))
                            .frame(height: 200)
                    )
                
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
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    showShimmer = false
                }
            }
            
            // Fact Content with Dynamic Type
            Text(fact.content)
                .font(.body)
                .lineSpacing(8)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: categoryColor.opacity(0.1), radius: 5)
                )
                .padding(.horizontal)
            
            // Related Articles with Horizontal Scroll
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
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Footer with Source and Learn More
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
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        cardOffset = .zero
                        cardRotation = 0
                    }
                }
        )
    }
}
