import { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import {
  deleteQuerySchema,
  reorderSchema,
  todoCreateSchema,
  todoListQuerySchema,
  todoUpdateSchema
} from './types.js';
import {
  getTopTodo,
  insertTodo,
  listTodos,
  markDeleted,
  reorderTodos,
  updateTodo
} from './todoStore.js';
import { ConflictError, NotFoundError } from './errors.js';

function requireDeviceToken(
  request: FastifyRequest,
  reply: FastifyReply
): string | undefined {
  const header = request.headers['x-device-token'] ?? request.headers['X-Device-Token'];
  const value = Array.isArray(header) ? header[0] : header;
  if (!value || typeof value !== 'string') {
    reply.status(400).send({ error: 'Missing X-Device-Token header' });
    return undefined;
  }
  return value;
}

export async function registerRoutes(app: FastifyInstance): Promise<void> {
  app.get('/health', async () => ({ status: 'ok' }));

  app.get('/todos', async (request, reply) => {
    const deviceToken = requireDeviceToken(request, reply);
    if (!deviceToken) {
      return;
    }
    const parsed = todoListQuerySchema.safeParse(request.query);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.flatten() });
    }

    const data = listTodos(deviceToken, parsed.data.since);
    return { data };
  });

  app.get('/todos/top', async (request, reply) => {
    const deviceToken = requireDeviceToken(request, reply);
    if (!deviceToken) {
      return;
    }
    const top = getTopTodo(deviceToken);
    if (!top) {
      return reply.status(404).send({ error: 'No todo available' });
    }
    return { data: top };
  });

  app.post('/todos', async (request, reply) => {
    const deviceToken = requireDeviceToken(request, reply);
    if (!deviceToken) {
      return;
    }
    const parsed = todoCreateSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.flatten() });
    }

    const created = insertTodo({
      ...parsed.data,
      deviceToken
    });
    return reply.code(201).send({ data: created });
  });

  app.put<{ Params: { id: string } }>('/todos/:id', async (request, reply) => {
    const deviceToken = requireDeviceToken(request, reply);
    if (!deviceToken) {
      return;
    }
    const parsed = todoUpdateSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.flatten() });
    }

    try {
      const updated = updateTodo(request.params.id, {
        ...parsed.data,
        deviceToken
      });
      return { data: updated };
    } catch (error) {
      if (error instanceof NotFoundError) {
        return reply.status(404).send({ error: error.message });
      }
      if (error instanceof ConflictError) {
        return reply.status(409).send({ error: error.message });
      }
      throw error;
    }
  });

  app.put('/todos/reorder', async (request, reply) => {
    const deviceToken = requireDeviceToken(request, reply);
    if (!deviceToken) {
      return;
    }
    const parsed = reorderSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.flatten() });
    }
    try {
      const updated = reorderTodos(
        deviceToken,
        parsed.data.orderedIds,
        parsed.data.lastWriteAt
      );
      return { data: updated };
    } catch (error) {
      if (error instanceof NotFoundError) {
        return reply.status(404).send({ error: error.message });
      }
      if (error instanceof ConflictError) {
        return reply.status(409).send({ error: error.message });
      }
      throw error;
    }
  });

  app.delete<{ Params: { id: string } }>(
    '/todos/:id',
    async (request, reply) => {
      const deviceToken = requireDeviceToken(request, reply);
      if (!deviceToken) {
        return;
      }
      const parsed = deleteQuerySchema.safeParse(request.query);
      if (!parsed.success) {
        return reply.status(400).send({ error: parsed.error.flatten() });
      }
      try {
        const removed = markDeleted(request.params.id, parsed.data.revision, {
          deviceToken,
          lastWriteAt: parsed.data.lastWriteAt
        });
        return { data: removed };
      } catch (error) {
        if (error instanceof NotFoundError) {
          return reply.status(404).send({ error: error.message });
        }
        if (error instanceof ConflictError) {
          return reply.status(409).send({ error: error.message });
        }
        throw error;
      }
    }
  );
}
