# ScheduleShare - Smart Calendar from Screenshots

A powerful iOS app that automatically extracts event information from screenshots and adds them to your calendar. Built with SwiftUI and powered by iOS Vision framework.

## Features

### 🔍 Smart Text Extraction
- **OCR Technology**: Uses iOS Vision framework for accurate text recognition
- **AI Processing**: Intelligently parses dates, times, and locations from extracted text
- **High Confidence**: Shows extraction confidence percentage

### 📅 Seamless Calendar Integration
- **Auto-Save**: Automatically saves events to your iOS calendar
- **EventKit Integration**: Full integration with iOS Calendar app
- **Edit & Refine**: Review and edit extracted information before saving

### 📱 Easy Sharing
- **Multiple Formats**: Share as ICS files, via email, or text messages
- **Friend-Friendly**: Easy calendar sharing with friends and colleagues
- **Export Options**: Export all events or individual calendars

### 📸 Flexible Input
- **Camera Capture**: Take new photos of event information
- **Photo Library**: Select existing screenshots from your library
- **Smart Recognition**: Works with various event formats and layouts

## How It Works

1. **Capture**: Take a photo or select a screenshot containing event information
2. **Extract**: The app uses OCR to extract text from the image
3. **Parse**: AI algorithms identify dates, times, locations, and event titles
4. **Review**: Edit and refine the extracted information
5. **Save**: Add the event to your calendar with one tap
6. **Share**: Easily share your calendar with friends

## App Structure

### Main Components

- **Event Creation View**: Primary interface for capturing and processing screenshots
- **Calendar View**: Display and manage your events with a visual calendar
- **Settings**: Manage permissions, export data, and app information

### Core Technologies

- **SwiftUI**: Modern iOS UI framework
- **Vision Framework**: Apple's OCR and image analysis
- **EventKit**: iOS calendar integration
- **Natural Language**: Text processing and analysis
- **MessageUI**: Email and message sharing

## Setup Requirements

### Permissions Required
The app requires the following permissions (add to Info.plist):

```xml
<key>NSCameraUsageDescription</key>
<string>ScheduleShare needs camera access to capture event information.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>ScheduleShare needs photo library access to select screenshots.</string>

<key>NSCalendarsUsageDescription</key>
<string>ScheduleShare needs calendar access to save events.</string>
```

### iOS Version
- Minimum iOS 14.0
- Optimized for iOS 15.0+

## File Structure

```
ScheduleShare/
├── Models.swift                    # Data models and app state
├── TextExtractor.swift            # OCR and text parsing logic
├── ImagePicker.swift              # Camera and photo library integration
├── CalendarManager.swift          # EventKit calendar integration
├── SharingManager.swift           # Calendar sharing functionality
├── EventCreationView.swift        # Main event creation interface
├── EventDetailsView.swift         # Event editing and refinement
├── CalendarView.swift             # Calendar display and management
├── EventDetailDisplayView.swift   # Detailed event viewing
├── ContentView.swift              # Main app navigation and settings
└── README.md                      # This file
```

## Key Features in Detail

### Smart Text Recognition
- Recognizes various date formats (MM/DD/YYYY, DD-MM-YYYY, etc.)
- Identifies time patterns (12/24 hour formats)
- Extracts location information (addresses, venue names)
- Handles multiple languages and text orientations

### Calendar Integration
- Creates events in default calendar
- Supports custom calendars
- Maintains event metadata and source images
- Syncs with iCloud and other calendar services

### Sharing Capabilities
- ICS file export for universal calendar compatibility
- Email sharing with formatted event lists
- Message sharing with readable event summaries
- Future: Direct calendar subscription links

## Usage Tips

1. **Best Results**: Use clear, well-lit photos with readable text
2. **Event Formats**: Works best with structured event information (invitations, flyers, etc.)
3. **Review Always**: Always review extracted information before saving
4. **Permissions**: Grant all requested permissions for full functionality

## Future Enhancements

- [ ] Cloud sync for shared calendars
- [ ] Recurring event detection
- [ ] Multi-language support enhancement
- [ ] Integration with other calendar services
- [ ] Batch processing for multiple events

## Development

Built using:
- Xcode 15.0+
- SwiftUI 5.0
- iOS 14.0+ target
- Vision Framework
- EventKit Framework

## Support

For issues or feature requests, the app includes comprehensive error handling and user feedback systems.

---

**ScheduleShare** - Transform your screenshots into organized calendar events! 📅✨