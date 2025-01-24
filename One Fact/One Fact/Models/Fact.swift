import Foundation

struct RelatedArticle: Codable, Identifiable {
    let id: Int
    let title: String
    let url: String
    let source: String
    let snippet: String
}

struct Fact: Codable, Identifiable {
    let id: String
    let content: String
    let category: String
    let source: String
    let tags: [String]
    let verified: Bool
    let createdAt: Date
    let updatedAt: Date
    let relatedURLs: [String]
    let metadata: FactMetadata
    
    var displayDate: Date {
        // Use createdAt for display purposes
        createdAt
    }
    
    var relatedArticles: [RelatedArticle] {
        // Convert relatedURLs to RelatedArticle objects
        return relatedURLs.enumerated().map { index, url in
            let keyword = (metadata.keywords?.first ?? category)
            let snippet = "Learn more about \(keyword) from \(source)"
            return RelatedArticle(
                id: index,
                title: "Related Article \(index + 1)",
                url: url,
                source: source,
                snippet: snippet
            )
        }
    }
    
    var url: String? {
        // Return the first related URL if available
        relatedURLs.first
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case category
        case source
        case tags
        case verified
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case relatedURLs = "related_urls"
        case metadata
    }
}

struct FactMetadata: Codable {
    let language: String?
    let difficulty: String?
    let references: [String]?
    let keywords: [String]?
    let popularity: Int
    let lastServed: Date
    let serveCount: Int
    
    enum CodingKeys: String, CodingKey {
        case language
        case difficulty
        case references
        case keywords
        case popularity
        case lastServed = "last_served"
        case serveCount = "serve_count"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decodeIfPresent(String.self, forKey: .language) ?? ""
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty) ?? ""
        references = try container.decodeIfPresent([String].self, forKey: .references) ?? []
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords) ?? []
        popularity = try container.decodeIfPresent(Int.self, forKey: .popularity) ?? 0
        lastServed = try container.decode(Date.self, forKey: .lastServed)
        serveCount = try container.decodeIfPresent(Int.self, forKey: .serveCount) ?? 0
    }
}

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
}
