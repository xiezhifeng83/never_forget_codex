# Speckit - Never Forget Codex

Cross-platform todo experience focused on one-keystroke capture and instant status surfaces. The project pairs a Fastify + SQLite backend with a Flutter client for Android and Windows. Both live in this mono-workspace so the specification, docs, and code stay in sync.

## Highlights
- Offline-first sync model with device-scoped queues and timestamp-based last-write-wins.
- Drag-to-reorder list persisted in SQLite and mirrored across devices within a minute.
- Android ongoing notification and Windows system tray menu that surface the top task (refresh on every change and at least every 60s).
- Compact TypeScript + Riverpod codebases with shared specs and architecture notes.

## Layout
- `speckit-todo-backend/` – Fastify REST API, better-sqlite3 persistence, optimistic locking.
- `speckit-todo-client/` – Flutter 3.x app with Riverpod, Hive cache, tray/notification services.
- `docs/` – architecture and performance checklists for the current release.
- `specs/` – end-to-end specification, plans, contracts, and manual verification scripts.

## Prerequisites
- Node.js 20+
- Flutter 3.19+ with Android and Windows targets enabled (`flutter config --enable-windows-desktop`)

## Quick Start

### Backend (Fastify + SQLite)
```bash
cd speckit-todo-backend
npm install
npm run dev            # http://localhost:4000 by default
```

Optional environment variables:

| Var             | Default             | Purpose                  |
|-----------------|---------------------|--------------------------|
| `PORT`          | `4000`              | HTTP port                |
| `HOST`          | `0.0.0.0`           | Bind address             |
| `DATABASE_PATH` | `./data/todos.db`   | SQLite file location     |

### Client (Flutter Android + Windows)
```bash
cd speckit-todo-client
flutter create --platforms=android,windows .
flutter pub get
flutter run --dart-define=BACKEND_URL=http://localhost:4000
```

The client generates a persistent device token, queues offline mutations, and keeps Hive in sync with the backend. Ensure the backend is reachable before running on a device or emulator.

## Development Workflow
- Backend scripts: `npm run dev` (watch mode), `npm run build`, `npm start`, `npm run lint`.
- Lint/Type-check the workspace before pushing:  
  ```bash
  cd speckit-todo-backend
  npm run lint
  ```
- Flutter tooling: `flutter analyze` and `flutter test` from `speckit-todo-client/`.
- See `specs/master/quickstart.md` for manual verification flows and performance targets. Record measurements in `docs/performance-checklist.md`.

## Architecture Notes
- REST endpoints cover list operations (`GET/POST/PUT/DELETE /todos`, `PUT /todos/reorder`, `GET /todos/top`) and expect an `X-Device-Token` header.
- SQLite operates in WAL mode; reorder operations run in a single transaction to keep revisions consistent.
- Riverpod state exposes a `hasPendingMutations` flag so the UI can surface sync status while offline.

For deeper dives, start with:
- `docs/architecture.md` – diagrams, sync loop, and platform surfaces.
- `speckit-todo-backend/README.md` / `speckit-todo-client/README.md` – platform-specific guides.
- `specs/master/` – source planning artifacts and API contracts that drive the builds.

Happy shipping! Keep the top task fresh so you never forget what's next.
