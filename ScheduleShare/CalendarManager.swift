//
//  CalendarManager.swift
//  ScheduleShare
//
//  Calendar integration using EventKit
//

import Foundation
import EventKit
import UIKit

class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var hasCalendarPermission = false
    
    init() {
        checkCalendarPermission()
    }
    
    // MARK: - Permission Handling
    func checkCalendarPermission() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            hasCalendarPermission = true
        case .denied, .restricted:
            hasCalendarPermission = false
        case .notDetermined:
            requestCalendarPermission()
        @unknown default:
            hasCalendarPermission = false
        }
    }
    
    func requestCalendarPermission() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasCalendarPermission = granted
            }
        }
    }
    
    // MARK: - Event Management
    func saveEvent(_ calendarEvent: CalendarEvent, completion: @escaping (Result<String, Error>) -> Void) {
        print("🏪 CalendarManager.saveEvent called")
        print("🔑 Has permission: \(hasCalendarPermission)")
        
        guard hasCalendarPermission else {
            print("❌ No calendar permission!")
            completion(.failure(CalendarError.noPermission))
            return
        }
        
        print("📅 Creating EKEvent...")
        let event = EKEvent(eventStore: eventStore)
        event.title = calendarEvent.title
        event.startDate = calendarEvent.startDate
        event.endDate = calendarEvent.endDate
        event.notes = calendarEvent.notes
        event.location = calendarEvent.location
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        print("💾 Event details:")
        print("   Title: \(event.title ?? "nil")")
        print("   Start: \(event.startDate?.description ?? "nil")")
        print("   End: \(event.endDate?.description ?? "nil")")
        print("   Location: \(event.location ?? "nil")")
        print("   Calendar: \(event.calendar?.title ?? "nil")")
        
        do {
            print("🔄 Attempting to save to EventStore...")
            try eventStore.save(event, span: .thisEvent)
            print("✅ EventStore save successful! Event ID: \(event.eventIdentifier)")
            completion(.success(event.eventIdentifier))
        } catch {
            print("❌ EventStore save failed: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    func updateEvent(identifier: String, with calendarEvent: CalendarEvent, completion: @escaping (Result<Void, Error>) -> Void) {
        guard hasCalendarPermission else {
            completion(.failure(CalendarError.noPermission))
            return
        }
        
        guard let event = eventStore.event(withIdentifier: identifier) else {
            completion(.failure(CalendarError.eventNotFound))
            return
        }
        
        event.title = calendarEvent.title
        event.startDate = calendarEvent.startDate
        event.endDate = calendarEvent.endDate
        event.notes = calendarEvent.notes
        event.location = calendarEvent.location
        
        do {
            try eventStore.save(event, span: .thisEvent)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteEvent(identifier: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard hasCalendarPermission else {
            completion(.failure(CalendarError.noPermission))
            return
        }
        
        guard let event = eventStore.event(withIdentifier: identifier) else {
            completion(.failure(CalendarError.eventNotFound))
            return
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Calendar Queries
    func getEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        guard hasCalendarPermission else { return [] }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        return eventStore.events(matching: predicate)
    }
    
    func getUpcomingEvents(days: Int = 30) -> [EKEvent] {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate) ?? startDate
        return getEvents(from: startDate, to: endDate)
    }
    
    // MARK: - Calendar Creation and Sharing
    func createSharedCalendar(name: String, completion: @escaping (Result<EKCalendar, Error>) -> Void) {
        guard hasCalendarPermission else {
            completion(.failure(CalendarError.noPermission))
            return
        }
        
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = name
        calendar.cgColor = UIColor.systemBlue.cgColor
        
        // Use the default source (usually iCloud)
        if let source = eventStore.defaultCalendarForNewEvents?.source {
            calendar.source = source
        } else if let source = eventStore.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = source
        } else {
            completion(.failure(CalendarError.noValidSource))
            return
        }
        
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            completion(.success(calendar))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getAvailableCalendars() -> [EKCalendar] {
        guard hasCalendarPermission else { return [] }
        return eventStore.calendars(for: .event)
    }
    
    // MARK: - Export Functionality
    func exportCalendarEvents(_ events: [CalendarEvent]) -> String {
        var icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//ScheduleShare//EN
        
        """
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        for event in events {
            let startDateString = formatter.string(from: event.startDate)
            let endDateString = formatter.string(from: event.endDate)
            let uid = UUID().uuidString
            
            icsContent += """
            BEGIN:VEVENT
            UID:\(uid)
            DTSTART:\(startDateString)
            DTEND:\(endDateString)
            SUMMARY:\(event.title)
            """
            
            if let location = event.location {
                icsContent += "\nLOCATION:\(location)"
            }
            
            if let notes = event.notes {
                icsContent += "\nDESCRIPTION:\(notes)"
            }
            
            icsContent += "\nEND:VEVENT\n"
        }
        
        icsContent += "END:VCALENDAR"
        return icsContent
    }
}

// MARK: - Error Types
enum CalendarError: Error, LocalizedError {
    case noPermission
    case eventNotFound
    case noValidSource
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .noPermission:
            return "Calendar permission is required"
        case .eventNotFound:
            return "Event not found"
        case .noValidSource:
            return "No valid calendar source available"
        case .saveFailed:
            return "Failed to save calendar event"
        }
    }
}