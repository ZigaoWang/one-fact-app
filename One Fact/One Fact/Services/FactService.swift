import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

@MainActor
class FactService: ObservableObject {
    private let baseURL = "https://backend-broken-water-316.fly.dev/api/facts"
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            return try decoder.decode(Fact.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        }
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            let fact = try decoder.decode(Fact.self, from: data)
            // Cache the result
            cache.setObject(CachedFact(fact: fact, timestamp: Date()), forKey: category as NSString)
            return fact
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
