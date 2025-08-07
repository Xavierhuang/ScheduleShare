//
//  CalendarView.swift
//  ScheduleShare
//
//  Calendar view to display and manage events
//

import SwiftUI
import EventKit

struct CalendarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var calendarManager: CalendarManager
    private let sharingManager = SharingManager.shared
    
    @State private var selectedDate = Date()
    @State private var showingSharingOptions = false
    @State private var showingEventDetails = false
    @State private var selectedEvent: CalendarEvent? {
        didSet {
            print("🔄 selectedEvent changed: \(selectedEvent?.title ?? "nil")")
        }
    }
    @State private var selectedEventId: UUID?
    @State private var sheetEventId: UUID? // Separate state for sheet
    @State private var currentEventId: UUID? // Direct event ID for sheet
    @State private var eventForSheet: CalendarEvent? // Direct event for sheet
    @State private var lastTappedEventId: UUID? // Most reliable event ID
    @State private var eventToDisplay: CalendarEvent? // Direct event object for sheet
    @State private var capturedEvent: CalendarEvent? // Event captured in closure
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingManualEventCreation = false
    @State private var showingRoutePlanning = false
    @State private var refreshTrigger = false // Trigger for refreshing events
    @State private var lastEventUpdate = Date() // Track last event update
    
    private let calendar = Calendar.current
    
    // Computed property to make the view reactive to event changes
    private var currentEvents: [CalendarEvent] {
        print("🔄 currentEvents computed property called, events count: \(appState.events.count)")
        return appState.events
    }
    
    // Computed property to find the event to display in sheet
    private var eventToShow: CalendarEvent? {
        print("🔍 eventToShow computed property called")
        print("🔍 appState.selectedEventForSheet: \(appState.selectedEventForSheet?.title ?? "nil")")
        print("🔍 capturedEvent: \(capturedEvent?.title ?? "nil")")
        print("🔍 lastTappedEventId: \(lastTappedEventId?.uuidString ?? "nil")")
        
        // Use appState.selectedEventForSheet as the most stable method
        if let stableEvent = appState.selectedEventForSheet {
            print("✅ Using appState.selectedEventForSheet: \(stableEvent.title)")
            return stableEvent
        }
        
        // Use capturedEvent as primary since it's set in the closure and should be most stable
        if let captured = capturedEvent {
            print("✅ Using capturedEvent: \(captured.title)")
            return captured
        }
        
        // Fallback to ID-based lookup using lastTappedEventId
        if let eventId = lastTappedEventId,
           let foundEvent = appState.events.first(where: { $0.id == eventId }) {
            print("✅ Using lastTappedEventId lookup: \(foundEvent.title)")
            return foundEvent
        }
        
        print("❌ No event found in any fallback method")
        return nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                // Month Navigation
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.purple)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.purple.opacity(0.1))
                            )
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(monthYearFormatter.string(from: selectedDate))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(eventsForDate(selectedDate).count) events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.purple)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.purple.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                // Calendar Grid
                CalendarGridView(
                    selectedDate: $selectedDate,
                    events: appState.events
                )
                
                // Events List for Selected Date
                ScrollView {
                    LazyVStack(spacing: 12) {
                        let dayEvents = eventsForDate(selectedDate)
                        
                        if dayEvents.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 60))
                                    .foregroundColor(.purple.opacity(0.6))
                                    .padding()
                                    .background(
                                        Circle()
                                            .fill(Color.purple.opacity(0.1))
                                            .frame(width: 100, height: 100)
                                    )
                                
                                VStack(spacing: 8) {
                                    Text("No events for \(dateFormatter.string(from: selectedDate))")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Tap the + tab to add events from screenshots")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.vertical, 40)
                        } else {
                            ForEach(dayEvents) { event in
                                EventRowView(event: event) {
                                    print("🎯 Event tapped: \(event.title)")
                                    print("📅 Event date: \(event.startDate)")
                                    print("📍 Event location: \(event.location ?? "nil")")
                                    
                                    // Store the event in appState for stable access
                                    appState.selectedEventForSheet = event
                                    
                                    // Also set local state for fallback
                                    selectedEvent = event
                                    selectedEventId = event.id
                                    lastTappedEventId = event.id
                                    capturedEvent = event
                                    showingEventDetails = true
                                    
                                    print("✅ Set appState.selectedEventForSheet to: \(event.title)")
                                    print("✅ Set selectedEvent to: \(event.title)")
                                    print("✅ Set selectedEventId to: \(event.id)")
                                    print("✅ Set lastTappedEventId to: \(event.id)")
                                    print("✅ Set capturedEvent to: \(event.title)")
                                    print("✅ Set showingEventDetails = true")
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("My Calendar")
            .navigationBarItems(
                trailing: HStack(spacing: 16) {
                    Button(action: {
                        showingManualEventCreation = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.purple)
                    }
                    
                    if !appState.events.isEmpty {
                        Button(action: {
                            showingRoutePlanning = true
                        }) {
                            Image(systemName: "map")
                                .foregroundColor(.purple)
                        }
                        
                        Button(action: {
                            // Dismiss any existing sheets before showing share options
                            showingEventDetails = false
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingSharingOptions = true
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.purple)
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showingSharingOptions) {
            SharingOptionsView(selectedEvent: eventToShow, selectedDate: selectedDate)
        }
        .sheet(isPresented: $showingEventDetails) {
            if let event = eventToShow {
                // Use the updated event from AppState if available
                let currentEvent = appState.selectedEventForSheet ?? event
                EventDetailDisplayView(event: Binding(
                    get: { appState.selectedEventForSheet ?? currentEvent },
                    set: { newEvent in
                        appState.selectedEventForSheet = newEvent
                    }
                )) { updatedEvent in
                    updateEvent(updatedEvent)
                } onDelete: {
                    deleteEvent(currentEvent)
                    // Clear all state after deletion
                    appState.selectedEventForSheet = nil
                    selectedEvent = nil
                    selectedEventId = nil
                    lastTappedEventId = nil
                    capturedEvent = nil
                }
                .onAppear {
                    print("✅ Sheet opened with event: \(currentEvent.title)")
                }

            } else {
                VStack(spacing: 20) {
                    Text("Event Not Found")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text("The selected event could not be loaded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Close") {
                        showingEventDetails = false
                        appState.selectedEventForSheet = nil
                        selectedEvent = nil
                        selectedEventId = nil
                        lastTappedEventId = nil
                        capturedEvent = nil
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .onAppear {
                    print("❌ Sheet opened but no event found!")
                }
            }
        }
        .sheet(isPresented: $showingManualEventCreation) {
            ManualEventCreationView()
        }
        .sheet(isPresented: $showingRoutePlanning) {
            RoutePlanningView(events: eventsForDate(selectedDate))
        }
        .alert("Share Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadEvents()
            // Clear any lingering selected event state
            selectedEvent = nil
            selectedEventId = nil
        }
        .onChange(of: appState.events.count) { _ in
            // Refresh when events are added/removed
            print("🔄 Events count changed, refreshing calendar...")
            refreshTrigger.toggle()
        }
        .onChange(of: refreshTrigger) { _ in
            // Force refresh of the view
            print("🔄 Refresh trigger activated")
        }
        .onReceive(appState.$events) { _ in
            // Also listen to the events array directly
            print("🔄 Events array updated, refreshing calendar...")
        }
        .onChange(of: appState.events) { _ in
            // Refresh when events are modified (not just count changes)
            print("🔄 Events modified, refreshing calendar...")
            refreshTrigger.toggle()
        }
        .onChange(of: lastEventUpdate) { _ in
            // Force refresh when events are updated locally
            print("🔄 Local event update detected, refreshing calendar...")
            // Force reload of events
            loadEvents()
        }
        .onChange(of: selectedDate) { _ in
            // Refresh when selected date changes
            print("📅 Selected date changed to: \(dateFormatter.string(from: selectedDate))")
        }
    }
    
    // MARK: - Private Methods
    private func previousMonth() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextMonth() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }
    
    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        let events = currentEvents.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }.sorted { $0.startDate < $1.startDate }
        
        // Debug logging to see what events are found
        if !events.isEmpty {
            print("📅 Found \(events.count) events for \(dateFormatter.string(from: date)):")
            for event in events {
                print("   - \(event.title) at \(dateFormatter.string(from: event.startDate))")
            }
        }
        
        return events
    }
    
    private func loadEvents() {
        // Load events from EventKit if permission granted
        if calendarManager.hasCalendarPermission {
            let ekEvents = calendarManager.getUpcomingEvents()
            // Convert EKEvents to CalendarEvents (simplified)
            // In a real app, you'd want to sync this properly
        }
    }
    

    
    private func updateEvent(_ event: CalendarEvent) {
        print("🔄 Updating event in calendar view: \(event.title)")
        appState.updateEvent(event)
        
        // Force immediate UI refresh
        lastEventUpdate = Date()
        refreshTrigger.toggle()
        
        // Update selected date to show the new event date if it's different
        if !calendar.isDate(event.startDate, inSameDayAs: selectedDate) {
            print("📅 Event moved to different date, updating selected date to: \(dateFormatter.string(from: event.startDate))")
            selectedDate = event.startDate
        }
        
        // Update the selected event for sheet if it's the same event
        if selectedEvent?.id == event.id {
            print("🔄 Updating selectedEvent with new data")
            selectedEvent = event
        }
        
        // Also update in calendar if permission granted
        if calendarManager.hasCalendarPermission {
            // Note: This would require more complex EventKit update logic
            // For now, we'll just update the local storage
            print("📝 Event updated in local storage")
        }
    }
    
    private func deleteEvent(_ event: CalendarEvent) {
        appState.deleteEvent(event)
        
        // Clear selected event state if we're deleting the selected event
        if selectedEventId == event.id {
            selectedEvent = nil
            selectedEventId = nil
        }
        
        if let identifier = event.eventIdentifier {
            calendarManager.deleteEvent(identifier: identifier) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        // No alert needed - user can see the event disappeared
                        break
                    case .failure(let error):
                        self.alertMessage = "Failed to delete from calendar: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }
        }
    }
    
    // MARK: - Formatters
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.timeZone = TimeZone(identifier: "America/New_York") // Set to New York timezone
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = TimeZone(identifier: "America/New_York") // Set to New York timezone
        return formatter
    }
}

// MARK: - Calendar Grid View
struct CalendarGridView: View {
    @Binding var selectedDate: Date
    let events: [CalendarEvent]
    
    private let calendar = Calendar.current
    private let weekdayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday headers
            HStack {
                ForEach(weekdayLabels, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            // Calendar grid
            let daysInMonth = daysInCurrentMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        hasEvents: hasEventsForDate(date),
                        isCurrentMonth: calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
                    ) {
                        selectedDate = date
                    }
                }
            }
        }
        .padding()
    }
    
    private func daysInCurrentMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1) else {
            return []
        }
        
        var days: [Date] = []
        var date = monthFirstWeek.start
        
        while date < monthLastWeek.end {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days
    }
    
    private func hasEventsForDate(_ date: Date) -> Bool {
        return events.contains { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasEvents: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(textColor)
                
                if hasEvents {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(isSelected ? Color.purple : Color.clear)
                    .shadow(color: isSelected ? .purple.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
            )
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary
        }
    }
}

// MARK: - Event Row View
struct EventRowView: View {
    let event: CalendarEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Event icon
                Image(systemName: "calendar.badge.plus")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.purple.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(timeFormatter.string(from: event.startDate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let location = event.location {
                            HStack(spacing: 4) {
                                Image(systemName: "location")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(location)
                                    .font(.caption)
                                    .foregroundColor(.purple)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "America/New_York") // Set to New York timezone
        return formatter
    }
}

#Preview {
    CalendarView()
}