import Foundation

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
}
