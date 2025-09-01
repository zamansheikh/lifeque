# RemindMe - Comprehensive Islamic & Productivity App

A Flutter app built following Clean Architecture principles with BLoC pattern, GoRouter, and dependency injection. RemindMe is your complete companion for Islamic practices, productivity, and task management with advanced features for modern Muslim lifestyle.

## 🌟 Features

### 🕌 Islamic Features
- **Prayer Times**: Accurate prayer times with GPS location support
- **Qibla Direction**: Interactive compass with rotating N,E,S,W markings
- **Prayer Alarms**: Smart alarm system with two modes:
  - Before Prayer End: Alerts 5-20 minutes before prayer time ends
  - Fixed Time: Custom time-based prayer reminders
- **Restricted Times**: Educational information about Makruh (discouraged) prayer times
- **Location-Based**: Automatic location detection with manual override option
- **Multiple Calculation Methods**: Support for various Islamic calculation methods

### 📚 Productivity Features
- **Study Timer**: Pomodoro technique implementation with:
  - Customizable focus sessions (25-30 minutes)
  - Short breaks (5 minutes) and long breaks (15-30 minutes)
  - Cycle tracking with automatic progression
  - Pause/resume functionality
  - Audio alerts for phase transitions
- **Task Management**: Full-featured task system with:
  - Timeline-based organization
  - Progress tracking with visual indicators
  - Start and end date management
  - Status categories (All, Active, Completed)

### 🔔 Smart Notifications
- **Prayer Reminders**: System-level notifications for prayer times
- **Study Session Alerts**: Audio notifications for study phase changes
- **Task Reminders**: Timeline-based task notifications
- **Persistent Notifications**: Non-dismissible important reminders
- **Permission Management**: Guided setup for all notification types

### 🎨 Modern UI/UX
- **Material Design 3**: Latest design system implementation
- **Adaptive Theming**: Dynamic color schemes
- **Intuitive Navigation**: Clean and accessible interface
- **Real-time Updates**: Reactive UI with stream-based updates
- **Visual Feedback**: Progress bars, status indicators, and animations

## 🏗️ Architecture

This app follows **Clean Architecture** principles with advanced state management:

### Domain Layer
- **Entities**: Task, Prayer, StudySession entities with business logic
- **Repositories**: Abstract interfaces for data access across all features
- **Use Cases**: Comprehensive business logic operations

### Data Layer
- **Models**: Data models with JSON serialization
- **Data Sources**: SQLite for tasks, SharedPreferences for settings
- **Services**: Location services, alarm services, prayer calculation services
- **Repository Implementations**: Concrete implementations for all domains

### Presentation Layer
- **BLoC Pattern**: State management across all features
- **Pages**: Specialized pages for each feature domain
- **Widgets**: Highly reusable and composable UI components
- **Services**: UI-level services for notifications and permissions

## 🛠️ Tech Stack

### Core Framework
- **Flutter**: Cross-platform mobile development
- **Dart**: Modern programming language

### State Management & Architecture
- **flutter_bloc**: Reactive state management
- **get_it**: Dependency injection container
- **injectable**: Code generation for DI
- **equatable**: Value equality for state management

### Navigation & Routing
- **go_router**: Declarative routing system

### Data & Storage
- **sqflite**: Local database for tasks
- **shared_preferences**: Settings and preferences storage
- **json_annotation**: JSON serialization

### Islamic Features
- **adhan**: Accurate prayer time calculations
- **geolocator**: GPS location services
- **flutter_compass**: Compass and magnetic direction

### Notifications & Alarms
- **alarm**: System-level alarm scheduling
- **flutter_local_notifications**: Local notification system
- **permission_handler**: Runtime permission management

### Productivity & Time
- **timezone**: Comprehensive timezone handling
- **intl**: Internationalization and date formatting

### UI & Visualization
- **fl_chart**: Data visualization and charts
- **table_calendar**: Calendar widgets

### Utilities
- **uuid**: Unique identifier generation
- **dartz**: Functional programming utilities
- **http**: Network requests
- **url_launcher**: External app integration
- **package_info_plus**: App information
- **device_info_plus**: Device information

## 📱 Project Structure

```
lib/
├── core/
│   ├── services/
│   │   ├── prayer_alarm_service.dart    # Prayer alarm management
│   │   └── notification_service.dart    # Notification handling
│   ├── utils/
│   │   ├── salah_time_calculator.dart   # Prayer time calculations
│   │   └── database_helper.dart         # Database operations
│   ├── constants/                       # App-wide constants
│   └── error/                          # Error handling
├── features/
│   ├── tasks/
│   │   ├── data/                       # Task data layer
│   │   ├── domain/                     # Task business logic
│   │   └── presentation/               # Task UI components
│   ├── prayer_times/
│   │   ├── data/                       # Prayer data services
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── prayer_times_page.dart
│   │   │   │   └── prayer_alarm_page.dart
│   │   │   └── widgets/                # Prayer UI widgets
│   │   └── utils/                      # Prayer utilities
│   ├── study/
│   │   ├── services/
│   │   │   └── study_timer_service.dart # Pomodoro implementation
│   │   └── presentation/
│   │       └── pages/
│   │           └── study_timer_page.dart
│   ├── notifications/                  # Notification management
│   └── permissions/                    # Permission handling
├── injection_container.dart            # Dependency injection
└── main.dart                          # App entry point
```

## 🚀 Key Features Explained

