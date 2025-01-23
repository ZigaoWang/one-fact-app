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
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case content
        case category
        case source
        case url
        case displayDate
        case active
        case relatedArticles
    }
}
