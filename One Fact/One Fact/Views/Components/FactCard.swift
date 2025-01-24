import SwiftUI

struct FactCard: View {
    let fact: Fact
    let category: Category
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category and Date
            HStack {
                Text(category.icon)
                    .font(.title2)
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(category.color)
                Spacer()
                Text(fact.displayDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Content
            Text(fact.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
            
            // Tags
            if !fact.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(fact.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .foregroundColor(category.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(category.color.opacity(0.1))
                                )
                        }
                    }
                }
            }
            
            // Source
            if let url = fact.url {
                Link(destination: URL(string: url)!) {
                    HStack {
                        Text("Source: \(fact.source)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(
                    color: category.color.opacity(0.1),
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
    }
}
