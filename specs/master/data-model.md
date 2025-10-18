# Data Model

## Entities

### Todo
| Field        | Type     | Description                                       | Constraints                          |
|--------------|----------|---------------------------------------------------|--------------------------------------|
| `id`         | UUID     | Server-generated identifier                       | Primary key                          |
| `title`      | string   | Task text                                         | Required, 1–140 characters           |
| `orderIndex` | integer  | 0-based position for ordering                     | Non-negative, unique per device list |
| `createdAt`  | datetime | ISO-8601 timestamp when created                   | Immutable                            |
| `updatedAt`  | datetime | ISO-8601 timestamp of last mutation               | Updated on every change              |
| `revision`   | integer  | Legacy optimistic-lock counter                     | Incremented on update/delete/reorder |
| `lastWriteAt`| datetime | Client-provided timestamp used for LWW resolution  | Required on every mutation           |
| `deleted`    | boolean  | Soft delete flag                                  | `true` represents tombstone          |
| `deviceToken`| string   | Unique token identifying the device/task owner    | Required for scoping/sync            |

### Relationships
- Tasks are scoped per `deviceToken`. Sharing across devices requires out-of-band exchange of the token.
- Backend exposes a single logical list per device; no cross-device aggregation in this release.
- Last-write-wins uses `lastWriteAt` to decide winning mutations; `revision` remains for backward compatibility until migrations complete.

### State Transitions
1. **Create**: Client POST `/todos` with `title`; backend assigns `id`, appends to list, returns todo.
2. **Update (rename)**: Client PUT `/todos/{id}` with `title`, `revision`, and `lastWriteAt`; backend updates `updatedAt`, increments `revision`, and persists the timestamp.
3. **Reorder**: Client PUT `/todos/reorder` with ordered `id` list and shared `lastWriteAt`; backend rewrites `orderIndex`, increments `revision`, and stores the timestamp on affected todos.
4. **Delete**: Client DELETE `/todos/{id}?revision=&lastWriteAt=`; backend marks `deleted = true`, increments `revision`, and records the timestamp.
5. **Sync**: Client polls `/todos?since=` to receive changed todos (including tombstones), merges locally, triggers notification/tray refresh.

### Validation Notes
- Title length upper bound ensures UI fits across platforms (spec assumptions).
- Device token must persist locally (FR-016) and be attached to all backend requests (implementation detail).
