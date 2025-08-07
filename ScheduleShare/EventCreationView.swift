//
//  EventCreationView.swift
//  ScheduleShare
//
//  View for creating events from screenshots with AI extraction
//

import SwiftUI
import UIKit

struct EventCreationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var calendarManager: CalendarManager
    @StateObject private var textExtractor = TextExtractor()
    
    @State private var selectedImage: UIImage?
    @State private var extractedInfo: ExtractedEventInfo?
    @State private var isProcessing = false
    @State private var showingEventDetails = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSaveAlert = false
    @State private var showingEventForm = false
    
    // Event editing fields
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    @State private var eventEndDate = Date().addingTimeInterval(3600) // 1 hour later
    @State private var eventLocation = ""
    @State private var eventNotes = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Save & Share Events")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Extract events from screenshots and share with friends")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // Screenshot-based Extraction
                    VStack(spacing: 16) {
                        // Image Selection
                        ImageSelectionView(selectedImage: $selectedImage)
                            .padding(.horizontal)
                        
                        // Extract Button - Always visible when image is selected
                        if selectedImage != nil {
                            VStack(spacing: 16) {
                                Button(action: processImage) {
                                    HStack(spacing: 12) {
                                        if isProcessing {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "brain.head.profile")
                                                .font(.title2)
                                        }
                                        Text(isProcessing ? "Processing..." : "Extract Event Info")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 24)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(isProcessing ? Color.gray : Color.purple)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                                }
                                .disabled(isProcessing)
                                .scaleEffect(isProcessing ? 0.98 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isProcessing)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                    
                    // Success Message and Edit Button (shown after extraction)
                    if extractedInfo != nil {
                        VStack(spacing: 16) {
                            // Success indicator
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                Text("Event details extracted successfully!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.1))
                            )
                            
                            // Quick preview
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Preview:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(eventTitle.isEmpty ? "Event Title" : eventTitle)
                                        .font(.headline)
                                        .foregroundColor(eventTitle.isEmpty ? .secondary : .primary)
                                    
                                    if !eventLocation.isEmpty {
                                        Text(eventLocation)
                                            .font(.subheadline)
                                            .foregroundColor(.purple)
                                    }
                                    
                                    Text(dateFormatter.string(from: eventDate))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                            }
                            
                            // Action buttons
                            HStack(spacing: 12) {
                                Button(action: {
                                    showingEventForm = true
                                }) {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Edit Details")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.purple)
                                    .cornerRadius(10)
                                }
                                
                                Button(action: createEvent) {
                                    HStack {
                                        if isSaving {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "plus.circle")
                                        }
                                        Text(isSaving ? "Saving..." : "Save Event")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(isSaving ? Color.gray : Color.green)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Calendar Permission
                    if !calendarManager.hasCalendarPermission {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("Calendar Permission Required")
                                    .font(.headline)
                            }
                            Text("To save events to your calendar, please grant permission")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Grant Calendar Permission") {
                                print("🔐 Requesting calendar permission...")
                                calendarManager.requestCalendarPermission()
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingEventForm) {
            EventFormSheet(
                eventTitle: $eventTitle,
                eventDate: $eventDate,
                eventEndDate: $eventEndDate,
                eventLocation: $eventLocation,
                eventNotes: $eventNotes,
                isSaving: $isSaving,
                onCreateEvent: {
                    createEvent()
                    // Force a refresh of the calendar view
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Switch to calendar tab to show the new event
                        // This will trigger the calendar view's onAppear
                    }
                },
                onUpdateEvent: { updatedEvent in
                    appState.updateEvent(updatedEvent)
                },
                existingEvent: nil // This is for creating new events
            )
        }
        .alert("Event Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Private Methods
    private func processImage() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        print("🔄 Starting AI extraction process...")
        
        textExtractor.extractText(from: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    print("📝 OCR completed, starting AI processing...")
                    // Use AI-powered parsing (async)
                    textExtractor.parseEventInfo(from: text) { info in
                        DispatchQueue.main.async {
                            print("🤖 AI processing completed")
                            self.extractedInfo = info
                            self.populateEventFields(from: info)
                            self.isProcessing = false  // Stop spinning after AI completes
                            
                            // No success alert needed - user can see the extracted details on screen
                        }
                    }
                    
                case .failure(let error):
                    print("❌ OCR failed: \(error.localizedDescription)")
                    self.alertMessage = "AI extraction failed: \(error.localizedDescription). Please check your API key and try again."
                    self.showingAlert = true
                    self.isProcessing = false  // Stop spinning on error
                }
            }
        }
    }
    
    private func populateEventFields(from info: ExtractedEventInfo) {
        print("🔍 Populating fields from extracted info:")
        print("🔍 Title: \(info.title ?? "nil")")
        print("🔍 Date: \(info.dateTime?.description ?? "nil")")
        print("🔍 Location: \(info.location ?? "nil")")
        print("🔍 Description: \(info.description ?? "nil")")
        print("🔍 Confidence: \(info.confidence)")
        
        eventTitle = info.title ?? "New Event"
        if let startDate = info.startDateTime {
            // The AI now extracts time in New York timezone directly
            // Just validate and adjust if needed
            let adjustedStartDate = validateAndAdjustDate(startDate)
            eventDate = adjustedStartDate
            
            // Use extracted end time if available, otherwise default to 1 hour later
            if let endDate = info.endDateTime {
                let adjustedEndDate = validateAndAdjustDate(endDate)
                eventEndDate = adjustedEndDate
                print("📅 AI extracted start date (New York time): \(startDate)")
                print("📅 AI extracted end date (New York time): \(endDate)")
                print("📅 Final adjusted start date: \(adjustedStartDate)")
                print("📅 Final adjusted end date: \(adjustedEndDate)")
            } else {
                eventEndDate = adjustedStartDate.addingTimeInterval(3600) // 1 hour later
                print("📅 AI extracted start date (New York time): \(startDate)")
                print("📅 Final adjusted start date: \(adjustedStartDate)")
                print("📅 Using default end time: 1 hour later")
            }
        }
        eventLocation = info.location ?? ""
        eventNotes = info.description ?? ""
        
        print("✅ Fields populated:")
        print("✅ eventTitle: \(eventTitle)")
        print("✅ eventDate: \(eventDate)")
        print("✅ eventLocation: \(eventLocation)")
        print("✅ eventNotes: \(eventNotes)")
    }
    
    private func validateAndAdjustDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Compare only the date part (not time)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let nowComponents = calendar.dateComponents([.year, .month, .day], from: now)
        
        // Create dates with just the date part (time set to 00:00:00)
        guard let dateOnly = calendar.date(from: dateComponents),
              let nowOnly = calendar.date(from: nowComponents) else {
            return date
        }
        
        // If the date is in the past, assume it's for next year
        if dateOnly < nowOnly {
            if let nextYear = calendar.date(byAdding: .year, value: 1, to: date) {
                print("⚠️ Date was in the past, adjusted to next year")
                return nextYear
            }
        }
        
        return date
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "America/New_York") // Set to New York timezone
        return formatter
    }
    
    private func createEvent() {
        print("🎯 createEvent() called")
        print("🔑 Calendar permission: \(calendarManager.hasCalendarPermission)")
        
        guard !eventTitle.isEmpty else {
            alertMessage = "Please enter an event title"
            showingAlert = true
            return
        }
        
        guard eventEndDate > eventDate else {
            alertMessage = "End time must be after start time"
            showingAlert = true
            return
        }
        
        isSaving = true
        print("📝 Creating event with details:")
        print("   Title: \(eventTitle)")
        print("   Start: \(eventDate)")
        print("   End: \(eventEndDate)")
        print("   Location: \(eventLocation)")
        
        // Create the event with extracted info if available
        let event = CalendarEvent(
            title: eventTitle,
            startDate: eventDate,
            endDate: eventEndDate,
            location: eventLocation.isEmpty ? nil : eventLocation,
            notes: eventNotes.isEmpty ? nil : eventNotes,
            sourceImage: selectedImage,
            extractedInfo: extractedInfo
        )
        
        // Save to local storage
        appState.addEvent(event)
        print("📱 Adding event to local storage: \(event.title)")
        
        // Force UI update
        DispatchQueue.main.async {
            // This ensures the UI updates immediately
            print("🔄 Forcing UI update after adding event")
        }
        
        // Save to calendar if permission granted
        if calendarManager.hasCalendarPermission {
            print("✅ Calendar permission granted, saving to calendar...")
            calendarManager.saveEvent(event) { result in
                DispatchQueue.main.async {
                    self.isSaving = false
                    
                    switch result {
                    case .success(let identifier):
                        print("✅ Event saved to calendar with ID: \(identifier)")
                        self.clearForm()
                        
                    case .failure(let error):
                        print("❌ Failed to save to calendar: \(error.localizedDescription)")
                        self.alertMessage = "Event saved locally but failed to save to calendar: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }
        } else {
            print("❌ No calendar permission, saving locally only")
            // Just save locally
            DispatchQueue.main.async {
                self.isSaving = false
                self.clearForm()
            }
        }
    }
    
    private func clearForm() {
        selectedImage = nil
        extractedInfo = nil
        eventTitle = ""
        eventDate = Date()
        eventEndDate = Date().addingTimeInterval(3600)
        eventLocation = ""
        eventNotes = ""
    }
}

#Preview {
    EventCreationView()
}
