//
//  SharingOptionsView.swift
//  ScheduleShare
//
//  View for selecting sharing options with time range
//

import SwiftUI

struct SharingOptionsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    let selectedEvent: CalendarEvent?
    let selectedDate: Date? // Add selected date from calendar
    @State private var selectedTimeRange: SharingTimeRange
    @State private var showingShareMethods = false
    @State private var eventsToShare: [CalendarEvent] = []
    @State private var showingEventSelection = false
    @State private var selectedEvents: Set<UUID> = []
    
    init(selectedEvent: CalendarEvent?, selectedDate: Date? = nil) {
        self.selectedEvent = selectedEvent
        self.selectedDate = selectedDate
        // Always default to "This Event" - it will handle the fallback to first event of selected date
        self._selectedTimeRange = State(initialValue: .thisEvent)
    }
    
    enum SharingTimeRange: String, CaseIterable {
        case thisEvent = "This Event"
        case selectEvents = "Select Events"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        
        var icon: String {
            switch self {
            case .thisEvent: return "calendar.badge.plus"
            case .selectEvents: return "checklist"
            case .today: return "calendar"
            case .thisWeek: return "calendar.badge.clock"
            case .thisMonth: return "calendar.badge.exclamationmark"
            }
        }
        
        var description: String {
            switch self {
            case .thisEvent: return "Share just this specific event"
            case .selectEvents: return "Choose specific events to share"
            case .today: return "Share all events happening today"
            case .thisWeek: return "Share all events this week"
            case .thisMonth: return "Share all events this month"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("Share Calendar")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose what you'd like to share")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                // Time Range Selection
                VStack(spacing: 12) {
                    ForEach(SharingTimeRange.allCases, id: \.self) { timeRange in
                        Button(action: {
                            selectedTimeRange = timeRange
                            updateEventsToShare()
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: timeRange.icon)
                                    .font(.title2)
                                    .foregroundColor(selectedTimeRange == timeRange ? .white : .purple)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(timeRange.rawValue)
                                        .font(.headline)
                                        .foregroundColor(selectedTimeRange == timeRange ? .white : .primary)
                                    
                                    Text(timeRange.description)
                                        .font(.caption)
                                        .foregroundColor(selectedTimeRange == timeRange ? .white.opacity(0.8) : .secondary)
                                }
                                
                                Spacer()
                                
                                if selectedTimeRange == timeRange {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedTimeRange == timeRange ? Color.purple : Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedTimeRange == timeRange ? Color.purple : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                // Event Selection Interface
                if selectedTimeRange == .selectEvents {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "checklist")
                                .foregroundColor(.purple)
                            Text("Select Events to Share")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            showingEventSelection = true
                        }) {
                            HStack {
                                Text(selectedEvents.isEmpty ? "Tap to select events" : "\(selectedEvents.count) event\(selectedEvents.count == 1 ? "" : "s") selected")
                                    .foregroundColor(selectedEvents.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Event Count Preview
                if !eventsToShare.isEmpty {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(.purple)
                            Text("\(eventsToShare.count) event\(eventsToShare.count == 1 ? "" : "s") to share")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        // Quick preview of events
                        ScrollView {
                            VStack(spacing: 6) {
                                ForEach(eventsToShare.prefix(3), id: \.id) { event in
                                    HStack {
                                        Text("• \(event.title)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                }
                                
                                if eventsToShare.count > 3 {
                                    Text("... and \(eventsToShare.count - 3) more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxHeight: 80)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Share Button
                Button(action: {
                    showingShareMethods = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                        Text("Share \(selectedTimeRange.rawValue)")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(eventsToShare.isEmpty ? Color.gray : Color.purple)
                    )
                }
                .disabled(eventsToShare.isEmpty)
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            updateEventsToShare()
        }
        .sheet(isPresented: $showingEventSelection) {
            EventSelectionView(
                events: getEventsFromToday(),
                selectedEvents: $selectedEvents,
                onDone: {
                    updateEventsToShare()
                    showingEventSelection = false
                }
            )
        }
        .actionSheet(isPresented: $showingShareMethods) {
            ActionSheet(
                title: Text("Share \(selectedTimeRange.rawValue)"),
                message: Text("Choose how you'd like to share your calendar"),
                buttons: [
                    .default(Text("Export as ICS File")) {
                        shareCalendar(.icsFile)
                    },
                    .default(Text("Share via Email")) {
                        shareCalendar(.email)
                    },
                    .default(Text("Share via Messages")) {
                        shareCalendar(.message)
                    },
                    .default(Text("Share Link")) {
                        shareCalendar(.link)
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private func updateEventsToShare() {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .thisEvent:
            if let event = selectedEvent {
                eventsToShare = [event]
            } else {
                // If no specific event is selected, default to the first event of the selected date
                let targetDate = selectedDate ?? now
                let startOfDay = calendar.startOfDay(for: targetDate)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                let dayEvents = appState.events.filter { event in
                    event.startDate >= startOfDay && event.startDate < endOfDay
                }.sorted { $0.startDate < $1.startDate }
                
                if let firstEvent = dayEvents.first {
                    eventsToShare = [firstEvent]
                } else {
                    // If no events on selected date, show empty
                    eventsToShare = []
                }
            }
            
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            eventsToShare = appState.events.filter { event in
                event.startDate >= startOfDay && event.startDate < endOfDay
            }
            
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
            eventsToShare = appState.events.filter { event in
                event.startDate >= startOfWeek && event.startDate < endOfWeek
            }
            
        case .selectEvents:
            // Use selected events from the selection interface
            eventsToShare = appState.events.filter { event in
                selectedEvents.contains(event.id)
            }
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            eventsToShare = appState.events.filter { event in
                event.startDate >= startOfMonth && event.startDate < endOfMonth
            }
        }
        
        // Sort events by start date
        eventsToShare.sort { $0.startDate < $1.startDate         }
    }
    
    private func getEventsFromToday() -> [CalendarEvent] {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        return appState.events.filter { event in
            event.startDate >= startOfDay
        }.sorted { $0.startDate < $1.startDate }
    }
    
    private func shareCalendar(_ method: SharingMethod) {
        guard !eventsToShare.isEmpty else { return }
        
        print("🔄 Starting share with method: \(method)")
        print("📊 Events to share: \(eventsToShare.count)")
        
        SharingManager.shared.shareCalendar(eventsToShare, method: method) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Calendar shared successfully")
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    print("❌ Failed to share calendar: \(error.localizedDescription)")
                    
                    // Show an alert for email/message not available
                    if let sharingError = error as? SharingError {
                        switch sharingError {
                        case .emailNotAvailable:
                            print("❌ Email not available on this device")
                            // Fallback to general sharing
                            self.fallbackToGeneralSharing()
                        case .messageNotAvailable:
                            print("❌ Messages not available on this device")
                            // Fallback to general sharing
                            self.fallbackToGeneralSharing()
                        case .exportFailed:
                            print("❌ Export failed")
                        }
                    }
                }
            }
        }
    }
    
    private func fallbackToGeneralSharing() {
        print("🔄 Falling back to general sharing")
        // Use the link sharing method as a fallback
        SharingManager.shared.shareCalendar(eventsToShare, method: .link) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Fallback sharing successful")
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    print("❌ Fallback sharing also failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    SharingOptionsView(selectedEvent: CalendarEvent(
        title: "Sample Event",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        location: "Sample Location",
        notes: "Sample notes"
    ))
    .environmentObject(AppState())
}

// MARK: - Event Selection View
struct EventSelectionView: View {
    let events: [CalendarEvent]
    @Binding var selectedEvents: Set<UUID>
    let onDone: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Select Events")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose which events to share")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Event List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(events, id: \.id) { event in
                            EventSelectionRow(
                                event: event,
                                isSelected: selectedEvents.contains(event.id),
                                onToggle: {
                                    if selectedEvents.contains(event.id) {
                                        selectedEvents.remove(event.id)
                                    } else {
                                        selectedEvents.insert(event.id)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Done Button
                Button(action: onDone) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        Text("Done (\(selectedEvents.count) selected)")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedEvents.isEmpty ? Color.gray : Color.purple)
                    )
                }
                .disabled(selectedEvents.isEmpty)
                .padding()
            }
            .navigationTitle("Select Events")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onDone()
                }
            )
        }
    }
}

// MARK: - Event Selection Row
struct EventSelectionRow: View {
    let event: CalendarEvent
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .purple : .gray)
                
                // Event Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatEventTime(event.startDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let location = event.location {
                            Image(systemName: "location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.purple.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return formatter.string(from: date)
    }
} 