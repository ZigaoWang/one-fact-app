import SwiftUI

struct RelatedArticleCard: View {
    let article: RelatedArticle
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image Placeholder
            ZStack {
                Rectangle()
                    .fill(color.opacity(0.1))
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Image(systemName: "newspaper")
                    .font(.system(size: 30))
                    .foregroundColor(color.opacity(0.3))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(article.source)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 200)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}
