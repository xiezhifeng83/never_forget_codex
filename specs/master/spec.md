# Feature Specification: Cross-Platform Todo List

**Feature Branch**: `001-cross-platform-todo`
**Created**: 2025-10-17
**Status**: Draft
**Input**: User description: "只需要支持Android、Windows, 各个平台的app端需要能够正常的查看、添加、删除、修改Todo的功能。此外还需要能够拖动排序, 排序完之后系统状态栏能够及时更新。系统状态栏至少每1分钟更新一次。系统状态栏上需要直接显示第一条需要做的Todo, 点击以后出现下拉列表, 列表里面是所有的todo (最多显示15条), 在各个app上面的操作需要实时保存到后端。除此之外没有提到的功能不需要 (比如标签、搜索等功能) 。"

## Clarifications

### Session 2025-10-17

- Q: User Authentication Strategy - how should users authenticate to sync across devices? → A: No user authentication needed. Each device randomly generates a fixed TOKEN on first launch for backend communication.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Quick Task Capture (Priority: P1)

Users need to quickly capture tasks as they think of them, without navigating through menus or filling out multiple fields. The primary interaction is opening the app and immediately typing a task.

**Why this priority**: This addresses the core friction point in task management - capturing thoughts before they're forgotten. Without quick capture, users will abandon the tool.

**Independent Test**: Can be fully tested by launching the app, adding a new task with just text input, and verifying it appears in the list immediately without requiring sync completion.

**Acceptance Scenarios**:

1. **Given** the app is not running, **When** user launches the app on any platform (Android/Windows), **Then** the app displays the task list with an immediately accessible input field for adding new tasks
2. **Given** user is viewing the task list, **When** user types task text and confirms (Enter/Return/Save), **Then** the task appears at the bottom of the list within 1 second
3. **Given** user has added a task, **When** the app syncs with the backend, **Then** the task is saved to the backend without user intervention
4. **Given** no network connection, **When** user adds a task, **Then** the task is saved locally and queued for sync when connection is restored

---

### User Story 2 - Status Bar Quick Access (Priority: P1)

Users need to see their top priority task at a glance from the system status bar/notification area, without opening the full app. Clicking the status bar item shows a dropdown with up to 15 tasks.

**Why this priority**: This is the core differentiator of this app - persistent visibility of the most important task. Without this, it's just another todo app.

**Independent Test**: Can be fully tested by adding tasks, verifying the first task appears in the status bar, clicking the status bar icon, and seeing the dropdown list appear with the tasks.

**Acceptance Scenarios**:

1. **Given** user has tasks in the list, **When** the app is running in the background, **Then** the system status bar displays the first (top priority) task text
2. **Given** the status bar shows a task, **When** user clicks/taps the status bar icon, **Then** a dropdown appears showing up to 15 tasks in priority order
3. **Given** the dropdown is visible, **When** user clicks outside the dropdown, **Then** the dropdown closes and status bar returns to showing only the top task
4. **Given** tasks are modified in the app, **When** the modification completes, **Then** the status bar updates to reflect the new top task within 2 seconds
5. **Given** the status bar is displaying a task, **When** at least 1 minute has passed, **Then** the status bar refreshes to show the current top task (even if unchanged)

---

### User Story 3 - Task Management (Priority: P2)

Users need to view all their tasks, edit task text, delete completed or irrelevant tasks, and reorder tasks by dragging to reflect changing priorities.

**Why this priority**: Once tasks are captured and visible, users need basic management capabilities. This is lower priority than capture and visibility because users can still capture and see tasks without these operations.

**Independent Test**: Can be fully tested by creating multiple tasks, editing one task's text, deleting another task, and dragging tasks to reorder them, then verifying all changes persist and sync to backend.

**Acceptance Scenarios**:

1. **Given** user is viewing the task list, **When** user selects a task, **Then** the app allows editing the task text inline
2. **Given** user is editing a task, **When** user confirms the edit, **Then** the updated text appears immediately and syncs to backend within 5 seconds
3. **Given** user is viewing the task list, **When** user selects delete/remove on a task, **Then** the task disappears from the list immediately and the deletion syncs to the backend within 5 seconds
4. **Given** user is viewing the task list with multiple tasks, **When** user drags a task to a different position, **Then** the task moves to the new position, all tasks reorder accordingly, and the new order syncs to backend
5. **Given** user has reordered tasks, **When** the new order is saved, **Then** the status bar updates to show the new first task within 2 seconds
6. **Given** user has made changes on one device, **When** another device syncs, **Then** both devices show the same task list and order

---

### User Story 4 - Multi-Platform Consistency (Priority: P2)

Users who work across multiple devices (phone, tablet, desktop) need their task list to stay synchronized across all platforms without manual intervention.

