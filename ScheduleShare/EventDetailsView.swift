//
//  EventDetailsView.swift
//  ScheduleShare
//
//  Detailed view for editing and saving events
//

import SwiftUI
import UIKit

struct EventDetailsView: View {
    @Binding var title: String
    @Binding var date: Date
    @Binding var location: String
    @Binding var notes: String
    
    let sourceImage: UIImage?
    let extractedInfo: ExtractedEventInfo?
    let onSave: (CalendarEvent) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var endDate = Date()
    @State private var isAllDay = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Details") {
                    HStack {
                        Image(systemName: "text.quote")
                            .foregroundColor(.blue)
                        TextField("Event Title", text: $title)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.blue)
                        TextField("Location (Optional)", text: $location)
                    }
                }
                
                Section("Date & Time") {
                    Toggle("All Day", isOn: $isAllDay)
                    
                    DatePicker("Start Date", selection: $date, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                    
                    if !isAllDay {
                        DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Additional Information") {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.blue)
                            Text("Notes")
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                    }
                }
                
                if let info = extractedInfo {
                    Section("Extracted Information") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Raw Text from Image:")
                                .font(.headline)
                            Text(info.rawText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            
                            HStack {
                                Text("Confidence:")
                                    .fontWeight(.medium)
                                Text("\(Int(info.confidence * 100))%")
                                    .foregroundColor(info.confidence > 0.7 ? .green : info.confidence > 0.4 ? .orange : .red)
                            }
                        }
                    }
                }
                
                if let image = sourceImage {
                    Section("Source Image") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveEvent()
                }
                .fontWeight(.semibold)
                .disabled(title.isEmpty)
            )
        }
        .onAppear {
            setupEndDate()
        }
    }
    
    private func setupEndDate() {
        // Set end date to 1 hour after start date if not already set
        endDate = Calendar.current.date(byAdding: .hour, value: 1, to: date) ?? date
    }
    
    private func saveEvent() {
        let finalEndDate = isAllDay ? Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date : endDate
        
        let event = CalendarEvent(
            title: title,
            startDate: date,
            endDate: finalEndDate,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes,
            extractedInfo: extractedInfo
        )
        
        onSave(event)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    EventDetailsView(
        title: .constant("Sample Event"),
        date: .constant(Date()),
        location: .constant("Conference Room A"),
        notes: .constant("Important meeting"),
        sourceImage: nil,
        extractedInfo: nil
    ) { _ in }
}