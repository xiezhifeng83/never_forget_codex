## Speckit Todo Backend

Fastify + SQLite service that keeps the Android/Windows clients in sync with optimistic locking and drag-to-reorder support.

### Quick start

1. Install Node.js 20+
2. Install dependencies
   ```bash
   npm install
   ```
3. Start the dev server (defaults to `http://localhost:4000`)
   ```bash
   npm run dev
   ```

Environment variables:

| Name             | Default | Purpose                      |
| ---------------- | ------- | ---------------------------- |
| `PORT`           | `4000`  | HTTP port                    |
| `HOST`           | `0.0.0.0` | Bind address               |
| `DATABASE_PATH`  | `./data/todos.db` | SQLite file path |

### API

| Method | Path             | Description                                             |
| ------ | ---------------- | ------------------------------------------------------- |
| GET    | `/health`        | Health check                                            |
| GET    | `/todos`         | Fetch all todos, or changes since `?since=<iso8601>`    |
| POST   | `/todos`         | Create a todo (body: `{ "title": "..." }`)              |
| PUT    | `/todos/:id`     | Rename a todo using `{ "title": "...", "revision": n }` |
| PUT    | `/todos/reorder` | Persist drag ordering `{ "orderedIds": ["..."] }`       |
| DELETE | `/todos/:id`     | Soft delete with `?revision=n`                           |
| GET    | `/todos/top`     | Current first todo (ordered by `orderIndex`)            |

Response shape:

```jsonc
{
  "id": "8d8e...",
  "title": "string",
  "orderIndex": 0,
  "createdAt": "ISO8601",
  "updatedAt": "ISO8601",
  "revision": 2,
  "deleted": false
}
```

> Updates and deletes require the latest `revision`. The server returns `409 Conflict` when the optimistic lock fails.

### Notes

- SQLite uses WAL mode for durability; data lives under `./data/` by default.
- Reordering updates every affected todo (order index + revision) in a single transaction.
- `npm run build` emits an ES module bundle in `dist/` for production hosting.
