## Speckit - Never Forget

Two Git repositories live side by side here:

- `speckit-todo-backend/` - Fastify + SQLite API with optimistic locking and drag-to-reorder support.
- `speckit-todo-client/` - Flutter client (Android + Windows) that shows the lead todo in the notification tray/system tray.
- `docs/architecture.md` - architecture notes aligned with the latest specification.

### Quick tour

```bash
# backend
cd speckit-todo-backend
npm install
npm run dev

# client
cd ../speckit-todo-client
flutter create --platforms=android,windows .
flutter pub get
flutter run --dart-define=BACKEND_URL=http://localhost:4000
```

### Focus

- **Only the required actions**: view, add, edit, delete, reorder.
- **Status surfaces**: Android ongoing notification + Windows tray menu, refreshed on every change and at least once a minute.
- **Straightforward sync**: SQLite store with revisions, incremental polling, and immediate persistence for every user action.

See the nested READMEs for platform-specific details.
