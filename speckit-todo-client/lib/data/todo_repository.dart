import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../models/todo.dart';
import 'api_client.dart';
import 'local_store.dart';
import 'pending_mutation_store.dart';
import '../services/connectivity_service.dart';

class TodoRepository {
  TodoRepository({
    required TodoApiClient apiClient,
    required LocalTodoStore localStore,
    required PendingMutationStore pendingStore,
    required ConnectivityService connectivityService,
  })  : _apiClient = apiClient,
        _localStore = localStore,
        _pendingStore = pendingStore,
        _connectivity = connectivityService {
    _connectivitySub = _connectivity.online$.listen((online) {
      if (online) {
        unawaited(flushPendingMutations());
        unawaited(_runBackgroundFetch());
      }
    });
    if (_connectivity.isOnline) {
      unawaited(flushPendingMutations());
      unawaited(_runBackgroundFetch());
    }
    _scheduleBackgroundFetch();
  }

  final TodoApiClient _apiClient;
  final LocalTodoStore _localStore;
  final PendingMutationStore _pendingStore;
  final ConnectivityService _connectivity;

  DateTime? _lastSyncedAt;
  StreamSubscription<bool>? _connectivitySub;
  bool _isFlushing = false;
  final StreamController<void> _changeController =
      StreamController<void>.broadcast();
  Timer? _backgroundTimer;

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _changeController.close();
    _backgroundTimer?.cancel();
  }

  Future<List<Todo>> loadFromCache() async {
    final cached = _localStore.loadAll();
    if (cached.isNotEmpty) {
      cached.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      _lastSyncedAt = cached
          .map((todo) => todo.updatedAt)
          .fold<DateTime>(cached.first.updatedAt, (prev, current) {
        return current.isAfter(prev) ? current : prev;
      });
    }
    return cached;
  }

  Future<List<Todo>> refresh({bool full = false}) async {
    DateTime? since;
    if (!full) since = _lastSyncedAt;
    if (_connectivity.isOnline) {
      await flushPendingMutations();
    }

    final remote = await _apiClient.fetchTodos(since: since);
    for (final todo in remote) {
      if (todo.deleted) {
        await _localStore.remove(todo.id);
      } else {
        await _localStore.upsert(todo);
      }
      _advanceSyncCursor(todo.updatedAt);
    }
    final merged = _localStore.loadAll();
    merged.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return merged;
  }

  Future<Todo?> fetchTopTodo() async {
    try {
      return await _apiClient.fetchTopTodo();
    } on StateError catch (error) {
      if (error.message == 'no-top') {
        return null;
      }
      rethrow;
    }
  }

  Future<Todo> createTodo({required String title}) async {
    final now = DateTime.now().toUtc();
    final lastWriteAt = now.toIso8601String();
    final id = _generateId();
    final deviceToken = await _apiClient.getDeviceToken();
    final orderIndex = _nextOrderIndex();
    final optimistic = Todo(
      id: id,
      title: title,
      orderIndex: orderIndex,
      deviceToken: deviceToken,
      createdAt: now,
      updatedAt: now,
      lastWriteAt: now,
      revision: 0,
      deleted: false,
    );

    if (_connectivity.isOnline) {
      try {
        final created = await _apiClient.createTodo(
          title: title,
          lastWriteAt: lastWriteAt,
          id: id,
        );
        await _localStore.upsert(created);
        _advanceSyncCursor(created.updatedAt);
        _maybeSyncSoon();
        return created;
      } catch (_) {
        // fallback to queue
      }
    }

    await _localStore.upsert(optimistic);
    await _pendingStore.enqueue(
      PendingMutationType.create,
      {
        'id': id,
        'title': title,
      },
      lastWriteAt,
    );
    _advanceSyncCursor(optimistic.updatedAt);
    _maybeSyncSoon();
    if (_connectivity.isOnline) {
      unawaited(flushPendingMutations());
    }
    return optimistic;
  }

  Future<Todo> renameTodo({
    required Todo todo,
    required String nextTitle,
  }) async {
    final now = DateTime.now().toUtc();
    final lastWriteAt = now.toIso8601String();
    final baseRevision = todo.revision;

    if (_connectivity.isOnline) {
      try {
        final updated = await _apiClient.updateTodo(
          id: todo.id,
          title: nextTitle,
          revision: baseRevision,
          lastWriteAt: lastWriteAt,
        );
        await _localStore.upsert(updated);
        _advanceSyncCursor(updated.updatedAt);
        _maybeSyncSoon();
        return updated;
      } catch (_) {
        // fallback to queue
      }
    }

    final optimistic = todo.copyWith(
      title: nextTitle,
      revision: baseRevision + 1,
      updatedAt: now,
      lastWriteAt: now,
    );
    await _localStore.upsert(optimistic);
    await _pendingStore.enqueue(
      PendingMutationType.update,
      {
        'id': todo.id,
        'title': nextTitle,
        'revision': baseRevision,
      },
      lastWriteAt,
    );
    _advanceSyncCursor(optimistic.updatedAt);
    _maybeSyncSoon();
    if (_connectivity.isOnline) {
      unawaited(flushPendingMutations());
    }
    return optimistic;
  }

  Future<void> deleteTodo(Todo todo) async {
    final now = DateTime.now().toUtc();
    final lastWriteAt = now.toIso8601String();
    final baseRevision = todo.revision;

    if (_connectivity.isOnline) {
      try {
        await _apiClient.deleteTodo(todo.id, baseRevision, lastWriteAt);
        await _localStore.remove(todo.id);
        _maybeSyncSoon();
        return;
      } catch (_) {
        // fallback to queue
      }
    }

    await _localStore.remove(todo.id);
    await _pendingStore.enqueue(
      PendingMutationType.delete,
      {
        'id': todo.id,
        'revision': baseRevision,
      },
      lastWriteAt,
    );
    _maybeSyncSoon();
    if (_connectivity.isOnline) {
      unawaited(flushPendingMutations());
    }
  }

  Future<List<Todo>> reorderTodos(List<Todo> ordered) async {
    final now = DateTime.now().toUtc();
    final lastWriteAt = now.toIso8601String();
    final orderedIds = ordered.map((todo) => todo.id).toList();

    if (_connectivity.isOnline) {
      try {
        final updated =
            await _apiClient.reorderTodos(orderedIds, lastWriteAt);
        await _localStore.upsertMany(updated);
        final merged = _localStore.loadAll();
        merged.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        if (updated.isNotEmpty) {
          _advanceSyncCursor(
            updated
                .map((todo) => todo.updatedAt)
                .reduce((a, b) => a.isAfter(b) ? a : b),
          );
        }
        _maybeSyncSoon();
        return merged;
      } catch (_) {
        // fallback to queue
      }
    }

    await _pendingStore.enqueue(
      PendingMutationType.reorder,
      {
        'orderedIds': orderedIds,
      },
      lastWriteAt,
    );
    _maybeSyncSoon();
    for (var i = 0; i < ordered.length; i++) {
      final todo = ordered[i];
      await _localStore.upsert(
        todo.copyWith(
          orderIndex: i,
          updatedAt: now,
          lastWriteAt: now,
        ),
      );
    }
    final merged = _localStore.loadAll();
    merged.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (_connectivity.isOnline) {
      unawaited(flushPendingMutations());
    }
    return merged;
  }

  Future<void> flushPendingMutations() async {
    if (_isFlushing || !_connectivity.isOnline) {
      return;
    }
    _isFlushing = true;
    try {
      final mutations = _pendingStore.all();
      var appliedAny = false;
      for (final mutation in mutations) {
        final applied = await _applyMutation(mutation);
        if (applied) {
          await _pendingStore.remove(mutation.id);
          appliedAny = true;
        } else {
          break;
        }
      }
      if (appliedAny) {
        _changeController.add(null);
        _maybeSyncSoon();
      }
    } finally {
      _isFlushing = false;
    }
  }

  Future<bool> _applyMutation(PendingMutation mutation) async {
    try {
      switch (mutation.type) {
        case PendingMutationType.create:
          final created = await _apiClient.createTodo(
            title: mutation.payload['title'] as String,
            lastWriteAt: mutation.lastWriteAt,
            id: mutation.payload['id'] as String?,
          );
          await _localStore.upsert(created);
          _advanceSyncCursor(created.updatedAt);
          break;
        case PendingMutationType.update:
          final updated = await _apiClient.updateTodo(
            id: mutation.payload['id'] as String,
            title: mutation.payload['title'] as String,
            revision: mutation.payload['revision'] as int,
            lastWriteAt: mutation.lastWriteAt,
          );
          await _localStore.upsert(updated);
          _advanceSyncCursor(updated.updatedAt);
          break;
        case PendingMutationType.delete:
          await _apiClient.deleteTodo(
            mutation.payload['id'] as String,
            mutation.payload['revision'] as int,
            mutation.lastWriteAt,
          );
          await _localStore.remove(mutation.payload['id'] as String);
          break;
        case PendingMutationType.reorder:
          final updated = await _apiClient.reorderTodos(
            (mutation.payload['orderedIds'] as List<dynamic>).cast<String>(),
            mutation.lastWriteAt,
          );
          await _localStore.upsertMany(updated);
          if (updated.isNotEmpty) {
            _advanceSyncCursor(
              updated
                  .map((todo) => todo.updatedAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b),
            );
          }
          break;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  int _nextOrderIndex() {
    final todos = _localStore.loadAll();
    if (todos.isEmpty) return 0;
    return todos.map((todo) => todo.orderIndex).reduce(max) + 1;
  }

  void _advanceSyncCursor(DateTime candidate) {
    if (_lastSyncedAt == null || candidate.isAfter(_lastSyncedAt!)) {
      _lastSyncedAt = candidate;
    }
  }

  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  bool get hasPendingMutations => !_pendingStore.isEmpty;

  Stream<void> get changes => _changeController.stream;

  void _scheduleBackgroundFetch() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer(const Duration(minutes: 1), () {
      unawaited(_runBackgroundFetch());
    });
  }

  Future<void> _runBackgroundFetch() async {
    if (!_connectivity.isOnline) {
      _scheduleBackgroundFetch();
      return;
    }
    try {
      final remote = await _apiClient.fetchTodos(since: _lastSyncedAt);
      if (remote.isNotEmpty) {
        for (final todo in remote) {
          if (todo.deleted) {
            await _localStore.remove(todo.id);
          } else {
            await _localStore.upsert(todo);
          }
          _advanceSyncCursor(todo.updatedAt);
        }
        _changeController.add(null);
      }
    } catch (_) {
      // ignore background fetch failures
    } finally {
      _scheduleBackgroundFetch();
    }
  }

  void _maybeSyncSoon() {
    if (_connectivity.isOnline) {
      unawaited(_runBackgroundFetch());
    }
  }
}
