# Implementation Plan: Cross-Platform Todo List

**Branch**: `master` (current) | **Date**: 2025-10-17 | **Spec**: `specs/master/spec.md`

## Summary

Deliver a cross-platform todo solution consisting of:
- Flutter client (Android + Windows) with offline-first capture, reorder, edit, delete
- Persistent system surfaces (Android notification, Windows tray) showing the top task and dropdown list
- Node.js/TypeScript backend providing REST sync with device-token scoping and timestamp-based last-write-wins conflict resolution

Primary priorities:
1. **US1 (P1)** Quick task capture on both platforms
2. **US2 (P1)** System status bar visibility with dropdown list
3. **US3 (P2)** Full task management (view/edit/delete/reorder) with realtime sync

## Technical Context

**Language/Version**: Node.js 20 + TypeScript (backend); Dart 3 / Flutter 3.x (client)  
**Primary Dependencies**: Fastify, better-sqlite3, Zod (backend); Flutter Riverpod, Hive, flutter_local_notifications, system_tray (client)  
**Storage**: SQLite (better-sqlite3) with WAL enabled  
**Testing**: Backend TypeScript type-check (`npm run lint`); manual Flutter verification (automated tests TBD per story)  
**Target Platform**: Backend service; Flutter client targeting Android (mobile) and Windows (desktop)  
**Project Type**: Multi-project repository (Node.js API + Flutter client)  
**Performance Goals**: Status surfaces refresh ≤2s after changes, global refresh ≥1/min, app cold start ≤1s (per spec)  
**Constraints**: Offline-capable with queued sync (FR-013); no tags/search (FR-014); timestamp-driven last-write-wins conflict resolution (FR-015)  
**Scale/Scope**: Single-user per device token; cross-device sync via shared token, high responsiveness emphasis

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The constitution file is currently a placeholder with no explicit mandates. Interim guidance:
- Document assumptions and decisions (research.md already captures key points).
- Ensure each user story delivers an independently testable increment.
- Highlight governance gaps for stakeholder follow-up (tracked here).

No blocking gates identified; proceed with standard repository practices.

## Project Structure

### Documentation (this feature)

```
specs/master/
├── plan.md          # this file
├── research.md      # Phase 0 output
├── data-model.md    # Phase 1 output
├── quickstart.md    # Phase 1 output
└── contracts/       # Phase 1 OpenAPI spec
```

### Source Code (repository root)

```
docs/
└── architecture.md

speckit-todo-backend/
├── package.json
├── src/
│   ├── db.ts
│   ├── errors.ts
│   ├── index.ts
│   ├── routes.ts
│   ├── todoStore.ts
│   └── types.ts

speckit-todo-client/
├── pubspec.yaml
├── lib/
│   ├── app.dart
│   ├── main.dart
│   ├── models/todo.dart
│   ├── data/
│   │   ├── api_client.dart
│   │   ├── local_store.dart
│   │   └── todo_repository.dart
│   ├── services/
│   │   ├── notification_service.dart
│   │   └── tray_service.dart
│   ├── state/todo_controller.dart
│   └── ui/
│       ├── home_screen.dart
│       └── widgets/
│           ├── add_todo_field.dart
│           └── todo_list_tile.dart
└── assets/tray/icon.ico
```

**Structure Decision**: Maintain separate backend and Flutter client projects. Story work will modify files within these directories according to responsibilities (backend sync, client UI/platform services).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| None      | N/A        | N/A                                  |
