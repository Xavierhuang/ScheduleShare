//
//  AIRoutePlanner.swift
//  ScheduleShare
//
//  AI-powered route planning using OpenAI
//

import Foundation
import OpenAI

class AIRoutePlanner: ObservableObject {
    private let openAI: OpenAI
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.openAI = OpenAI(apiToken: apiKey)
    }
    
    func generateCompleteRoutePlan(for events: [CalendarEvent], startingLocation: LocationCoordinate?, completion: @escaping (RoutePlan) -> Void) {
        print("🤖 Starting comprehensive AI route planning for \(events.count) events")
        
        guard !events.isEmpty else {
            print("🤖 No events to analyze")
            completion(RoutePlan(segments: [], totalTravelTime: 0, totalCost: 0))
            return
        }
        
        let prompt = createCompleteRoutePlanningPrompt(events: events, startingLocation: startingLocation)
        print("🤖 AI Prompt: \(prompt)")
        
        let query = ChatQuery(
            messages: [
                ChatQuery.ChatCompletionMessageParam(role: .system, content: "You are an AI assistant that provides comprehensive route planning including segments, suggestions, and optimization. Return only valid JSON.")!,
                ChatQuery.ChatCompletionMessageParam(role: .user, content: prompt)!
            ],
            model: .gpt4_1,
            maxCompletionTokens: 1000,
            temperature: 0.1
        )
        
        print("🤖 Sending comprehensive request to OpenAI...")
        
        Task {
            do {
                let result = try await openAI.chats(query: query)
                print("🤖 Received response from OpenAI")
                
                if let content = result.choices.first?.message.content {
                    print("🤖 AI Content: \(content)")
                    let routePlan = parseCompleteRoutePlan(from: content, events: events)
                    DispatchQueue.main.async {
                        print("🤖 Returning route plan with \(routePlan.segments.count) segments")
                        completion(routePlan)
                    }
                } else {
                    print("❌ No content in AI response")
                    DispatchQueue.main.async {
                        completion(self.createFallbackRoutePlan(for: events))
                    }
                }
            } catch {
                print("❌ AI route planning failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    print("🤖 Using fallback route plan due to AI error")
                    completion(self.createFallbackRoutePlan(for: events))
                }
            }
        }
    }
    

    
    private func createCompleteRoutePlanningPrompt(events: [CalendarEvent], startingLocation: LocationCoordinate?) -> String {
        let eventDetails = events.map { event in
            """
            Event: \(event.title)
            Time: \(formatDate(event.startDate))
            Location: \(event.location ?? "No location")
            """
        }.joined(separator: "\n")
        
        let eventTimes = events.map { event in
            "\(event.title): \(formatDate(event.startDate))"
        }.joined(separator: ", ")
        
        let locationInfo = startingLocation != nil ? "User's current location is available" : "User's current location is not available"
        
        return """
        Create realistic route segments for these events in New York City.
        
        Events for the day:
        \(eventDetails)
        
        Event Times: \(eventTimes)
        Location: \(locationInfo)
        Current time: \(formatDate(Date()))
        
        CRITICAL: You must create exactly \(events.count) route segments:
        1. If user location is available: Start → Event 1, Event 1 → Event 2, Event 2 → Event 3, etc.
        2. If no user location: Starting Point → Event 1, Event 1 → Event 2, Event 2 → Event 3, etc.
        
        IMPORTANT RULES:
        - First segment: Starting Point → First Event Location
        - Middle segments: Each event location → Next event location
        - Last segment: Second-to-last event → Last event location
        - NO segments that stay at the same location
        - Consider event timing when choosing transportation (rush hour vs. off-peak)
        
        Return ONLY valid JSON in this exact format:
        {
          "segments": [
            {
              "fromLocation": {
                "latitude": 40.7308,
                "longitude": -73.9976,
                "address": "Starting Point"
              },
              "toLocation": {
                "latitude": 40.7378,
                "longitude": -74.0057,
                "address": "First Event Location"
              },
              "transportationMode": "subway",
              "travelTime": 1800,
              "cost": 2.75,
              "instructions": "Take A/C/E subway from Starting Point to First Event"
            },
            {
              "fromLocation": {
                "latitude": 40.7378,
                "longitude": -74.0057,
                "address": "First Event Location"
              },
              "toLocation": {
                "latitude": 40.7712,
                "longitude": -73.9742,
                "address": "Second Event Location"
              },
              "transportationMode": "walking",
              "travelTime": 900,
              "cost": 0,
              "instructions": "Walk from First Event to Second Event"
            }
          ],
          "totalTravelTime": 2700,
          "totalCost": 2.75
        }
        
        Consider:
        1. Real NYC transportation options (subway, bus, walking, Uber)
        2. Actual travel times between locations
        3. Realistic costs (subway $2.75, Uber $15-25, walking free)
        4. NYC geography and transit routes
        5. Time of day and typical travel patterns
        6. Event timing (rush hour vs. off-peak transportation choices)
        
        IMPORTANT: You must create exactly \(events.count) segments for \(events.count) events. 
        CRITICAL: All travelTime values must be actual numbers (e.g., 1800, 900) NOT expressions (e.g., 18 * 60).
        Return ONLY the JSON object, no additional text or markdown.
        """
    }
    
    private func parseCompleteRoutePlan(from content: String, events: [CalendarEvent]) -> RoutePlan {
        print("🔍 Raw AI route plan response: \(content)")
        
        // Clean the JSON string first
        let cleanedJson = cleanJsonString(content)
        print("🔍 Cleaned JSON: \(cleanedJson)")
        
        do {
            let data = cleanedJson.data(using: .utf8)!
            let response = try JSONDecoder().decode(CompleteRoutePlanResponse.self, from: data)
            print("✅ Successfully parsed complete route plan")
            
            let segments = response.segments.enumerated().map { index, segmentData in
                let eventIndex = min(index, events.count - 1)
                let event = events[eventIndex]
                
                // Parse location strings to coordinates (simplified)
                let fromLocation = LocationCoordinate(
                    latitude: 40.7128, // NYC default
                    longitude: -74.0060,
                    address: segmentData.fromLocation
                )
                let toLocation = LocationCoordinate(
                    latitude: 40.7128, // NYC default
                    longitude: -74.0060,
                    address: segmentData.toLocation
                )
                
                return RouteSegment(
                    fromLocation: fromLocation,
                    toLocation: toLocation,
                    transportationMode: TransportationMode(rawValue: segmentData.transportationMode) ?? .subway,
                    travelTime: segmentData.travelTime,
                    cost: segmentData.cost,
                    instructions: segmentData.instructions,
                    departureTime: event.startDate.addingTimeInterval(-Double(segmentData.travelTime)),
                    arrivalTime: event.startDate
                )
            }
            
            return RoutePlan(
                segments: segments,
                totalTravelTime: response.totalTravelTime,
                totalCost: response.totalCost
            )
        } catch {
            print("❌ Failed to parse complete route plan: \(error.localizedDescription)")
            return createFallbackRoutePlan(for: events)
        }
    }
    
    private func cleanJsonString(_ jsonString: String) -> String {
        var cleaned = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove any markdown code blocks
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        }
        if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        
        // Remove any leading/trailing text
        if let startIndex = cleaned.firstIndex(of: "{"),
           let endIndex = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[startIndex...endIndex])
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func createFallbackRoutePlan(for events: [CalendarEvent]) -> RoutePlan {
        var segments: [RouteSegment] = []
        var currentLocation = LocationCoordinate(latitude: 40.7128, longitude: -74.0060, address: "Starting Point")
        
        for event in events {
            let eventLocation = LocationCoordinate(latitude: 40.7128, longitude: -74.0060, address: event.location)
            
            let segment = RouteSegment(
                fromLocation: currentLocation,
                toLocation: eventLocation,
                transportationMode: .subway,
                travelTime: 1800, // 30 minutes
                cost: 2.75,
                instructions: "Take subway to \(event.title)",
                departureTime: event.startDate.addingTimeInterval(-1800),
                arrivalTime: event.startDate
            )
            segments.append(segment)
            currentLocation = eventLocation
        }
        
        return RoutePlan(
            segments: segments,
            totalTravelTime: segments.count * 1800,
            totalCost: Double(segments.count) * 2.75
        )
    }
    

    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return formatter.string(from: date)
    }
}

// AI Response models are defined in Models.swift 