**Why this priority**: Cross-platform sync is a key requirement, but users can still use the app on a single device without it. It's essential for the full experience but not for basic functionality.

**Independent Test**: Can be fully tested by adding a task on Android, verifying it appears on Windows within sync interval, then modifying it on Windows and verifying changes appear on Android.

**Acceptance Scenarios**:

1. **Given** user adds a task on Android, **When** the sync interval completes (within 1 minute), **Then** the task appears on Windows client
2. **Given** user edits a task on Windows, **When** the sync completes, **Then** the updated text appears on Android client
3. **Given** user deletes a task on Android, **When** the sync completes, **Then** the task is removed from Windows client
4. **Given** user reorders tasks on one platform, **When** the sync completes, **Then** all platforms show the same task order
5. **Given** users make conflicting changes on different devices (same task edited differently), **When** both devices sync, **Then** the most recent change wins based on timestamp

---

### Edge Cases

- What happens when user has more than 15 tasks but status bar dropdown only shows 15?
  - Dropdown shows the first 15 tasks in priority order; user must open full app to see remaining tasks

- What happens when user has no tasks?
  - Status bar shows a default message like "No tasks" or the app icon only
  - Dropdown shows "No tasks yet" message with option to add task

- What happens when network is unavailable for extended period?
  - App continues functioning with local data
  - Changes queue locally and sync when connection restores
  - User sees indicator that sync is pending (optional: show last sync time)

- What happens when user tries to drag a task in the dropdown vs. the full app?
  - Drag-to-reorder only works in the full app view, not in the status bar dropdown

- What happens when task text is too long for status bar display?
  - Text is truncated with ellipsis (...) to fit status bar width
  - Full text visible in dropdown and full app

- What happens when multiple devices edit the same task simultaneously?
  - Last-write-wins based on server timestamp
  - No conflict resolution UI needed

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support Android and Windows platforms with native apps for each
- **FR-002**: System MUST allow users to add new tasks with text-only input (no additional fields required)
- **FR-003**: System MUST allow users to view all their tasks in a list within the app
- **FR-004**: System MUST allow users to edit existing task text
- **FR-005**: System MUST allow users to delete tasks from the list
- **FR-006**: System MUST allow users to reorder tasks by dragging within the app interface
- **FR-007**: System MUST display the first (top priority) task in the system status bar/notification area when app is running
- **FR-008**: System MUST show a dropdown list of up to 15 tasks when user clicks the status bar icon
- **FR-009**: System MUST update the status bar display within 2 seconds when task order changes
- **FR-010**: System MUST refresh the status bar display at least once per minute
- **FR-011**: System MUST save all user operations (add, edit, delete, reorder) to the backend server in real-time
- **FR-012**: System MUST sync changes across all user devices automatically
- **FR-013**: System MUST function offline with local storage and queue changes for sync when connection is available
- **FR-014**: System MUST NOT include tags, search, categories, or other features not explicitly specified
- **FR-015**: System MUST resolve sync conflicts using timestamp-based last-write-wins strategy
- **FR-016**: System MUST generate a unique random device token on first launch and persist it locally for all backend communication

### Key Entities

- **Task**: A todo item with text content, creation timestamp, modification timestamp, and position in the ordered list. Each task is associated with a device token and has a unique identifier for sync purposes.

- **Device Token**: A randomly generated unique identifier created on first app launch, used to authenticate all backend requests and group tasks belonging to the same device.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can add a new task in under 3 seconds from launching the app
- **SC-002**: Users can see their top priority task in the status bar without opening the app
- **SC-003**: Status bar updates within 2 seconds after any task reordering operation
- **SC-004**: Status bar refreshes automatically at least once every 60 seconds
- **SC-005**: Changes made on one device appear on other devices within 1 minute during normal network conditions
- **SC-006**: 95% of user operations (add/edit/delete/reorder) complete successfully without errors
- **SC-007**: App remains functional offline with all operations working except cross-device sync
- **SC-008**: Dropdown displays up to 15 tasks and loads within 1 second of clicking status bar icon
- **SC-009**: Task list displays within 1 second of launching the app (cold start)
- **SC-010**: Users can complete the full task management cycle (add → reorder → edit → delete) on each platform without technical assistance

## Assumptions

- Each device operates independently with its own randomly generated token for backend authentication
- Backend sync uses standard REST or GraphQL API (technology to be determined during planning)
- Status bar integration is technically feasible on both platforms (Android notification area, Windows system tray)
- Network availability is intermittent; offline-first design required
- Task text has a reasonable length limit (e.g., 500 characters) to fit UI constraints
- Cross-device task sharing requires manual token sharing between devices (mechanism to be determined during planning)
- No multi-user collaboration features required in this version
- Background sync interval is configurable but defaults to 1 minute or less
