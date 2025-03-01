import Foundation

// Server-Sent Events Delegate for handling streaming responses
class SSEDelegate: NSObject, URLSessionDataDelegate {
    private var buffer = Data()
    private var currentMessage = ""
    private let onReceive: (String) -> Void
    private let onComplete: (Result<Message, Error>) -> Void
    private var receivedData = false
    
    init(onReceive: @escaping (String) -> Void, onComplete: @escaping (Result<Message, Error>) -> Void) {
        self.onReceive = onReceive
        self.onComplete = onComplete
        super.init()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        receivedData = true
        
        // Process any complete events in the buffer
        processBuffer()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Task { @MainActor in
                onComplete(.failure(ChatError.networkError(error)))
            }
            return
        }
        
        // If we didn't receive any data, return a default message
        if !receivedData || currentMessage.isEmpty {
            print("No data received or empty message, using default response")
            Task { @MainActor in
                let defaultMessage = Message(role: .assistant, content: "I'm sorry, but I couldn't process your request at this time. Please try again later.")
                onComplete(.success(defaultMessage))
            }
            return
        }
        
        // Create the final message with the accumulated content
        Task { @MainActor in
            let finalMessage = Message(role: .assistant, content: currentMessage)
            onComplete(.success(finalMessage))
        }
    }
    
    private func processBuffer() {
        // Convert buffer to string
        guard let string = String(data: buffer, encoding: .utf8) else { return }
        
        // Split by SSE format lines
        let lines = string.components(separatedBy: "\n")
        var processedToIndex = 0
        
        for (index, line) in lines.enumerated() {
            // Skip empty lines
            guard !line.isEmpty else {
                processedToIndex = index + 1
                continue
            }
            
            // Check for data prefix
            if line.hasPrefix("data: ") {
                let data = line.dropFirst(6) // Remove "data: " prefix
                
                // Check if it's the completion marker
                if data == "[DONE]" {
                    processedToIndex = index + 1
                    continue
                }
                
                // Try to parse as JSON
                if let jsonData = data.data(using: .utf8) {
                    do {
                        // Allow fragments in JSON parsing
                        let options = JSONSerialization.ReadingOptions.allowFragments
                        
                        // First try to parse as a standard OpenAI streaming response
                        if let json = try JSONSerialization.jsonObject(with: jsonData, options: options) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let choice = choices.first,
                           let delta = choice["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                    
                            // Append to current message
                            currentMessage += content
                            
                            // Notify about new content
                            Task { @MainActor in
                                onReceive(content)
                            }
                        } else {
                            // If standard parsing fails, try to handle the raw text directly
                            // This is a fallback for non-standard SSE responses
                            let rawText = String(data: jsonData, encoding: .utf8) ?? ""
                            if !rawText.isEmpty {
                                // Append to current message
                                currentMessage += rawText
                                
                                // Notify about new content
                                Task { @MainActor in
                                    onReceive(rawText)
                                }
                            }
                        }
                    } catch {
                        print("Error parsing SSE JSON: \(error)")
                        
                        // Try to use the raw data as text if JSON parsing fails
                        let rawText = String(data: jsonData, encoding: .utf8) ?? ""
                        if !rawText.isEmpty {
                            // Append to current message
                            currentMessage += rawText
                            
                            // Notify about new content
                            Task { @MainActor in
                                onReceive(rawText)
                            }
                        }
                    }
                }
                
                processedToIndex = index + 1
            }
        }
        
        // Remove processed data from buffer
        if processedToIndex > 0 && processedToIndex < lines.count {
            let remainingLines = lines[processedToIndex...]
            buffer = remainingLines.joined(separator: "\n").data(using: .utf8) ?? Data()
        } else if processedToIndex > 0 {
            buffer.removeAll()
        }
    }
}
