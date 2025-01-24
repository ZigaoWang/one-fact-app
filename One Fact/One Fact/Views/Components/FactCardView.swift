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
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: fact.displayDate)
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
                    Text(formattedDate)
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
                    .clipped()
                
                if isImageLoaded {
                    // Placeholder for future image implementation
                    Color.clear
                        .frame(height: 200)
                }
            }
            
            // Fact Content
            VStack(alignment: .leading, spacing: 12) {
                Text(fact.content)
                    .font(.body)
                    .lineSpacing(4)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(fact.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(categoryColor.opacity(0.1))
                                .foregroundColor(categoryColor)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Source
                HStack {
                    Text("Source: \(fact.source)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding(.horizontal)
        .onAppear {
            // Animate shimmer effect
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                showShimmer.toggle()
            }
        }
    }
}
