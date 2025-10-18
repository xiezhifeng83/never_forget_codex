import Database from 'better-sqlite3';
import { existsSync, mkdirSync } from 'fs';
import { dirname, join } from 'path';

const dbPath =
  process.env.DATABASE_PATH ?? join(process.cwd(), 'data', 'todos.db');
const dir = dirname(dbPath);

if (!existsSync(dir)) {
  mkdirSync(dir, { recursive: true });
}

export const db = new Database(dbPath);

db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS todos (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    device_token TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    last_write_at TEXT NOT NULL,
    revision INTEGER NOT NULL DEFAULT 0,
    deleted INTEGER NOT NULL DEFAULT 0
  );

  CREATE INDEX IF NOT EXISTS idx_todos_updated_at ON todos(updated_at);
  CREATE INDEX IF NOT EXISTS idx_todos_order ON todos(order_index);
  CREATE INDEX IF NOT EXISTS idx_todos_device_token ON todos(device_token);
  CREATE INDEX IF NOT EXISTS idx_todos_device_token_updated_at ON todos(device_token, updated_at);
`);
