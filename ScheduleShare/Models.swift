import Foundation
import SwiftUI
import EventKit
import CoreLocation

// MARK: - Core Data Models

struct CalendarEvent: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var notes: String?
    var extractedInfo: ExtractedEventInfo?
    var eventIdentifier: String?
    
    init(id: UUID = UUID(), title: String, startDate: Date, endDate: Date, location: String? = nil, notes: String? = nil, extractedInfo: ExtractedEventInfo? = nil, eventIdentifier: String? = nil) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.extractedInfo = extractedInfo
        self.eventIdentifier = eventIdentifier
    }
    
    // Custom initializer for updating events while preserving ID
    init(from event: CalendarEvent, title: String? = nil, startDate: Date? = nil, endDate: Date? = nil, location: String? = nil, notes: String? = nil) {
        self.id = event.id
        self.title = title ?? event.title
        self.startDate = startDate ?? event.startDate
        self.endDate = endDate ?? event.endDate
        self.location = location ?? event.location
        self.notes = notes ?? event.notes
        self.extractedInfo = event.extractedInfo
        self.eventIdentifier = event.eventIdentifier
    }
}

struct ExtractedEventInfo: Codable, Equatable {
    let rawText: String
    var title: String?
    var startDateTime: Date?
    var endDateTime: Date?
    var location: String?
    var description: String?
    var confidence: Double
    
    init(rawText: String, title: String? = nil, startDateTime: Date? = nil, endDateTime: Date? = nil, location: String? = nil, description: String? = nil, confidence: Double = 0.5) {
        self.rawText = rawText
        self.title = title
        self.startDateTime = startDateTime
        self.endDateTime = endDateTime
        self.location = location
        self.description = description
        self.confidence = confidence
    }
}

// MARK: - Location Models

struct LocationCoordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    var address: String?
    
    init(latitude: Double, longitude: Double, address: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
}

// MARK: - Route Planning Models

enum TransportationMode: String, CaseIterable, Codable {
    case walking = "walking"
    case subway = "subway"
    case bus = "bus"
    case taxi = "taxi"
    case rideshare = "rideshare"
    case driving = "driving"
    
    var displayName: String {
        switch self {
        case .walking: return "Walking"
        case .subway: return "Subway"
        case .bus: return "Bus"
        case .taxi: return "Taxi"
        case .rideshare: return "Rideshare"
        case .driving: return "Driving"
        }
    }
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .subway: return "tram.fill"
        case .bus: return "bus"
        case .taxi: return "car.fill"
        case .rideshare: return "car.circle"
        case .driving: return "car"
        }
    }
    
    var color: Color {
        switch self {
        case .walking: return .blue
        case .subway: return .green
        case .bus: return .orange
        case .taxi: return .yellow
        case .rideshare: return .purple
        case .driving: return .gray
        }
    }
}

struct RouteSegment: Identifiable, Codable {
    let id = UUID()
    let fromLocation: LocationCoordinate
    let toLocation: LocationCoordinate
    let transportationMode: TransportationMode
    let travelTime: Int // in seconds
    let cost: Double
    let instructions: String
    let departureTime: Date
    let arrivalTime: Date
    
    var formattedTravelTime: String {
        let minutes = travelTime / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedCost: String {
        return String(format: "$%.2f", cost)
    }
}

struct Route: Codable {
    let events: [CalendarEvent]
    let startingLocation: LocationCoordinate?
    var routeSegments: [RouteSegment] = []
    var totalTravelTime: Int = 0
    var totalCost: Double = 0.0
    
    init(events: [CalendarEvent], startingLocation: LocationCoordinate?) {
        self.events = events
        self.startingLocation = startingLocation
    }
}

struct RoutePlan: Codable {
    let segments: [RouteSegment]
    let totalTravelTime: Int
    let totalCost: Double
    
    init(segments: [RouteSegment], totalTravelTime: Int, totalCost: Double) {
        self.segments = segments
        self.totalTravelTime = totalTravelTime
        self.totalCost = totalCost
    }
}

struct CompleteRoutePlanResponse: Codable {
    let segments: [RouteSegmentData]
    let totalTravelTime: Int
    let totalCost: Double
}

// MARK: - AI Suggestion Models

enum SuggestionType: String, Codable, CaseIterable {
    case routeOptimization = "routeOptimization"
    case transportation = "transportation"
    case timeManagement = "timeManagement"
    case costOptimization = "costOptimization"
    case socialCoordination = "socialCoordination"
    
    var displayName: String {
        switch self {
        case .routeOptimization: return "Route Optimization"
        case .transportation: return "Transportation"
        case .timeManagement: return "Time Management"
        case .costOptimization: return "Cost Optimization"
        case .socialCoordination: return "Social Coordination"
        }
    }
}

struct AISuggestion: Identifiable, Codable {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let description: String
    let confidence: Double
    let action: String
    let costSavings: Double?
    let timeSavings: Int? // in seconds
    
    var formattedCostSavings: String? {
        guard let savings = costSavings else { return nil }
        return String(format: "$%.2f", savings)
    }
    
