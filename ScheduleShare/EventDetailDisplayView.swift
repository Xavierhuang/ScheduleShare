//
//  EventDetailDisplayView.swift
//  ScheduleShare
//
//  Detailed display view for existing events
//

import SwiftUI

struct EventDetailDisplayView: View {
    @Binding var event: CalendarEvent
    let onUpdate: (CalendarEvent) -> Void
    let onDelete: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingMapOptions = false
    @State private var selectedLocationForMap: String = ""
    
    // Editing fields
    @State private var editTitle: String = ""
    @State private var editDate: Date = Date()
    @State private var editEndDate: Date = Date()
    @State private var editLocation: String = ""
    @State private var editNotes: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Event Title
                    if isEditing {
                        TextField("Event Title", text: $editTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(event.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    // Date and Time
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.purple)
                            Text("Date & Time")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        if isEditing {
                            VStack(spacing: 12) {
                                DatePicker("Start Date", selection: $editDate, displayedComponents: [.date, .hourAndMinute])
                                DatePicker("End Date", selection: $editEndDate, displayedComponents: [.date, .hourAndMinute])
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.purple)
                                        .font(.caption)
                                    Text("Start")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(fullDateFormatter.string(from: event.startDate))
                                        .font(.subheadline)
                                }
                                
                                HStack {
                                    Image(systemName: "clock.badge.checkmark")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("End")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(fullDateFormatter.string(from: event.endDate))
                                        .font(.subheadline)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                        }
                    }
                    
                    // Location
                    if isEditing || event.location != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "location")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                Text("Location")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            if isEditing {
                                TextField("Location", text: $editLocation)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            } else if let location = event.location {
                                HStack {
                                    Image(systemName: "mappin.circle")
                                        .foregroundColor(.purple)
                                        .font(.caption)
                                    Text(location)
                                        .font(.subheadline)
                                    Spacer()
                                    Button(action: {
                                        selectedLocationForMap = location
                                        showingMapOptions = true
                                    }) {
                                        Image(systemName: "map")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                            }
                        }
                    }
                    
                    // Notes
                    if isEditing || event.notes != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "note.text")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                Text("Notes")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            if isEditing {
                                TextEditor(text: $editNotes)
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6))
                                    )
                            } else if let notes = event.notes {
                                HStack(alignment: .top) {
                                    Image(systemName: "text.quote")
                                        .foregroundColor(.purple)
                                        .font(.caption)
                                        .padding(.top, 2)
                                    Text(notes)
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                            }
                        }
                    }
                    
                    // Source Image
                    if let image = event.sourceImage {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                Text("Source Screenshot")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                    

                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Event" : "Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.purple),
                trailing: HStack(spacing: 16) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    } else {
                        Button("Edit") {
                            startEditing()
                        }
                        .foregroundColor(.purple)
                        
                        Button("Delete") {
                            showingDeleteAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            )
        }
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .actionSheet(isPresented: $showingMapOptions) {
            ActionSheet(
                title: Text("Open in Maps"),
                message: Text("Choose your preferred map app"),
                buttons: [
                    .default(Text("Apple Maps")) {
                        openAppleMapsForLocation(selectedLocationForMap)
                    },
                    .default(Text("Google Maps")) {
                        openGoogleMapsForLocation(selectedLocationForMap)
                    },
                    .cancel()
                ]
            )
        }
        .onAppear {
            initializeEditingFields()
        }
    }
    
    // MARK: - Private Methods
    private func initializeEditingFields() {
        editTitle = event.title
        editDate = event.startDate
        editEndDate = event.endDate
        editLocation = event.location ?? ""
        editNotes = event.notes ?? ""
    }
    
    private func startEditing() {
        isEditing = true
    }
    
    private func saveChanges() {
        let updatedEvent = CalendarEvent(
            id: event.id, // Preserve the original ID
            title: editTitle,
            startDate: editDate,
            endDate: editEndDate,
            location: editLocation.isEmpty ? nil : editLocation,
            notes: editNotes.isEmpty ? nil : editNotes,
            sourceImage: event.sourceImage,
            extractedInfo: event.extractedInfo,
            eventIdentifier: event.eventIdentifier
        )
        
        onUpdate(updatedEvent)
        isEditing = false
    }
    
    // MARK: - Formatters
    private var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "America/New_York") // Set to New York timezone
        return formatter
    }
    
    // MARK: - Maps Integration
    private func openGoogleMapsForLocation(_ location: String) {
        // Extract coordinates from location string (simplified)
        let coordinates = extractCoordinatesFromLocation(location)
        let urlString = "https://maps.google.com/?q=\(coordinates.latitude),\(coordinates.longitude)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openAppleMapsForLocation(_ location: String) {
        // Extract coordinates from location string (simplified)
        let coordinates = extractCoordinatesFromLocation(location)
        let urlString = "http://maps.apple.com/?q=\(coordinates.latitude),\(coordinates.longitude)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func extractCoordinatesFromLocation(_ location: String) -> (latitude: Double, longitude: Double) {
        // Try to extract coordinates from location string
        // This is a simplified version - in a real app you'd use geocoding
        if location.contains("Washington Square Park") {
            return (40.7308, -73.9976)
        } else if location.contains("Abingdon Square") {
            return (40.7378, -74.0057)
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

#Preview {
    EventDetailDisplayView(
        event: .constant(CalendarEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date(),
            location: "Conference Room A",
            notes: "Discuss project timeline"
        )),
        onUpdate: { _ in },
        onDelete: { }
    )
}