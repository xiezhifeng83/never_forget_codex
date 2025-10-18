import { randomUUID } from 'crypto';
import { db } from './db.js';
import { ConflictError, NotFoundError } from './errors.js';
import { TodoDTO, TodoRecord, mapRecord } from './types.js';

export interface CreateTodoInput {
  id?: string;
  title: string;
  deviceToken: string;
  lastWriteAt?: string;
}

export interface UpdateTodoInput {
  title: string;
  revision: number;
  deviceToken: string;
  lastWriteAt: string;
}

export interface MutationContext {
  deviceToken: string;
  lastWriteAt: string;
}

function fetchById(id: string, deviceToken: string): TodoRecord | undefined {
  const statement = db.prepare('SELECT * FROM todos WHERE id = ? AND device_token = ?');
  return statement.get(id, deviceToken) as TodoRecord | undefined;
}

function nextOrderIndex(deviceToken: string): number {
  const row = db
    .prepare('SELECT IFNULL(MAX(order_index), -1) as maxOrder FROM todos WHERE device_token = ? AND deleted = 0')
    .get(deviceToken) as { maxOrder: number } | undefined;
  const max = row?.maxOrder ?? -1;
  return max + 1;
}

function shouldApplyUpdate(existing: TodoRecord, incoming: string): boolean {
  return new Date(incoming).getTime() >= new Date(existing.lastWriteAt).getTime();
}

export function listTodos(deviceToken: string, since?: string): TodoDTO[] {
  const statement = since
    ? db.prepare(
        'SELECT * FROM todos WHERE device_token = ? AND updated_at > ? ORDER BY updated_at ASC'
      )
    : db.prepare(
        'SELECT * FROM todos WHERE device_token = ? ORDER BY order_index ASC'
      );

  const rows = since
    ? statement.all(deviceToken, since)
    : statement.all(deviceToken);
  return (rows as TodoRecord[]).map(mapRecord);
}

export function getTopTodo(deviceToken: string): TodoDTO | null {
  const row = db
    .prepare(
      `
      SELECT *
      FROM todos
      WHERE device_token = ? AND deleted = 0
      ORDER BY order_index ASC
      LIMIT 1
    `
    )
    .get(deviceToken) as TodoRecord | undefined;

  return row ? mapRecord(row) : null;
}

export function insertTodo(input: CreateTodoInput): TodoDTO {
  const id = input.id ?? randomUUID();
  const createdAt = new Date().toISOString();
  const orderIndex = nextOrderIndex(input.deviceToken);
  const lastWriteAt = input.lastWriteAt ?? createdAt;

  db.prepare(
    `
      INSERT INTO todos (
        id,
        title,
        order_index,
        device_token,
        created_at,
        updated_at,
        last_write_at,
        revision,
        deleted
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0)
    `
  ).run(
    id,
    input.title,
    orderIndex,
    input.deviceToken,
    createdAt,
    lastWriteAt,
    lastWriteAt
  );

  return mapRecord({
    id,
    title: input.title,
    orderIndex,
    deviceToken: input.deviceToken,
    createdAt,
    updatedAt: lastWriteAt,
    lastWriteAt,
    revision: 0,
    deleted: 0
  });
}

export function updateTodo(id: string, input: UpdateTodoInput): TodoDTO {
  const existing = fetchById(id, input.deviceToken);
  if (!existing) {
    throw new NotFoundError('Todo not found');
  }
  if (existing.deleted === 1) {
    throw new NotFoundError('Todo was deleted');
  }
  if (existing.revision !== input.revision) {
    throw new ConflictError('Revision mismatch');
  }
  if (!shouldApplyUpdate(existing, input.lastWriteAt)) {
    return mapRecord(existing);
  }

  const nextRevision = existing.revision + 1;

  db.prepare(
    `
      UPDATE todos
      SET title = ?,
          updated_at = ?,
          last_write_at = ?,
          revision = ?
      WHERE id = ? AND device_token = ?
    `
  ).run(
    input.title,
    input.lastWriteAt,
    input.lastWriteAt,
    nextRevision,
    id,
    input.deviceToken
  );

  return mapRecord({
    ...existing,
    title: input.title,
    updatedAt: input.lastWriteAt,
    lastWriteAt: input.lastWriteAt,
    revision: nextRevision
  });
}

export function markDeleted(
  id: string,
  revision: number,
  context: MutationContext
): TodoDTO {
  const existing = fetchById(id, context.deviceToken);
  if (!existing) {
    throw new NotFoundError('Todo not found');
  }
  if (existing.revision !== revision) {
    throw new ConflictError('Revision mismatch');
  }
  if (!shouldApplyUpdate(existing, context.lastWriteAt)) {
    return mapRecord(existing);
  }

  const nextRevision = existing.revision + 1;

  db.prepare(
    `
      UPDATE todos
      SET deleted = 1,
          updated_at = ?,
          last_write_at = ?,
          revision = ?
      WHERE id = ? AND device_token = ?
    `
  ).run(
    context.lastWriteAt,
    context.lastWriteAt,
    nextRevision,
    id,
    context.deviceToken
  );

  return mapRecord({
    ...existing,
    deleted: 1,
    updatedAt: context.lastWriteAt,
    lastWriteAt: context.lastWriteAt,
    revision: nextRevision
  });
}

export function reorderTodos(
  deviceToken: string,
  orderedIds: string[],
  lastWriteAt: string
): TodoDTO[] {
  const transaction = db.transaction((token: string, ids: string[], writeAt: string) => {
    const current = db
      .prepare(
        'SELECT id FROM todos WHERE device_token = ? AND deleted = 0 ORDER BY order_index ASC'
      )
      .all(token) as { id: string }[];

    const currentIds = new Set(current.map((row) => row.id));
    for (const id of ids) {
      if (!currentIds.has(id)) {
        throw new NotFoundError(`Todo ${id} missing`);
      }
    }
    if (ids.length !== current.length) {
      throw new ConflictError(
        'Reorder payload must include all active todos'
      );
    }

    ids.forEach((id, index) => {
      db.prepare(
        `
            UPDATE todos
            SET order_index = ?,
                updated_at = ?,
                last_write_at = ?,
                revision = revision + 1
            WHERE id = ? AND device_token = ?
          `
      ).run(index, writeAt, writeAt, id, token);
    });

    return db
      .prepare(
        'SELECT * FROM todos WHERE device_token = ? AND deleted = 0 ORDER BY order_index ASC'
      )
      .all(token) as TodoRecord[];
  });

  const rows = transaction(deviceToken, orderedIds, lastWriteAt);
  return rows.map(mapRecord);
}

export function seedStarterTodo(): void {
  // Seeding is handled per device on the client; nothing to do centrally.
}