### Prayer Time System
- **Accurate Calculations**: Uses multiple Islamic calculation methods
- **GPS Integration**: Automatic location detection with fallback options
- **Background Updates**: Smart location updates without blocking UI
- **Fast Loading**: Cached data for immediate display
- **Multiple Methods**: Karachi, ISNA, MWL, and other calculation methods

### Qibla Compass
- **True North Alignment**: Accurate compass with magnetic declination
- **Visual Markers**: Rotating N,E,S,W markings for proper orientation
- **Real-time Updates**: Continuous compass readings
- **GPS-based Direction**: Precise Qibla calculation from current location

### Prayer Alarm System
- **Dual Mode Operation**:
  - **Smart Timing**: Alerts before prayer time window ends
  - **Fixed Scheduling**: Custom time-based reminders
- **Individual Controls**: Per-prayer enable/disable switches
- **Global Management**: Master switch for all prayer alarms
- **Persistent Storage**: Settings saved across app restarts
- **System Integration**: Uses Android/iOS alarm system for reliability

### Study Timer (Pomodoro)
- **Customizable Sessions**: Adjustable focus and break durations
- **Automatic Progression**: Seamless transitions between phases
- **Cycle Tracking**: Visual indication of completed cycles
- **Audio Feedback**: Sound alerts for phase changes
- **Pause/Resume**: Full control over session flow
- **Settings Persistence**: Saves preferences and session state

### Restricted Prayer Times
- **Educational Content**: Information about Makruh times in Islam
- **Visual Indicators**: Clear marking of discouraged prayer periods
- **Time Calculations**: Accurate sunrise/sunset based restrictions
- **Islamic Guidance**: Educational tooltips and explanations

## 📱 Getting Started

### Prerequisites
- Flutter SDK (3.10.0-75.1.beta or higher)
- Android Studio / VS Code with Flutter extensions
- Android SDK for Android development
- Xcode for iOS development (macOS only)

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/zamansheikh/remindme.git
cd remindme
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Generate model code:**
```bash
dart run build_runner build
```

4. **Run the app:**
```bash
flutter run
```

### Building

**Android Debug APK:**
```bash
flutter build apk --debug
```

**Android Release APK:**
```bash
flutter build apk --release
```

**iOS (macOS only):**
```bash
flutter build ios --release
```

## 🔐 Permissions

### Android Permissions
- `INTERNET`: Network access for location services
- `ACCESS_FINE_LOCATION`: GPS location for prayer times
- `ACCESS_COARSE_LOCATION`: Network-based location fallback
- `WAKE_LOCK`: Keep device awake for alarms
- `RECEIVE_BOOT_COMPLETED`: Restart alarms after device reboot
- `VIBRATE`: Alarm vibration
- `POST_NOTIFICATIONS`: Android 13+ notification permission
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: Battery optimization exclusion
- `SCHEDULE_EXACT_ALARM`: Precise alarm scheduling
- `USE_EXACT_ALARM`: Exact alarm usage
- `FOREGROUND_SERVICE`: Background alarm services

### iOS Permissions
- `NSLocationWhenInUseUsageDescription`: Location access for prayer times
- `NSMicrophoneUsageDescription`: Audio feedback for study timer
- `NSUserNotificationsUsageDescription`: Local notifications

## 🌙 Islamic Accuracy

### Prayer Time Calculations
- **Multiple Methods**: Karachi, ISNA, Muslim World League, and more
- **Madhab Support**: Hanafi and Shafi calculation differences
- **High Precision**: Accurate to the minute based on geographic location
- **Seasonal Adjustments**: Automatic handling of daylight saving time

### Qibla Direction
- **Great Circle Calculation**: Most accurate method for long distances
- **Magnetic Declination**: Compensation for magnetic vs true north
- **Real-time Updates**: Continuous recalculation as device moves

## 🧪 Testing

**Run all tests:**
```bash
flutter test
```

**Run specific test:**
```bash
flutter test test/prayer_alarm_service_test.dart
```

**Test Coverage:**
- Unit tests for core business logic
- Widget tests for UI components
- Integration tests for feature workflows

## 🚀 CI/CD

GitHub Actions workflow automatically:
- Builds release APK on push to main
- Creates GitHub releases with auto-generated notes
- Uploads APK artifacts
- Increments build numbers

## 🔮 Future Enhancements

### Islamic Features
- [ ] Hijri calendar integration
- [ ] Dhikr counter with customizable adhkar
- [ ] Islamic event notifications
- [ ] Mosque finder with directions
- [ ] Tafsir integration for Quranic verses

### Productivity Features
- [ ] Habit tracking system
- [ ] Goal setting and achievement
- [ ] Time analytics and reports
- [ ] Focus session statistics
- [ ] Task categories and tags

### Technical Improvements
- [ ] Cloud synchronization
- [ ] Multi-language support (Arabic, English, etc.)
- [ ] Dark theme with multiple variants
- [ ] Widget support for quick access
- [ ] Voice commands and accessibility
- [ ] Smart watch integration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing Islamic feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow clean architecture principles
- Write comprehensive tests for new features
- Ensure Islamic accuracy for religious features
- Maintain Material Design 3 consistency
- Document all public APIs

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Islamic Calculation Libraries**: Adhan library for accurate prayer times
- **Flutter Community**: Amazing packages and continuous support
- **Material Design 3**: Google's design system
- **Islamic Scholars**: For guidance on Islamic timing calculations
- **Open Source Contributors**: Everyone who helps make this project better

## 📞 Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/zamansheikh/remindme/issues)
- **Discussions**: [Community discussions and Q&A](https://github.com/zamansheikh/remindme/discussions)

---

**Made with ❤️ for the Muslim community worldwide**
