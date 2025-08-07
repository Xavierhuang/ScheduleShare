//
//  EventFormSheet.swift
//  ScheduleShare
//
//  Event form sheet for editing extracted event details
//

import SwiftUI

struct EventFormSheet: View {
    @Binding var eventTitle: String
    @Binding var eventDate: Date
    @Binding var eventEndDate: Date
    @Binding var eventLocation: String
    @Binding var eventNotes: String
    @Binding var isSaving: Bool
    let onCreateEvent: () -> Void
    let onUpdateEvent: ((CalendarEvent) -> Void)? // For updating existing events
    let existingEvent: CalendarEvent? // The event being edited, if any
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.purple.opacity(0.1))
                                    .frame(width: 100, height: 100)
                            )
                        
                        Text("Edit Event Details")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Review and modify the extracted information")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Title")
                                .font(.headline)
                                .fontWeight(.semibold)
                            TextField("Enter event title", text: $eventTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Date and Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start Date & Time")
                                .font(.headline)
                                .fontWeight(.semibold)
                            DatePicker("Start", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("End Date & Time")
                                .font(.headline)
                                .fontWeight(.semibold)
                            DatePicker("End", selection: $eventEndDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                        
                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location (Optional)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            TextField("Enter location", text: $eventLocation)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            TextEditor(text: $eventNotes)
                                .frame(minHeight: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            if let existingEvent = existingEvent {
                                // Update existing event
                                let updatedEvent = CalendarEvent(
                                    id: existingEvent.id, // Preserve the original ID
                                    title: eventTitle,
                                    startDate: eventDate,
                                    endDate: eventEndDate,
                                    location: eventLocation.isEmpty ? nil : eventLocation,
                                    notes: eventNotes.isEmpty ? nil : eventNotes,
                                    sourceImage: nil,
                                    extractedInfo: existingEvent.extractedInfo,
                                    eventIdentifier: existingEvent.eventIdentifier
                                )
                                onUpdateEvent?(updatedEvent)
                            } else {
                                // Create new event
                                onCreateEvent()
                            }
                            presentationMode.wrappedValue.dismiss()
                        }) {
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
                            .cornerRadius(12)
                        }
                        .disabled(eventTitle.isEmpty || isSaving)
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray5))
                                )
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    EventFormSheet(
        eventTitle: .constant("Sample Event"),
        eventDate: .constant(Date()),
        eventEndDate: .constant(Date().addingTimeInterval(3600)),
        eventLocation: .constant("Sample Location"),
        eventNotes: .constant("Sample notes"),
        isSaving: .constant(false),
        onCreateEvent: {},
        onUpdateEvent: { _ in },
        existingEvent: nil
    )
} 