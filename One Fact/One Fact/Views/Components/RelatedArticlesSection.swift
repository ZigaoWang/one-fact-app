import SwiftUI

struct RelatedArticlesSection: View {
    let articles: [RelatedArticle]
    let category: Category
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Articles")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(articles) { article in
                        RelatedArticleCard(article: article, color: category.color)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

#Preview {
    RelatedArticlesSection(
        articles: [
            RelatedArticle(
                id: 1,
                title: "Sample Article",
                url: "https://example.com",
                source: "Example Source",
                snippet: "Sample snippet"
            )
        ],
        category: Category(name: "Science", icon: "🔬", color: .blue)
    )
}
