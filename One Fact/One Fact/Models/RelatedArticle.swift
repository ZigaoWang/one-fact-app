import Foundation

struct RelatedArticle: Codable, Identifiable {
    let id: Int
    let title: String
    let url: String
    let source: String
    let imageUrl: String?
    let snippet: String
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case title
        case url
        case source
        case imageUrl
        case snippet
    }
}
