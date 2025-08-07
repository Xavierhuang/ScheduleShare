# ScheduleShare - AI-Powered Smart Calendar & Event Sharing

## 📱 Overview

ScheduleShare is a revolutionary iOS app that transforms how you manage and share your schedule. Unlike traditional calendar apps, ScheduleShare uses AI to intelligently extract event information from screenshots and provides smart route planning for multiple events in a day.

## ✨ Key Features

### 🤖 AI-Powered Event Extraction
- **Smart Screenshot Processing**: Take a screenshot of any event and let AI extract all details
- **Intelligent Parsing**: Automatically identifies event title, date, time, location, and notes
- **High Accuracy**: Uses GPT-4 for precise information extraction
- **Timezone Aware**: Automatically handles New York timezone for accurate scheduling

### 🗺️ AI Route Planning
- **Multi-Event Optimization**: Plan routes between multiple events in a single day
- **Real-Time Location**: Uses your current location for optimal route calculation
- **Transportation Options**: Suggests best transportation modes (subway, walking, rideshare)
- **Time & Cost Estimates**: Provides realistic travel times and costs
- **Interactive Maps**: Tap locations to open in Google Maps or Apple Maps

### 📅 Smart Calendar Integration
- **Seamless Sync**: Direct integration with iOS Calendar
- **Event Management**: Create, edit, and delete events with ease
- **Visual Calendar**: Beautiful month view with event indicators
- **Real-Time Updates**: Calendar refreshes automatically after changes

### 📤 Advanced Sharing Options
- **Flexible Sharing**: Share single events, today's events, this week, or this month
- **Selective Sharing**: Choose specific events to share with friends
- **Multiple Formats**: Share via email, messages, or calendar links
- **iCal Support**: Generate .ics files for easy calendar import

### 🎨 Modern UI/UX
- **Beautiful Design**: Clean, modern interface with purple accent theme
- **Smooth Animations**: Polished transitions and loading indicators
- **Intuitive Navigation**: Easy-to-use tab-based interface
- **Responsive Layout**: Optimized for all iPhone sizes

## 🚀 Why ScheduleShare is Better

### vs. Google Calendar
- **AI Extraction**: No manual typing - just screenshot and go
- **Route Planning**: Built-in navigation between events
- **Smart Sharing**: More granular control over what to share
- **Privacy**: Local processing with optional cloud features

### vs. Apple Calendar
- **AI-Powered**: Intelligent event extraction from any source
- **Route Optimization**: Plan your day efficiently
- **Enhanced Sharing**: Multiple sharing options and formats
- **Modern Interface**: More intuitive and feature-rich design

### vs. Luma & Meetup.com
- **Personal Focus**: Designed for individual schedule management
- **AI Integration**: Smart extraction and route planning
- **Calendar Sync**: Direct integration with your existing calendar
- **Offline Capable**: Works without internet for basic features

## 🛠️ Technical Features

### AI & Machine Learning
- **OpenAI Integration**: Uses GPT-4 for intelligent text extraction
- **Natural Language Processing**: Understands various event formats
- **Route Optimization**: AI-powered travel planning
- **Context Awareness**: Considers event timing and location

### iOS Integration
- **EventKit Framework**: Native calendar integration
- **CoreLocation**: Real-time location services
- **SwiftUI**: Modern, responsive interface
- **iOS 15+ Support**: Latest iOS features and optimizations

### Data Management
- **Local Storage**: Secure event storage on device
- **Cloud Sync**: Optional iCloud integration
- **Privacy First**: No unnecessary data collection
- **Export Options**: Multiple sharing formats

## 📋 Setup Instructions

### Prerequisites
- iOS 15.0 or later
- iPhone with camera access
- OpenAI API key (for AI features)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Xavierhuang/ScheduleShare.git
   ```

2. Open in Xcode:
   ```bash
   cd ScheduleShare
   open ScheduleShare.xcodeproj
   ```

3. Configure API Keys:
   - Open `ScheduleShare/AITextExtractor.swift`
   - Replace `YOUR_OPENAI_API_KEY_HERE` with your OpenAI API key
   - Open `ScheduleShare/Models.swift`
   - Replace `YOUR_OPENAI_API_KEY_HERE` with your OpenAI API key

4. Build and Run:
   - Select your target device
   - Press Cmd+R to build and run

### Permissions Required
- **Calendar Access**: To read and write events
- **Location Services**: For route planning
- **Camera**: To take screenshots of events
- **Photo Library**: To access saved screenshots

## 🎯 Use Cases

### For Professionals
- **Meeting Management**: Quickly add meetings from screenshots
- **Travel Planning**: Optimize routes between client meetings
- **Event Sharing**: Share conference schedules with colleagues

### For Students
- **Class Scheduling**: Extract class times from screenshots
- **Study Planning**: Plan routes between classes and study sessions
- **Group Projects**: Share schedules with project partners

### For Social Events
- **Party Planning**: Organize multiple events in a day
- **Friend Coordination**: Share event details easily
- **Venue Hopping**: Plan routes between different venues

## 🔧 Architecture

### Core Components
- **AITextExtractor**: Handles AI-powered text extraction
- **AIRoutePlanner**: Manages route planning and optimization
- **CalendarManager**: Handles calendar integration
- **SharingManager**: Manages event sharing functionality
- **Models**: Data structures and state management

### Design Patterns
- **MVVM Architecture**: Clean separation of concerns
- **ObservableObject**: Reactive state management
- **Singleton Pattern**: Shared service management
- **Protocol-Oriented**: Flexible and testable design

## 🚀 Future Enhancements

### Planned Features
- **Multi-Platform Support**: iPad and macOS versions
- **Advanced AI**: More sophisticated route optimization
- **Social Features**: Event discovery and recommendations
- **Analytics**: Schedule insights and optimization suggestions
- **Widgets**: iOS home screen widgets for quick access

### API Integrations
- **Google Maps API**: Enhanced navigation features
- **Weather API**: Weather-aware route planning
- **Public Transit API**: Real-time transit information
- **Rideshare APIs**: Uber/Lyft integration

## 🤝 Contributing

We welcome contributions! Please feel free to submit issues and pull requests.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **OpenAI**: For providing the GPT-4 API
- **Apple**: For EventKit and SwiftUI frameworks
- **SwiftUI Community**: For inspiration and best practices

---

**Made with ❤️ for better schedule management**

*ScheduleShare - Where AI meets your calendar*