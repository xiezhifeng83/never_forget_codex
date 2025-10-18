## Speckit Todo Client

Flutter app for Android and Windows that mirrors the backend list, supports drag-to-reorder, and keeps the system tray/notification shade up to date.

### Prerequisites

1. Install Flutter 3.19+ with Android and Windows targets enabled.
2. From the client directory, generate platform scaffolding once:
   ```bash
   flutter create --platforms=android,windows .
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```

> Enable Windows support with `flutter config --enable-windows-desktop` if necessary.

### Run

Ensure the backend is running (default `http://localhost:4000`) and launch:

```bash
flutter run --dart-define=BACKEND_URL=http://localhost:4000
```

### Features

- Inline text field to add todos with a single action.
- Tap to rename, press the trash icon to delete.
- Drag the handle to reorder; the new order is saved immediately.
- Android: ongoing notification shows the first todo and up to 15 items in the inbox body.
- Windows: tray icon menu lists up to 15 todos and focuses the main window on click.
- List refreshes from the backend every minute and pushes local changes instantly.

### Layout

```
lib/
 |- app.dart            # Theme + MaterialApp
 |- main.dart           # Bootstrap + providers
 |- models/todo.dart    # Shared model
 |- data/               # API + cache repository
 |- services/           # Notifications + tray integration
 |- state/              # Riverpod controller
 \- ui/                 # Screens and widgets
assets/
 \- tray/icon.ico       # Windows tray icon
```
