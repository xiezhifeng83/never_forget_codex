# Speckit Todo App Architecture

## Guiding Principles
- Implement only required capabilities: view, add, edit, delete, reorder.
- Surface the highest-priority todo everywhere (Android notification, Windows tray).
- Keep the codebase compact and explicit; avoid extra metadata or premature abstractions.

## High-Level Overview
```
+----------------------+       +----------------------+
|  Flutter Client      | <---> |  Sync REST API       |
|  (Android, Windows)  |       |  (Node.js + SQLite)  |
+----------------------+       +----------------------+
         ^                                 ^
         |                                 |
         |                         SQLite persistence
         |                         optimistic locking
         |
  System tray / ongoing notification
```

### Backend
- **Runtime**: Node.js 20 + Fastify + better-sqlite3.
- **Data Model**: Todos persist `id`, `title`, `order_index`, `device_token`, `created_at`, `updated_at`, `last_write_at`, `revision`, and `deleted`.
- **Sync Model**:
  - Each device presents an `X-Device-Token` header; todos are scoped per token.
  - Mutations carry a client `lastWriteAt` timestamp; the server applies timestamp-based last-write-wins while retaining `revision` for conflict signalling.
  - Clients fetch all entries on first run, then poll `/todos?since=<timestamp>` for incremental updates (including tombstones).
- **Endpoints**:
  - `GET /todos?since=<iso>` -> incremental or full list filtered by device token.
  - `POST /todos` -> create (server assigns order tail if not supplied).
  - `PUT /todos/:id` -> rename/update with optimistic timestamp check.
  - `DELETE /todos/:id` -> soft delete (keeps tombstones for sync).
  - `PUT /todos/reorder` -> persist ordering for supplied ids.
  - `GET /todos/top` -> resolve the first active todo for the device.

### Client
- **Stack**: Flutter 3.x + Riverpod + http + Hive.
- **Local Cache & Offline Queue**:
  - Hive persists todos for instant boot and device-token storage.
  - A pending-mutation store keeps create/update/delete/reorder operations (with `lastWriteAt` metadata) while offline.
  - Connectivity listener flushes queued mutations when the device reconnects.
- **Sync Loop**:
  1. Load cache on startup and emit current todos/status surfaces.
  2. Mutations execute optimistically; when offline they are enqueued and retried via the connectivity watcher.
  3. Background fetch runs at least every 60 seconds (and immediately after mutations) using the `since` cursor to pull remote changes.
- **Status Bar / System Tray**:
  - Android: an ongoing `flutter_local_notifications` channel shows the top task (tap opens the app) with an inbox body limited to 15 items; refreshed after every mutation and on the minute.
  - Windows: `system_tray` exposes a left-click dropdown capped at 15 active tasks and a menu item to reopen the window; also refreshed on mutation and per-minute intervals.
- **UI Layout**:
  - Top-aligned input with autofocus for one-keystroke capture.
  - `ReorderableListView` with inline edit controls and drag handles.
  - Pending-sync indicator propagated via controller state (`hasPendingMutations`).

### Repositories
- `speckit-todo-backend/` and `speckit-todo-client/` are independent git roots kept side-by-side here for convenience.

### Non-Goals
- Priority flags, tags, search, or filters.
- Multi-user collaboration; tokens are exchanged manually between devices.
- Advanced conflict UI beyond timestamp-based last-write-wins.
