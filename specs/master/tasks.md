# Tasks: Cross-Platform Todo List

**Input**: Design documents from `/specs/master/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: No automated tests requested; rely on independent story verification steps from the specification.

**Organization**: Tasks are grouped by phase, then by user story to keep increments independently testable.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare shared services and dependencies required by all user stories.

- [X] T001 Add `connectivity_plus` dependency in speckit-todo-client/pubspec.yaml for network status monitoring
- [X] T002 Scaffold connectivity service in speckit-todo-client/lib/services/connectivity_service.dart to broadcast online/offline events

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before any user story work.

- [X] T003 Add `device_token` column and indexes in speckit-todo-backend/src/db.ts to scope todos per device
- [X] T004 Update device scoping in speckit-todo-backend/src/types.ts and speckit-todo-backend/src/todoStore.ts to carry `deviceToken` through DTOs and queries
- [X] T005 Enforce `X-Device-Token` header in speckit-todo-backend/src/routes.ts and propagate token into all store calls
- [X] T006 Document required `X-Device-Token` header across endpoints in specs/master/contracts/api.yaml
- [X] T007 Create persistent token manager in speckit-todo-client/lib/data/device_token_store.dart that generates and caches a random device token
- [X] T008 Attach device token header to every request in speckit-todo-client/lib/data/api_client.dart
- [X] T009 Create queued mutation store in speckit-todo-client/lib/data/pending_mutation_store.dart for offline operations
- [X] T010 Integrate queued mutation flushing with connectivity changes in speckit-todo-client/lib/data/todo_repository.dart and speckit-todo-client/lib/services/connectivity_service.dart

**Checkpoint**: Device-scoped sync and offline queue infrastructure ready.

---

## Phase 3: User Story 1 - Quick Task Capture (Priority: P1) - MVP

**Goal**: Instantly capture tasks on Android/Windows with an accessible input box and offline queueing.

**Independent Test**: Launch the app, add a task via the top input, confirm it appears within 1 second, and ensure the task syncs automatically once connectivity is available.

- [X] T011 [US1] Extend create flow in speckit-todo-client/lib/data/todo_repository.dart to assign local order indexes, enqueue offline creates, and flush on reconnect
- [X] T012 [US1] Update add workflow in speckit-todo-client/lib/state/todo_controller.dart to optimistically append tasks, trigger sync, and surface offline queue state
- [X] T013 [P] [US1] Enable autofocus and single-key submit in speckit-todo-client/lib/ui/widgets/add_todo_field.dart
- [X] T014 [P] [US1] Ensure home screen auto-focuses the add field and scrolls to the latest task in speckit-todo-client/lib/ui/home_screen.dart

**Checkpoint**: Quick capture works online/offline and tasks sync without manual steps.

---

## Phase 4: User Story 2 - Status Bar Quick Access (Priority: P1)

**Goal**: Keep the most important task visible in the system status bar and show a dropdown list (<=15 items) on click.

**Independent Test**: With tasks present, verify the status bar shows the top task while the app runs in the background, click the status icon to open a dropdown of up to 15 tasks, and confirm updates propagate within 2 seconds and at least every minute.

- [X] T015 [P] [US2] Enhance Android notification handling in speckit-todo-client/lib/services/notification_service.dart to open the app on tap, refresh on a 60-second interval, and cap inbox lines at 15
- [X] T016 [P] [US2] Improve Windows tray interactions in speckit-todo-client/lib/services/tray_service.dart to toggle the dropdown on icon click, truncate to 15 tasks, collapse on focus loss, and refresh every 60 seconds
- [X] T017 [US2] Trigger immediate status-surface refreshes after mutations and queue flushes in speckit-todo-client/lib/state/todo_controller.dart

**Checkpoint**: Status bar surfaces stay accurate and interactive across platforms.

---

## Phase 5: User Story 3 - Task Management (Priority: P2)

**Goal**: Allow users to edit text inline, delete tasks, and reorder via drag with reliable sync and offline support.

**Independent Test**: Create several tasks, edit one inline, delete another, drag tasks to reorder, and confirm all changes persist locally, sync to backend, and propagate to another device within 1 minute.

- [X] T018 [US3] Extend speckit-todo-client/lib/data/pending_mutation_store.dart to persist update/delete/reorder payloads with client timestamps
- [X] T019 [US3] Queue and apply optimistic update/delete/reorder operations in speckit-todo-client/lib/data/todo_repository.dart using last-write timestamp metadata
- [X] T020 [US3] Accept client `lastWriteAt` timestamps and apply last-write-wins in speckit-todo-backend/src/routes.ts, speckit-todo-backend/src/todoStore.ts, and specs/master/contracts/api.yaml
- [X] T021 [US3] Implement inline edit mode and confirm prompts in speckit-todo-client/lib/ui/widgets/todo_list_tile.dart and related controller hooks
- [X] T022 [US3] Ensure reorder actions update local order, enqueue offline operations, and refresh surfaces in speckit-todo-client/lib/state/todo_controller.dart
- [X] T025 [US3] Schedule background fetch every 60 seconds and on-demand post-mutation in speckit-todo-client/lib/data/todo_repository.dart to satisfy cross-device sync timing

**Checkpoint**: Full task management loop works online/offline with consistent sync.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final documentation and validation across stories.

- [X] T023 Document device-token flow, offline queue, and status-bar behaviour in docs/architecture.md
- [X] T024 Update specs/master/quickstart.md with manual verification steps for US1-US3 and performance checks (SC-001/SC-008/SC-009)
- [X] T026 Capture launch-to-task and dropdown load timings, recording results in docs/performance-checklist.md

---

## Dependencies & Execution Order

- **Phase order**: Setup -> Foundational -> User Stories (US1 & US2 can run in parallel after foundation) -> User Story 3 -> Polish
- **User stories**:
  - US1 (P1) depends on Foundational completion.
  - US2 (P1) depends on Foundational completion; may proceed alongside US1 once shared infrastructure is done.
  - US3 (P2) depends on Foundational tasks plus US1 queue work to avoid duplication.
- **Backend updates** (T003-T006, T020) should complete before client stories that rely on scoped tokens or timestamp logic.
- **Queue infrastructure** (T009-T010) must complete before any user story touches offline flows.

## Parallel Opportunities

- [P] T013 and [P] T014 (US1 UI improvements) can run concurrently after T012.
- [P] T015 and [P] T016 (US2 platform-specific surfaces) can proceed in parallel.
- Tasks on different layers (backend vs client) within Foundational (e.g., T003/T004 vs T007/T008) can be split across developers once shared APIs are defined.

## Task Counts

- **Total tasks**: 26
- **User Story 1 tasks**: 4
- **User Story 2 tasks**: 3
- **User Story 3 tasks**: 6

## Independent Test Criteria

- **US1**: Launch -> add task -> appears within 1s -> goes to backend after reconnect.
- **US2**: Background app -> status bar shows top task -> click icon -> dropdown <=15 tasks -> updates within 2s and on 60s cadence.
- **US3**: Edit/delete/reorder tasks -> all changes persist locally and sync cross-device within 1 minute.

## MVP Scope

- Deliver Phase 1-3 (Setup, Foundational, US1) for the initial MVP. This enables fast capture with offline support and provides baseline sync infrastructure for later stories.

## Implementation Strategy

1. Complete Setup and Foundational phases to establish device scoping, queue infrastructure, and connectivity awareness.
2. Deliver US1 as MVP; validate capture flow end-to-end (online/offline).
3. Layer in US2 to expose tasks via system surfaces.
4. Finish with US3 for full management capabilities.
5. Polish documentation and manual verification steps before release.





