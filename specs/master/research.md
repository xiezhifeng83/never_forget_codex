# Research Notes

## Decision: Backend stack – Node.js 20 + TypeScript + Fastify + SQLite
- **Rationale**: `speckit-todo-backend/package.json` specifies Node 20, Fastify, better-sqlite3, and Zod. Existing code (`src/index.ts`, `src/routes.ts`) already exposes REST endpoints with this stack.
- **Alternatives considered**: Switching to Express/NestJS or PostgreSQL would increase effort without delivering value for current scope.

## Decision: Client stack – Flutter (Android + Windows) with Riverpod + Hive
- **Rationale**: `speckit-todo-client/pubspec.yaml` and `lib/` structure confirm Flutter 3, Riverpod, Hive, and platform services (`flutter_local_notifications`, `system_tray`). Reusing this stack ensures parity across supported platforms.
- **Alternatives considered**: Native Android/Windows or React Native were rejected to avoid duplicating effort and diverging from current codebase.

## Decision: Data model continuity
- **Rationale**: Backend `todos` table tracks id, title, order_index, revision, `lastWriteAt`, deleted flag, and timestamps. The client model mirrors these fields so timestamp-based last-write-wins (FR-015) works without extra migration effort.
- **Alternatives considered**: Adding priority/tags was dismissed in line with FR-014 (“no extra features”) until future specs demand it.

## Decision: Offline-first sync with queued mutations
- **Rationale**: Spec mandates offline operation (FR-013) and 60-second refresh cadence. Existing client repository uses Hive for local cache; expanding the pending-mutation queue fits within this design.
- **Alternatives considered**: Forcing online-only behaviour was rejected as it violates success criteria SC-007.

## Decision: Testing strategy
- **Rationale**: Repository currently relies on TypeScript type-checking and manual Flutter testing. Each user story will define independent manual verification per acceptance scenarios; automated tests can be introduced incrementally as the codebase stabilizes.
- **Alternatives considered**: Enforcing full TDD upfront was deferred given time constraints and absent governance directives.
