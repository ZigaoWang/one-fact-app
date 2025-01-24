import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case networkError(Error)
    case emptyResponse(String)
    
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
        case .emptyResponse(let category):
            return "No facts found\(category.isEmpty ? "" : " for \(category)")"
        }
    }
}

@MainActor
class FactService: ObservableObject {
    #if DEBUG
    private let baseURL = "http://localhost:8080/api/v1/facts"
    #else
    private let baseURL = "https://your-production-url.com/api/v1/facts"
    #endif
    
    private let cache = NSCache<NSString, CachedFact>()
    private let defaults = UserDefaults.standard
    private let jsonDecoder: JSONDecoder
    
    init() {
        self.jsonDecoder = JSONDecoder()
        
        // Create date formatters for different formats
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let backupFormatter = DateFormatter()
        backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        // Custom date decoding strategy that tries multiple formats
        self.jsonDecoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            // Try ISO8601 first
            if let date = iso8601Formatter.date(from: dateStr) {
                return date
            }
            
            // Try backup formatter
            if let date = backupFormatter.date(from: dateStr) {
                return date
            }
            
            // For "0001-01-01T00:00:00Z" (default time)
            if dateStr == "0001-01-01T00:00:00Z" {
                return Date(timeIntervalSince1970: 0)
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateStr)")
        }
    }
    
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
    
    func fetchDailyFact() async throws -> Fact {
        // Check cache first
        if let cachedFact = cache.object(forKey: "dailyFact" as NSString),
           cachedFact.isValid {
            return cachedFact.fact
        }
        
        guard let url = URL(string: "\(baseURL)/daily") else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "", code: -1))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError("Status code: \(httpResponse.statusCode)")
            }
            
            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
                
                // Handle null response
                if responseString == "null" {
                    throw APIError.emptyResponse("")
                }
            }
            
            // Try to decode as array first
            do {
                let facts = try jsonDecoder.decode([Fact].self, from: data)
                guard let fact = facts.first else {
                    throw APIError.emptyResponse("")
                }
                
                // Cache the fact
                let cachedFact = CachedFact(fact: fact, timestamp: Date())
                cache.setObject(cachedFact, forKey: "dailyFact" as NSString)
                
                return fact
            } catch {
                // If array decoding fails, try decoding as single fact
                let fact = try jsonDecoder.decode(Fact.self, from: data)
                
                // Cache the fact
                let cachedFact = CachedFact(fact: fact, timestamp: Date())
                cache.setObject(cachedFact, forKey: "dailyFact" as NSString)
                
                return fact
            }
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func searchFacts(query: String, category: String? = nil) async throws -> [Fact] {
        var urlComponents = URLComponents(string: "\(baseURL)/search")
        var queryItems = [URLQueryItem]()
        
        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "", code: -1))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError("Status code: \(httpResponse.statusCode)")
            }
            
            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
                
                // Handle null response
                if responseString == "null" {
                    throw APIError.emptyResponse(category ?? "")
                }
            }
            
            // Handle empty response
            if data.isEmpty {
                throw APIError.emptyResponse(category ?? "")
            }
            
            // Always try to decode as array first
            let facts = try jsonDecoder.decode([Fact].self, from: data)
            if facts.isEmpty {
                throw APIError.emptyResponse(category ?? "")
            }
            return facts
            
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func getRelatedArticles(for fact: Fact) -> [RelatedArticle] {
        // Convert relatedURLs to RelatedArticle objects using the metadata
        return fact.relatedURLs.enumerated().map { index, url in
            let keyword = fact.metadata.keywords.isEmpty ? fact.category : fact.metadata.keywords[0]
            let snippet = "Learn more about \(keyword) from \(fact.source)"
            
            return RelatedArticle(
                id: index,
                title: "Related Article \(index + 1)",
                url: url,
                source: fact.source,
                snippet: snippet
            )
        }
    }
}
