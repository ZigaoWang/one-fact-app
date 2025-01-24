import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case networkError(Error)
    case tooManyRetries
    
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
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .tooManyRetries:
            return "Failed to connect after multiple attempts"
        }
    }
}

@MainActor
class FactService: ObservableObject {
    private let baseURL = "https://one-fact-backend.fly.dev/api/facts"
    private let cache = NSCache<NSString, CachedFact>()
    private let defaults = UserDefaults.standard
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0
    
    class CachedFact {
        let fact: Fact
        let timestamp: Date
        
        init(fact: Fact, timestamp: Date) {
            self.fact = fact
            self.timestamp = timestamp
        }
        
        var isValid: Bool {
            Calendar.current.isDate(timestamp, inSameDayAs: Date())
        }
    }
    
    private func fetchWithRetry(url: URL, retryCount: Int = 0) async throws -> (Data, URLResponse) {
        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10
            config.timeoutIntervalForResource = 30
            let session = URLSession(configuration: config)
            
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError("Invalid response")
            }
            
            // Print response for debugging
            print("Response status code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
            
            if httpResponse.statusCode >= 400, retryCount < maxRetries {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(retryCount + 1) * 1_000_000_000))
                return try await fetchWithRetry(url: url, retryCount: retryCount + 1)
            }
            
            guard httpResponse.statusCode == 200 else {
                throw APIError.serverError("Server returned \(httpResponse.statusCode)")
            }
            
            return (data, response)
        } catch let error as URLError {
            print("URLError: \(error.localizedDescription)")
            if retryCount < maxRetries {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(retryCount + 1) * 1_000_000_000))
                return try await fetchWithRetry(url: url, retryCount: retryCount + 1)
            }
            throw APIError.networkError(error)
        } catch {
            print("Other error: \(error.localizedDescription)")
            if retryCount < maxRetries {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(retryCount + 1) * 1_000_000_000))
                return try await fetchWithRetry(url: url, retryCount: retryCount + 1)
            }
            throw error
        }
    }
    
    func fetchDailyFact() async throws -> Fact {
        // Check cache first
        if let cached = cache.object(forKey: "dailyFact" as NSString), cached.isValid {
            return cached.fact
        }
        
        guard let url = URL(string: "\(baseURL)/daily") else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, _) = try await fetchWithRetry(url: url)
            let fact = try JSONDecoder().decode(Fact.self, from: data)
            
            // Cache the result
            let cachedFact = CachedFact(fact: fact, timestamp: Date())
            cache.setObject(cachedFact, forKey: "dailyFact" as NSString)
            
            return fact
        } catch let error as DecodingError {
            throw APIError.decodingError
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func fetchDailyFactByCategory(_ category: String) async throws -> Fact {
        // Check cache first
        let cacheKey = "dailyFact_\(category)" as NSString
        if let cached = cache.object(forKey: cacheKey), cached.isValid {
            return cached.fact
        }
        
        // URL encode the category name for special characters (e.g., "Fun Facts")
        let encodedCategory = category.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? category
        guard let url = URL(string: "\(baseURL)/category/\(encodedCategory)/daily") else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, _) = try await fetchWithRetry(url: url)
            let fact = try JSONDecoder().decode(Fact.self, from: data)
            
            // Cache the result
            let cachedFact = CachedFact(fact: fact, timestamp: Date())
            cache.setObject(cachedFact, forKey: cacheKey)
            
            return fact
        } catch let error as DecodingError {
            throw APIError.decodingError
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func fetchRandomFact() async throws -> Fact {
        guard let url = URL(string: "\(baseURL)/random") else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, _) = try await fetchWithRetry(url: url)
            return try JSONDecoder().decode(Fact.self, from: data)
        } catch let error as DecodingError {
            throw APIError.decodingError
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func fetchFactsByCategory(_ category: String) async throws -> [Fact] {
        // URL encode the category name for special characters (e.g., "Fun Facts")
        let encodedCategory = category.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? category
        guard let url = URL(string: "\(baseURL)/category/\(encodedCategory)") else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, _) = try await fetchWithRetry(url: url)
            return try JSONDecoder().decode([Fact].self, from: data)
        } catch let error as DecodingError {
            throw APIError.decodingError
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}
