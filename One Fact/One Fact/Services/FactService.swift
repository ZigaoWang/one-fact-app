import Foundation

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
}

@MainActor
class FactService: ObservableObject {
    // MARK: - Properties
    private let baseURLs = [
        "http://172.20.10.2:5000/api"
    ]
    
    // MARK: - Methods
    func fetchDailyFact() async throws -> Fact {
        var lastError: Error?
        
        // Try each base URL until one works
        for baseURL in baseURLs {
            do {
                guard let url = URL(string: "\(baseURL)/fact/daily") else {
                    print("❌ Invalid URL: \(baseURL)/fact/daily")
                    throw APIError.invalidURL
                }
                
                print("🌐 Attempting to fetch daily fact from: \(url)")
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    throw APIError.serverError("Invalid response type")
                }
                
                print("📡 Response status code: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ Server error: \(httpResponse.statusCode)")
                    throw APIError.serverError("Server returned status code: \(httpResponse.statusCode)")
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                // Try decoding as a wrapped response first
                do {
                    let apiResponse = try decoder.decode(APIResponse<Fact>.self, from: data)
                    print("✅ Successfully fetched daily fact (wrapped)")
                    return apiResponse.data
                } catch {
                    // If that fails, try decoding directly as a Fact
                    print("⚠️ Trying to decode as direct Fact")
                    let fact = try decoder.decode(Fact.self, from: data)
                    print("✅ Successfully fetched daily fact (direct)")
                    return fact
                }
            } catch {
                print("❌ Error fetching from \(baseURL): \(error.localizedDescription)")
                lastError = error
                continue
            }
        }
        
        throw lastError ?? APIError.serverError("All URLs failed")
    }
    
    func fetchRelatedArticles(for factId: Int) async throws -> [RelatedArticle] {
        var lastError: Error?
        
        for baseURL in baseURLs {
            do {
                guard let url = URL(string: "\(baseURL)/fact/articles?factId=\(factId)") else {
                    print("❌ Invalid URL: \(baseURL)/fact/articles")
                    throw APIError.invalidURL
                }
                
                print("🌐 Attempting to fetch related articles from: \(url)")
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    throw APIError.serverError("Invalid response type")
                }
                
                print("📡 Response status code: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ Server error: \(httpResponse.statusCode)")
                    throw APIError.serverError("Server returned status code: \(httpResponse.statusCode)")
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                // Try decoding as a wrapped response first
                do {
                    let apiResponse = try decoder.decode(APIResponse<[RelatedArticle]>.self, from: data)
                    print("✅ Successfully fetched related articles (wrapped)")
                    return apiResponse.data
                } catch {
                    // If that fails, try decoding directly as [RelatedArticle]
                    print("⚠️ Trying to decode as direct [RelatedArticle]")
                    let articles = try decoder.decode([RelatedArticle].self, from: data)
                    print("✅ Successfully fetched related articles (direct)")
                    return articles
                }
            } catch {
                print("❌ Error fetching from \(baseURL): \(error.localizedDescription)")
                lastError = error
                continue
            }
        }
        
        throw lastError ?? APIError.serverError("All URLs failed")
    }
    
    func sendChatMessage(_ message: String) async throws -> String {
        var lastError: Error?
        
        for baseURL in baseURLs {
            do {
                guard let url = URL(string: "\(baseURL)/chat/message") else {
                    print("❌ Invalid URL: \(baseURL)/chat/message")
                    throw APIError.invalidURL
                }
                
                print("🌐 Attempting to send chat message to: \(url)")
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body = ["message": message]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    throw APIError.serverError("Invalid response type")
                }
                
                print("📡 Response status code: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ Server error: \(httpResponse.statusCode)")
                    throw APIError.serverError("Server returned status code: \(httpResponse.statusCode)")
                }
                
                let decoder = JSONDecoder()
                
                // Try decoding as a wrapped response first
                do {
                    let apiResponse = try decoder.decode(APIResponse<String>.self, from: data)
                    print("✅ Successfully sent chat message (wrapped)")
                    return apiResponse.data
                } catch {
                    // If that fails, try decoding directly as String
                    print("⚠️ Trying to decode as direct String")
                    let response = try decoder.decode(String.self, from: data)
                    print("✅ Successfully sent chat message (direct)")
                    return response
                }
            } catch {
                print("❌ Error sending to \(baseURL): \(error.localizedDescription)")
                lastError = error
                continue
            }
        }
        
        throw lastError ?? APIError.serverError("All URLs failed")
    }
}
