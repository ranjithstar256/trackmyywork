# TrackMyWork

A Flutter application to track your work progress and time spent on various activities.

## Features

- **Time Tracking**: Track time spent on different activities like work, breaks, and more
- **Custom Activities**: Add custom activities with personalized colors and icons
- **Detailed Reports**: View daily, weekly, monthly, and yearly reports of your time usage
- **Visual Statistics**: See your time distribution with beautiful charts
- **Simple UI**: Clean and intuitive user interface for easy time tracking

## Getting Started

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## How to Use

### Tracking Time

- Click on an activity button (like "Work" or "Break") to start tracking time for that activity
- The active activity will be highlighted and a timer will show your current session duration
- Click on the same activity again or use the STOP button to end the current tracking session

### Adding Custom Activities

- Click the "+" icon in the app bar to add a new activity
- Enter a name, select a color and an icon for your activity
- Save the activity to start tracking time for it

### Viewing Reports

- Click the chart icon in the app bar to view reports
- Switch between daily, weekly, monthly, and yearly views
- See detailed breakdowns of how you spend your time

## Screenshots

(Screenshots will be added soon)

## App Icon

The app uses custom PNG icons for the launcher icons:

1. The app icon files are located in the `assets` folder:
   - `app_icon.png` - Main app icon (1024x1024 resolution)
   - `app_icon_foreground.png` - Foreground icon for adaptive icons on Android (1024x1024 resolution)
2. The app icon has been generated using the `flutter_launcher_icons` package
3. If you want to update the app icon, replace these PNG files and run:
   ```
   dart run flutter_launcher_icons
   ```

## Dependencies

- provider: State management
- shared_preferences: Local data storage
- fl_chart: Data visualization
- intl: Date formatting
- google_fonts: Custom fonts
- uuid: Generating unique IDs
- flutter_background_service: Background processing
- flutter_local_notifications: Notifications for background service
- flutter_svg: SVG rendering

## License

This project is licensed under the MIT License - see the LICENSE file for details.