    var formattedTimeSavings: String? {
        guard let savings = timeSavings else { return nil }
        let minutes = savings / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct RouteSegmentData: Codable {
    let fromLocation: String
    let toLocation: String
    let transportationMode: String
    let travelTime: Int
    let cost: Double
    let instructions: String
}

// MARK: - Sharing Models

enum SharingTimeRange: String, CaseIterable {
    case thisEvent = "thisEvent"
    case today = "today"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case selectEvents = "selectEvents"
    
    var icon: String {
        switch self {
        case .thisEvent: return "calendar.badge.clock"
        case .today: return "calendar"
        case .thisWeek: return "calendar.badge.clock"
        case .thisMonth: return "calendar.badge.exclamationmark"
        case .selectEvents: return "checklist"
        }
    }
    
    var description: String {
        switch self {
        case .thisEvent: return "This Event"
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .selectEvents: return "Select Events"
        }
    }
}

// MARK: - App State Management

class AppState: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var selectedDate: Date = Date()
    @Published var selectedEvent: CalendarEvent?
    @Published var selectedEventForSheet: CalendarEvent?
    @Published var showingEventDetails = false
    @Published var showingSharingOptions = false
    @Published var showingRoutePlanning = false
    @Published var shouldSwitchToCalendar = false
    @Published var isCalculatingRoute = false
    @Published var currentRoute: Route?
    
    private let calendarManager = CalendarManager()
    private let locationManager = CLLocationManager()
    private let aiRoutePlanner: AIRoutePlanner
    
    init() {
        // Use the same API key as AITextExtractor
        self.aiRoutePlanner = AIRoutePlanner(apiKey: "YOUR_OPENAI_API_KEY_HERE")
    }
    
    func calculateRoute(for events: [CalendarEvent]) {
        guard !events.isEmpty else { return }
        
        isCalculatingRoute = true
        
        // Create starting location from current location or first event
        let startingLocation: LocationCoordinate?
        if let currentLocation = locationManager.location {
            startingLocation = LocationCoordinate(
                latitude: currentLocation.coordinate.latitude,
                longitude: currentLocation.coordinate.longitude
            )
        } else {
            // Use first event location as starting point
            startingLocation = nil
        }
        
        // Set calculating state
        DispatchQueue.main.async {
            self.isCalculatingRoute = true
        }
        
        // Generate comprehensive route plan using AI (with realistic delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.aiRoutePlanner.generateCompleteRoutePlan(for: events, startingLocation: startingLocation) { routePlan in
                DispatchQueue.main.async {
                    print("🤖 AI route plan received")
                    var route = Route(events: events, startingLocation: startingLocation)
                    route.routeSegments = routePlan.segments
                    route.totalTravelTime = routePlan.totalTravelTime
                    route.totalCost = routePlan.totalCost
                    self.currentRoute = route
                    self.isCalculatingRoute = false
                }
            }
        }
    }
    
    // MARK: - Event Management
    
    func addEvent(_ event: CalendarEvent) {
        events.append(event)
        saveEventsToLocalStorage()
        calendarManager.saveEvent(event) { result in
            switch result {
            case .success(let identifier):
                print("✅ Event saved to calendar with ID: \(identifier)")
            case .failure(let error):
                print("❌ Failed to save event to calendar: \(error.localizedDescription)")
            }
        }
    }
    
    func updateEvent(_ event: CalendarEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEventsToLocalStorage()
            if let identifier = event.eventIdentifier {
                calendarManager.updateEvent(identifier: identifier, with: event) { result in
                    switch result {
                    case .success:
                        print("✅ Event updated in calendar")
                    case .failure(let error):
                        print("❌ Failed to update event in calendar: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func deleteEvent(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
        saveEventsToLocalStorage()
        if let identifier = event.eventIdentifier {
            calendarManager.deleteEvent(identifier: identifier) { result in
                switch result {
                case .success:
                    print("✅ Event deleted from calendar")
                case .failure(let error):
                    print("❌ Failed to delete event from calendar: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Local Storage
    
    private func saveEventsToLocalStorage() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "savedEvents")
            print("💾 Saved \(events.count) events to local storage")
        }
    }
    
    func loadEventsFromLocalStorage() {
        if let data = UserDefaults.standard.data(forKey: "savedEvents"),
           let decoded = try? JSONDecoder().decode([CalendarEvent].self, from: data) {
            events = decoded
            print("📂 Loaded \(events.count) events from local storage")
        }
    }
    
    // MARK: - Computed Properties
    
    var currentEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return events.filter { event in
            event.startDate >= startOfDay && event.startDate < endOfDay
        }.sorted { $0.startDate < $1.startDate }
    }
    
    func eventsForDate(_ date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return events.filter { event in
            event.startDate >= startOfDay && event.startDate < endOfDay
        }.sorted { $0.startDate < $1.startDate }
    }
    
    func clearAllEvents() {
        events.removeAll()
        saveEventsToLocalStorage()
        print("🗑️ All events cleared from local storage")
    }
}

// MARK: - Error Types

enum AIExtractionError: Error, LocalizedError {
    case invalidURL
    case noData
    case clientNotInitialized
    case invalidResponse
    case invalidJSON
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from API"
        case .clientNotInitialized:
            return "AI client not initialized"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .invalidJSON:
            return "Invalid JSON format"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

// MARK: - Helper Extensions

extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return formatter.string(from: self)
    }
    
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return formatter.string(from: self)
    }
}

extension String {
    func extractCoordinatesFromLocation() -> LocationCoordinate {
        // Simple coordinate extraction - in a real app, you'd use geocoding
        return LocationCoordinate(latitude: 40.7128, longitude: -74.0060, address: self)
    }
} 