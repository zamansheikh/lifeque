# RemindMe - Task Reminder App

A Flutter app built following Clean Architecture principles with BLoC pattern, GoRouter, and dependency injection. RemindMe helps you manage tasks with timeline-based reminders and progress tracking.

## Features

- **Task Management**: Create, edit, and delete tasks with start and end dates
- **Timeline View**: Tasks are automatically sorted by end date
- **Progress Tracking**: Visual progress bars showing time elapsed and days remaining
- **Status Categories**: View tasks by All, Active, and Completed status
- **Smart Notifications**: Schedule reminders with persistent notifications
- **Permission Management**: Guided setup for notifications and battery optimization
- **Clean UI**: Material Design 3 with intuitive navigation

## Architecture

This app follows **Clean Architecture** principles with the following layers:

### Domain Layer
- **Entities**: `Task` entity with business logic
- **Repositories**: Abstract interfaces for data access
- **Use Cases**: Business logic operations (GetAllTasks, AddTask, UpdateTask, etc.)

### Data Layer
- **Models**: Data models with JSON serialization
- **Data Sources**: Local database operations using SQLite
- **Repository Implementations**: Concrete implementations of domain repositories

### Presentation Layer
- **BLoC**: State management using flutter_bloc
- **Pages**: UI screens (TaskListPage, AddEditTaskPage, TaskDetailPage)
- **Widgets**: Reusable UI components (TaskCard, ProgressIndicator)

## Tech Stack

- **Flutter**: Cross-platform mobile development
- **flutter_bloc**: State management
- **go_router**: Navigation and routing
- **get_it**: Dependency injection
- **sqflite**: Local database storage
- **flutter_local_notifications**: Push notifications
- **permission_handler**: Runtime permissions
- **timezone**: Date/time handling
- **equatable**: Value equality
- **json_annotation**: JSON serialization

## Project Structure

```
lib/
├── core/
│   ├── app.dart                 # Main app configuration
│   ├── constants/               # App constants
│   ├── error/                   # Error handling
│   ├── usecases/               # Base use case interface
│   └── utils/                  # Utilities and database helper
├── features/
│   ├── tasks/
│   │   ├── data/
│   │   │   ├── datasources/    # Local data sources
│   │   │   ├── models/         # Data models
│   │   │   └── repositories/   # Repository implementations
│   │   ├── domain/
│   │   │   ├── entities/       # Business entities
│   │   │   ├── repositories/   # Repository interfaces
│   │   │   └── usecases/       # Business use cases
│   │   └── presentation/
│   │       ├── bloc/           # BLoC state management
│   │       ├── pages/          # UI pages
│   │       └── widgets/        # Reusable widgets
│   ├── notifications/          # Notification feature
│   └── permissions/            # Permission handling
├── injection_container.dart    # Dependency injection setup
└── main.dart                   # App entry point
```

## Key Features Explained

### Task Timeline
- Tasks are sorted by end date automatically
- Visual progress indicators show elapsed time vs total duration
- Color-coded status: Active (orange), Overdue (red), Completed (green)

### Progress Calculation
- Progress percentage based on time elapsed between start and end dates
- Days remaining calculation for active tasks
- Overdue detection for tasks past their end date

### Notifications
- Scheduled notifications for task reminders
- Persistent notifications that don't auto-dismiss
- Background task setup for ongoing reminders
- Permission handling for Android 13+ notification requirements

### Database Schema
```sql
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  startDate INTEGER NOT NULL,
  endDate INTEGER NOT NULL,
  isCompleted INTEGER NOT NULL DEFAULT 0,
  isNotificationEnabled INTEGER NOT NULL DEFAULT 1,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER
)
```

## Getting Started

### Prerequisites
- Flutter SDK (3.10.0 or higher)
- Android Studio / VS Code
- Android SDK for Android development

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd remindme
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate model code:
```bash
dart run build_runner build
```

4. Run the app:
```bash
flutter run
```

### Building

For Android debug APK:
```bash
flutter build apk --debug
```

For Android release APK:
```bash
flutter build apk --release
```

## Android Permissions

The app requires the following permissions:

- `INTERNET`: Network access
- `WAKE_LOCK`: Keep device awake for notifications
- `RECEIVE_BOOT_COMPLETED`: Restart notifications after device reboot
- `VIBRATE`: Notification vibration
- `POST_NOTIFICATIONS`: Android 13+ notification permission
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: Battery optimization exclusion
- `SCHEDULE_EXACT_ALARM`: Precise alarm scheduling
- `USE_EXACT_ALARM`: Exact alarm usage

## Future Enhancements

- [ ] Categories and tags for tasks
- [ ] Recurring tasks support
- [ ] Cloud synchronization
- [ ] Dark theme support
- [ ] Export/import functionality
- [ ] Task attachments
- [ ] Collaborative tasks
- [ ] Widget support
- [ ] Voice reminders
- [ ] Integration with calendar apps

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Flutter and the amazing Flutter community packages
- Follows clean architecture principles inspired by Uncle Bob's Clean Architecture
- Material Design 3 for modern UI/UX
