import Foundation

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
}

@MainActor
class FactService: ObservableObject {
    private let baseURL = "http://localhost:8080/api/facts"
    
    func fetchDailyFact() async throws -> Fact {
        guard let url = URL(string: "\(baseURL)/daily") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Server returned an error")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct APIResponse: Codable {
            let success: Bool
            let data: Fact
        }
        
        let apiResponse = try decoder.decode(APIResponse.self, from: data)
        return apiResponse.data
    }
    
    func fetchRandomFact() async throws -> Fact {
        guard let url = URL(string: "\(baseURL)/random") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Server returned an error")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct APIResponse: Codable {
            let success: Bool
            let data: Fact
        }
        
        let apiResponse = try decoder.decode(APIResponse.self, from: data)
        return apiResponse.data
    }
    
    func fetchFactByCategory(_ category: String) async throws -> Fact {
        guard let encodedCategory = category.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/category/\(encodedCategory)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Server returned an error")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct APIResponse: Codable {
            let success: Bool
            let data: [Fact]
        }
        
        let apiResponse = try decoder.decode(APIResponse.self, from: data)
        
        // Get a random fact from the category
        guard let fact = apiResponse.data.randomElement() else {
            throw APIError.noData
        }
        
        return fact
    }
}
