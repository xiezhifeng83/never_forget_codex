import { z } from 'zod';

export interface TodoRecord {
  id: string;
  title: string;
  orderIndex: number;
  deviceToken: string;
  createdAt: string;
  updatedAt: string;
  lastWriteAt: string;
  revision: number;
  deleted: number;
}

export interface TodoDTO {
  id: string;
  title: string;
  orderIndex: number;
  deviceToken: string;
  createdAt: string;
  updatedAt: string;
  lastWriteAt: string;
  revision: number;
  deleted: boolean;
}

export const todoCreateSchema = z.object({
  id: z.string().uuid().optional(),
  title: z.string().min(1).max(140),
  lastWriteAt: z.string().datetime().optional()
});

export const todoUpdateSchema = z.object({
  title: z.string().min(1).max(140),
  revision: z.number().int().nonnegative(),
  lastWriteAt: z.string().datetime()
});

export const todoListQuerySchema = z.object({
  since: z.string().datetime().optional()
});

export const deleteQuerySchema = z.object({
  revision: z.coerce.number().int().nonnegative(),
  lastWriteAt: z.string().datetime()
});

export const reorderSchema = z.object({
  orderedIds: z.array(z.string().uuid()).min(1),
  lastWriteAt: z.string().datetime()
});

export function mapRecord(record: TodoRecord): TodoDTO {
  return {
    id: record.id,
    title: record.title,
    orderIndex: record.orderIndex,
    deviceToken: record.deviceToken,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    lastWriteAt: record.lastWriteAt,
    revision: record.revision,
    deleted: record.deleted === 1
  };
}
