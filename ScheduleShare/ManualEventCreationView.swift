//
//  ManualEventCreationView.swift
//  ScheduleShare
//
//  Manual event creation view
//

import SwiftUI

struct ManualEventCreationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var calendarManager: CalendarManager
    
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    @State private var eventEndDate = Date().addingTimeInterval(3600) // 1 hour later
    @State private var eventLocation = ""
    @State private var eventNotes = ""
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Create New Event")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enter your event details manually")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Event Title
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "textformat")
                                .foregroundColor(.purple)
                            Text("Event Title")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        TextField("Enter event title", text: $eventTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Date and Time
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.purple)
                            Text("Date & Time")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 12) {
                            DatePicker("Start Date", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                            
                            DatePicker("End Date", selection: $eventEndDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.purple)
                            Text("Location")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        TextField("Enter location (optional)", text: $eventLocation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.purple)
                            Text("Notes")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        TextEditor(text: $eventNotes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    
                    // Create Button
                    Button(action: createEvent) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            Text(isSaving ? "Creating..." : "Create Event")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(eventTitle.isEmpty ? Color.gray : Color.purple)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .disabled(eventTitle.isEmpty || isSaving)
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.purple),
                trailing: Button("Create") {
                    createEvent()
                }
                .foregroundColor(.purple)
                .disabled(eventTitle.isEmpty || isSaving)
            )
        }
        .alert("Event Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func createEvent() {
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
        
        // Create the event
        let event = CalendarEvent(
            title: eventTitle,
            startDate: eventDate,
            endDate: eventEndDate,
            location: eventLocation.isEmpty ? nil : eventLocation,
            notes: eventNotes.isEmpty ? nil : eventNotes,
            extractedInfo: nil
        )
        
        // Save to local storage
        appState.addEvent(event)
        
        // Save to calendar if permission granted
        if calendarManager.hasCalendarPermission {
            calendarManager.saveEvent(event) { result in
                DispatchQueue.main.async {
                    self.isSaving = false
                    
                    switch result {
                    case .success:
                        // No alert needed - user can see the event in calendar
                        self.presentationMode.wrappedValue.dismiss()
                        
                    case .failure(let error):
                        self.alertMessage = "Event saved locally but failed to save to calendar: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }
        } else {
            // Just save locally
            DispatchQueue.main.async {
                self.isSaving = false
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    ManualEventCreationView()
        .environmentObject(AppState())
        .environmentObject(CalendarManager())
} 