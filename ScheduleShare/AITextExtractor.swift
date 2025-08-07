//
//  AITextExtractor.swift
//  ScheduleShare
//
//  AI-powered text extraction using OpenAIKit
//

import Foundation
import OpenAI

class AITextExtractor: ObservableObject {
    private let apiKey = "YOUR_OPENAI_API_KEY_HERE" // Replace with your actual OpenAI API key
    private var openAIClient: OpenAI?
    
    init() {
        setupOpenAIClient()
    }
    
    private func setupOpenAIClient() {
        openAIClient = OpenAI(apiToken: apiKey)
    }
    
    func extractEventInfo(from text: String, completion: @escaping (Result<ExtractedEventInfo, Error>) -> Void) {
        guard let client = openAIClient else {
            completion(.failure(AIExtractionError.clientNotInitialized))
            return
        }
        
        let prompt = createEventExtractionPrompt(from: text)
        
        Task {
            do {
                let query = ChatQuery(
                    messages: [
                        ChatQuery.ChatCompletionMessageParam(role: .system, content: "You are an AI assistant that extracts event information from text. Return only valid JSON.")!,
                        ChatQuery.ChatCompletionMessageParam(role: .user, content: prompt)!
                    ],
                    model: .gpt4_1,
                    maxCompletionTokens: 500,
                    temperature: 0.1
                )
                
                let chatCompletion = try await client.chats(query: query)
                
                if let content = chatCompletion.choices.first?.message.content {
                    print("🔍 AI Content: \(content)")
                    
                    // Parse the AI response content as JSON
                    guard let contentData = content.data(using: .utf8),
                          let eventData = try JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
                        print("❌ Failed to parse AI content as JSON")
                        throw AIExtractionError.invalidJSON
                    }
                    
                    let title = eventData["title"] as? String
                    let location = eventData["location"] as? String
                    let description = eventData["description"] as? String
                    let confidence = eventData["confidence"] as? Double ?? 0.5
                    
                    // Parse start date
                    var startDateTime: Date?
                    if let startDateString = eventData["startDateTime"] as? String {
                        let formatter = ISO8601DateFormatter()
                        startDateTime = formatter.date(from: startDateString)
                    }
                    
                    // Parse end date
                    var endDateTime: Date?
                    if let endDateString = eventData["endDateTime"] as? String {
                        let formatter = ISO8601DateFormatter()
                        endDateTime = formatter.date(from: endDateString)
                    }
                    
                    let extractedInfo = ExtractedEventInfo(
                        rawText: text,
                        title: title,
                        startDateTime: startDateTime,
                        endDateTime: endDateTime,
                        location: location,
                        description: description,
                        confidence: confidence
                    )
                    
                    print("✅ AI extraction successful!")
                    completion(.success(extractedInfo))
                    
                } else {
                    throw AIExtractionError.invalidResponse
                }
                
            } catch let error as OpenAIError {
                print("❌ OpenAI API Error: \(error)")
                completion(.failure(AIExtractionError.apiError(error.localizedDescription)))
            } catch {
                print("❌ AI parsing error: \(error.localizedDescription)")
                
                // Fallback: Try to extract basic information from the original text
                print("🔄 Attempting fallback extraction...")
                let fallbackInfo = self.createFallbackExtraction(from: text)
                completion(.success(fallbackInfo))
            }
        }
    }
    
    private func createEventExtractionPrompt(from text: String) -> String {
        return """
        You are an expert at extracting event information from text. Look for event titles, dates, times, and locations.
        
        Extract event information from this text and return a JSON object with the following structure:
        {
            "title": "Event title or name (be specific, not generic)",
            "startDateTime": "ISO 8601 date string in New York timezone (YYYY-MM-DDTHH:MM:SS-04:00) or null if not found",
            "endDateTime": "ISO 8601 date string in New York timezone (YYYY-MM-DDTHH:MM:SS-04:00) or null if not found",
            "location": "Specific location/venue/address or null if not found",
            "description": "Event description, details, or additional context or null if not found",
            "confidence": 0.0-1.0 confidence score based on how clear the event information is
        }
        
        CRITICAL DATE EXTRACTION RULES:
        - Extract the EXACT date shown in the text, do not guess or assume
        - If you see "Aug 5" or "8/5", extract as 2025-08-05T18:30:00-04:00 (New York time)
        - If you see "Aug 10" or "8/10", extract as 2025-08-10T18:30:00-04:00 (New York time)
        - Pay close attention to the specific day number in the text
        - Do not confuse similar-looking dates (5 vs 10, 1 vs 7, etc.)
        - If the date is ambiguous, use the most specific date mentioned
        - Current year is 2025, so "Aug 5" = 2025-08-05
        - ALWAYS use New York timezone (-04:00 for EDT, -05:00 for EST)
        - If you see "6:30 PM", extract as T18:30:00-04:00 (New York time)
        - If you see "6:30 PM - 8:30 PM", extract startDateTime as T18:30:00-04:00 and endDateTime as T20:30:00-04:00
        - If you see "6:30-8:30 PM", extract startDateTime as T18:30:00-04:00 and endDateTime as T20:30:00-04:00
        - If only start time is given, set endDateTime to null (will default to 1 hour later)
        
        Important: 
        - Look for actual event names, specific dates/times, and real locations
        - If the date is in the past, assume it's for the current year or next year
        - Don't make up information
        - For dates like "Aug 10" or "8/10", assume current year (2025) unless clearly specified otherwise
        
        Text to analyze:
        \(text)
        
        Return only the JSON object, no additional text or explanations.
        """
    }
    
    // MARK: - Fallback Extraction
    private func createFallbackExtraction(from text: String) -> ExtractedEventInfo {
        print("🔄 Creating fallback extraction from text: \(text)")
        
        // Simple regex patterns to extract basic information
        let lines = text.components(separatedBy: .newlines)
        
        var title = "Event"
        var location = ""
        var description = ""
        
        // Look for potential title (first non-empty line that looks like an event name)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.contains("Date") && !trimmed.contains("Time") && !trimmed.contains("Location") {
                title = trimmed
                break
            }
        }
        
        // Look for location patterns
        if let locationMatch = text.range(of: "Location[\\s\\n]*([^\\n]+)", options: .regularExpression) {
            location = String(text[locationMatch]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Use the original text as description
        description = text
        
        return ExtractedEventInfo(
            rawText: text,
            title: title,
            startDateTime: Date(), // Use current date as fallback
            endDateTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date()), // 1 hour later
            location: location.isEmpty ? nil : location,
            description: description,
            confidence: 0.3 // Low confidence for fallback
        )
    }
}

// MARK: - Error Types
enum AIExtractionError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case invalidJSON
    case apiError(String)
    case clientNotInitialized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from API"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .invalidJSON:
            return "Invalid JSON in AI response"
        case .apiError(let message):
            return "API Error: \(message)"
        case .clientNotInitialized:
            return "OpenAI client not initialized"
        }
    }
} 
