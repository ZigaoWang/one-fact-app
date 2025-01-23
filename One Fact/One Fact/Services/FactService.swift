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
    private let cache = NSCache<NSString, CachedFact>()
    private let defaults = UserDefaults.standard
    
    class CachedFact {
        let fact: Fact
        let timestamp: Date
        
        init(fact: Fact, timestamp: Date) {
            self.fact = fact
            self.timestamp = timestamp
        }
        
        var isValid: Bool {
            // Check if the fact is from today
            Calendar.current.isDate(timestamp, inSameDayAs: Date())
        }
    }
    
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
    
    func fetchFactByCategory(_ category: String) async throws -> Fact {
        // Check cache first
        if let cachedData = cache.object(forKey: category as NSString),
           cachedData.isValid {
            return cachedData.fact
        }
        
        // If not in cache or expired, fetch from server
        guard let encodedCategory = category.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/category/\(encodedCategory)/daily") else {
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
        let fact = apiResponse.data
        
        // Cache the result
        cache.setObject(CachedFact(fact: fact, timestamp: Date()), forKey: category as NSString)
        
        return fact
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
