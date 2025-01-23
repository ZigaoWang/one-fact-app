import Foundation

struct RelatedArticle: Codable, Identifiable {
    let id: Int
    let title: String
    let url: String
    let source: String
    let snippet: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case source
        case snippet
    }
}
