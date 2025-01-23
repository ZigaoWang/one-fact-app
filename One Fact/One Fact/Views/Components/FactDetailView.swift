import SwiftUI

struct FactDetailView: View {
    let fact: Fact
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category and Date
                    HStack {
                        Text(fact.category)
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text(fact.displayDate.formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(.secondary)
                    }
                    
                    // Fact Content
                    Text(fact.content)
                        .font(.body)
                        .lineSpacing(6)
                    
                    // Source Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source")
                            .font(.headline)
                        
                        HStack {
                            Text(fact.source)
                                .foregroundColor(.secondary)
                            Spacer()
                            if let url = fact.url {
                                Link("Learn More", destination: URL(string: url)!)
                            }
                        }
                    }
                    
                    // Related Articles Section
                    if !fact.relatedArticles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Related Articles")
                                .font(.headline)
                                .padding(.top)
                            
                            ForEach(fact.relatedArticles) { article in
                                Link(destination: URL(string: article.url)!) {
                                    HStack(spacing: 16) {
                                        if let imageUrl = article.imageUrl {
                                            AsyncImage(url: URL(string: imageUrl)) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Color.gray.opacity(0.3)
                                            }
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(article.title)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                                .lineLimit(2)
                                            
                                            Text(article.source)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Today's Fact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
