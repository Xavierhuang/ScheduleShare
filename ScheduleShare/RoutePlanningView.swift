//
//  RoutePlanningView.swift
//  ScheduleShare
//
//  View for displaying route planning with AI suggestions
//

import SwiftUI
import CoreLocation

struct RoutePlanningView: View {
    @EnvironmentObject var appState: AppState
    @State private var locationManager = CLLocationManager()
    @StateObject private var aiRoutePlanner: AIRoutePlanner
    @Environment(\.presentationMode) var presentationMode
    
    let events: [CalendarEvent]
    @State private var showingLocationPermission = false
    @State private var showingMapOptions = false
    @State private var selectedLocationForMap: LocationCoordinate?
    @State private var selectedEventForMap: CalendarEvent?
    @State private var isCalculating = false
    @State private var currentRoute: Route?
    
    init(events: [CalendarEvent]) {
        self.events = events
        self._aiRoutePlanner = StateObject(wrappedValue: AIRoutePlanner(apiKey: "YOUR_OPENAI_API_KEY_HERE"))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Your Day Plan")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("AI-optimized route with smart suggestions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // Location Status
                    LocationStatusView(locationManager: locationManager)
                    
                    // Route Overview
                    if let route = currentRoute {
                        RouteOverviewCard(route: route, onTapEvent: { event in
                            selectedEventForMap = event
                            showingMapOptions = true
                        })
                        
                        // Route Segments
                        RouteSegmentsView(segments: route.routeSegments, onTapLocation: { location in
                            selectedLocationForMap = location
                            showingMapOptions = true
                        })
                    } else if isCalculating {
                        CalculatingRouteView()
                    } else {
                        // Calculate Route Button
                        Button(action: calculateRoute) {
                            HStack(spacing: 12) {
                                Image(systemName: "map")
                                    .font(.title2)
                                Text("Calculate Route")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Bottom spacing for better scrolling
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationTitle("Route Planning")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            setupLocationServices()
        }
        .alert("Location Permission", isPresented: $showingLocationPermission) {
            Button("Allow") {
                locationManager.requestWhenInUseAuthorization()
            }
            Button("Not Now", role: .cancel) { }
        } message: {
            Text("Location access helps optimize your route from your current position.")
        }
        .actionSheet(isPresented: $showingMapOptions) {
            ActionSheet(
                title: Text("Open in Maps"),
                message: Text("Choose your preferred map app"),
                buttons: [
                    .default(Text("Apple Maps")) {
                        if let location = selectedLocationForMap {
                            openAppleMapsForLocation(location)
                        } else if let event = selectedEventForMap {
                            openAppleMapsForEvent(event)
                        }
                    },
                    .default(Text("Google Maps")) {
                        if let location = selectedLocationForMap {
                            openGoogleMapsForLocation(location)
                        } else if let event = selectedEventForMap {
                            openGoogleMapsForEvent(event)
                        }
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private func setupLocationServices() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            showingLocationPermission = true
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            // Use default location
            break
        @unknown default:
            break
        }
    }
    
    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func calculateRoute() {
        isCalculating = true
        
        // Create starting location from current location or first event
        let startingLocation: LocationCoordinate?
        if let currentLocation = locationManager.location {
            startingLocation = LocationCoordinate(
                latitude: currentLocation.coordinate.latitude,
                longitude: currentLocation.coordinate.longitude
            )
        } else {
            startingLocation = nil
        }
        
        // Generate route plan using AI
        aiRoutePlanner.generateCompleteRoutePlan(for: events, startingLocation: startingLocation) { routePlan in
            DispatchQueue.main.async {
                var route = Route(events: events, startingLocation: startingLocation)
                route.routeSegments = routePlan.segments
                route.totalTravelTime = routePlan.totalTravelTime
                route.totalCost = routePlan.totalCost
                self.currentRoute = route
                self.isCalculating = false
            }
        }
    }
    
    // MARK: - Maps Integration
    private func openGoogleMapsForLocation(_ location: LocationCoordinate) {
        let urlString = "https://maps.google.com/?q=\(location.latitude),\(location.longitude)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openAppleMapsForLocation(_ location: LocationCoordinate) {
        let urlString = "http://maps.apple.com/?q=\(location.latitude),\(location.longitude)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openGoogleMapsForEvent(_ event: CalendarEvent) {
        let coordinates = extractCoordinatesFromLocation(event.location)
        let urlString = "https://maps.google.com/?q=\(coordinates.latitude),\(coordinates.longitude)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openAppleMapsForEvent(_ event: CalendarEvent) {
        let coordinates = extractCoordinatesFromLocation(event.location)
        let urlString = "http://maps.apple.com/?q=\(coordinates.latitude),\(coordinates.longitude)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func extractCoordinatesFromLocation(_ location: String?) -> (latitude: Double, longitude: Double) {
        // Default to NYC coordinates if location parsing fails
        guard let location = location else {
            return (40.7128, -74.0060) // NYC default
        }
        
        // Try to extract coordinates from location string
        // This is a simplified version - in a real app you'd use geocoding
        if location.contains("Washington Square Park") {
            return (40.7308, -73.9976)
        } else if location.contains("Abingdon Square") {
            return (40.7484, -74.0047)
        } else if location.contains("Sheep Meadow") {
            return (40.7645, -73.9731)
        } else if location.contains("The Hugh") {
            return (40.7589, -73.9851)
        } else if location.contains("SHIPYARD") {
            return (40.7484, -74.0047)
        } else {
            return (40.7128, -74.0060) // NYC default
        }
    }
}

// MARK: - Location Status View
struct LocationStatusView: View {
    let locationManager: CLLocationManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: locationManager.location != nil ? "location.fill" : "location.slash")
                .foregroundColor(locationManager.location != nil ? .green : .orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(locationManager.location != nil ? "Location Enabled" : "Location Not Available")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(locationManager.location != nil ? "Route optimized from your location" : "Using default starting point")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

// MARK: - Route Overview Card
struct RouteOverviewCard: View {
    let route: Route
    let onTapEvent: (CalendarEvent) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Route Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(route.events.count) events • \(formatTime(TimeInterval(route.totalTravelTime))) travel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", route.totalCost))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("Total Cost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick event preview
            VStack(spacing: 8) {
                ForEach(route.events.prefix(3), id: \.id) { event in
                    HStack {
                        Text("• \(event.title)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatTime(event.startDate))
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Button(action: {
                            onTapEvent(event)
                        }) {
                            Image(systemName: "map")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if route.events.count > 3 {
                    Text("... and \(route.events.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        return "\(minutes) min"
    }
    
    private func openGoogleMapsForEvent(_ event: CalendarEvent) {
        // Extract coordinates from location string (simplified)
        let coordinates = extractCoordinatesFromLocation(event.location)
        let urlString = "https://maps.google.com/?q=\(coordinates.latitude),\(coordinates.longitude)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func extractCoordinatesFromLocation(_ location: String?) -> (latitude: Double, longitude: Double) {
        // Default to NYC coordinates if location parsing fails
        guard let location = location else {
            return (40.7128, -74.0060) // NYC default
        }
        
        // Try to extract coordinates from location string
        // This is a simplified version - in a real app you'd use geocoding
        if location.contains("Washington Square Park") {
            return (40.7308, -73.9976)
        } else if location.contains("Abingdon Square") {
            return (40.7378, -74.0057)
        } else if location.contains("Sheep Meadow") {
            return (40.7645, -73.9731)
        } else {
            return (40.7128, -74.0060) // NYC default
        }
    }
}

// MARK: - AI Suggestions View
struct AISuggestionsView: View {
    let suggestions: [AISuggestion]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text("AI Suggestions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(suggestions, id: \.id) { suggestion in
                        AISuggestionCard(suggestion: suggestion)
                    }
                }
            }
            .frame(maxHeight: 300) // Limit height for better UX
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

// MARK: - AI Suggestion Card
struct AISuggestionCard: View {
    let suggestion: AISuggestion
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForSuggestionType(suggestion.type))
                .foregroundColor(.purple)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(suggestion.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let costSavings = suggestion.costSavings {
                    Text("Saves $\(String(format: "%.2f", costSavings))")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                
                if let timeSavings = suggestion.timeSavings {
                    Text("Saves \(Int(timeSavings / 60)) minutes")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(suggestion.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
                
                Text("Confidence")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
    }
    
    private func iconForSuggestionType(_ type: SuggestionType) -> String {
        switch type {
        case .routeOptimization: return "arrow.triangle.2.circlepath"
        case .timeManagement: return "clock"
        case .costOptimization: return "dollarsign.circle"
        case .transportation: return "tram.fill"
        case .socialCoordination: return "person.2"
        }
    }
}

// MARK: - Route Segments View
struct RouteSegmentsView: View {
    let segments: [RouteSegment]
    let onTapLocation: (LocationCoordinate) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "map")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text("Route Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(segments, id: \.id) { segment in
                        RouteSegmentCard(segment: segment, onTapLocation: onTapLocation)
                    }
                }
            }
            .frame(maxHeight: 400) // Limit height for better UX
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

// MARK: - Route Segment Card
struct RouteSegmentCard: View {
    let segment: RouteSegment
    let onTapLocation: (LocationCoordinate) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: segment.transportationMode.icon)
                .foregroundColor(segment.transportationMode.color)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(segment.transportationMode.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(segment.instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(formatTime(TimeInterval(segment.travelTime))) • $\(String(format: "%.2f", segment.cost))")
                    .font(.caption)
                    .foregroundColor(.purple)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(segment.departureTime))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Departure")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
        .onTapGesture {
            onTapLocation(segment.toLocation)
        }
    }
    
    private func openGoogleMaps(for location: LocationCoordinate) {
        let urlString = "https://maps.google.com/?q=\(location.latitude),\(location.longitude)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        return "\(minutes) min"
    }
}

// MARK: - Calculating Route View
struct CalculatingRouteView: View {
    @State private var thinkingStep = 0
    let thinkingSteps = [
        "🤖 AI analyzing your events...",
        "🗺️ Calculating optimal routes...",
        "🚇 Finding best transportation...",
        "⏱️ Estimating travel times...",
        "💰 Calculating costs..."
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // AI Brain Icon with Spinner
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 30))
                    .foregroundColor(.purple)
                
                ProgressView()
                    .scaleEffect(0.8)
                    .foregroundColor(.purple)
                    .offset(x: 25, y: -25)
            }
            
            VStack(spacing: 8) {
                Text("AI Route Planning")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(thinkingSteps[thinkingStep])
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.5), value: thinkingStep)
            }
            
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<thinkingSteps.count, id: \.self) { index in
                    Circle()
                        .fill(index == thinkingStep ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: thinkingStep)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
        .onAppear {
            startThinkingAnimation()
        }
    }
    
    private func startThinkingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            withAnimation {
                thinkingStep = (thinkingStep + 1) % thinkingSteps.count
            }
        }
    }
}

#Preview {
    RoutePlanningView(events: [
        CalendarEvent(
            title: "Coffee Meeting",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(7200),
            location: "Starbucks, Downtown"
        ),
        CalendarEvent(
            title: "Lunch",
            startDate: Date().addingTimeInterval(14400),
            endDate: Date().addingTimeInterval(18000),
            location: "Restaurant, Midtown"
        )
    ])
    .environmentObject(AppState())
} 