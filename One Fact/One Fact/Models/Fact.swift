import Foundation

struct Fact: Codable, Identifiable {
    let id: Int
    let content: String
    let category: String
    let source: String
    let url: String?
    let displayDate: Date
    let active: Bool
    let relatedArticles: [RelatedArticle]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        category = try container.decode(String.self, forKey: .category)
        source = try container.decode(String.self, forKey: .source)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        displayDate = try container.decode(Date.self, forKey: .displayDate)
        active = try container.decode(Bool.self, forKey: .active)
        relatedArticles = try container.decode([RelatedArticle].self, forKey: .relatedArticles)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(category, forKey: .category)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encode(displayDate, forKey: .displayDate)
        try container.encode(active, forKey: .active)
        try container.encode(relatedArticles, forKey: .relatedArticles)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case category
        case source
        case url
        case displayDate
        case active
        case relatedArticles
    }
}

// API Response models
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
}
