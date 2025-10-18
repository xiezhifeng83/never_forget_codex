import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/todo_repository.dart';
import '../models/todo.dart';
import '../providers.dart';
import '../services/notification_service.dart';
import '../services/tray_service.dart';

class TodoState {
  const TodoState({
    required this.todos,
    this.isLoading = false,
    this.isSyncing = false,
    this.errorMessage,
    this.hasPendingMutations = false,
  });

  final List<Todo> todos;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;
  final bool hasPendingMutations;

  TodoState copyWith({
    List<Todo>? todos,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
    bool? hasPendingMutations,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
      hasPendingMutations:
          hasPendingMutations ?? this.hasPendingMutations,
    );
  }

  Todo? get topTodo => todos.isEmpty ? null : todos.first;
}

class TodoController extends StateNotifier<TodoState> {
  TodoController(
    this._repository,
    this._notificationService,
    this._trayService,
  ) : super(const TodoState(todos: [], isLoading: true));

  final TodoRepository _repository;
  final NotificationService _notificationService;
  final TrayService _trayService;

  Timer? _syncTimer;
  Timer? _surfaceTimer;
  StreamSubscription<void>? _repositorySub;

  Future<void> initialize() async {
    await _loadCache();
    await refresh(full: true);
    _startTimers();
    _repositorySub = _repository.changes.listen((_) async {
      final cached = await _repository.loadFromCache();
      cached.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      state = state.copyWith(
        todos: cached,
        hasPendingMutations: _repository.hasPendingMutations,
      );
      await _updateSurfaces();
    });
  }

  Future<void> refresh({bool full = false}) async {
    state = state.copyWith(isSyncing: true, errorMessage: null);
    try {
      final todos = await _repository.refresh(full: full);
      todos.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      state = state.copyWith(
        todos: todos,
        isSyncing: false,
        hasPendingMutations: _repository.hasPendingMutations,
      );
      await _updateSurfaces();
    } catch (error) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Sync failed: $error',
        hasPendingMutations: _repository.hasPendingMutations,
      );
    }
  }

  Future<void> addTodo(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    try {
      final created = await _repository.createTodo(title: trimmed);
      final next = [...state.todos, created]
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      state = state.copyWith(
        todos: next,
        errorMessage: null,
        hasPendingMutations: _repository.hasPendingMutations,
      );
      await _updateSurfaces();
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Create failed: $error',
        hasPendingMutations: _repository.hasPendingMutations,
      );
    }
  }

  Future<void> renameTodo(Todo todo, String nextTitle) async {
    final trimmed = nextTitle.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: 'Title cannot be empty');
      return;
    }
    try {
      final updated = await _repository.renameTodo(
        todo: todo,
        nextTitle: trimmed,
      );
      final next = [
        for (final item in state.todos)
          if (item.id == todo.id) updated else item
      ]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      state = state.copyWith(
        todos: next,
        errorMessage: null,
        hasPendingMutations: _repository.hasPendingMutations,
      );
      await _updateSurfaces();
    } on StateError catch (error) {
      if (error.message == 'conflict' || error.message == 'deleted') {
        await refresh(full: true);
      } else {
        state = state.copyWith(
          errorMessage: 'Update failed: $error',
          hasPendingMutations: _repository.hasPendingMutations,
        );
      }
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Update failed: $error',
        hasPendingMutations: _repository.hasPendingMutations,
      );
    }
  }

  Future<void> deleteTodo(Todo todo) async {
    try {
      await _repository.deleteTodo(todo);
      final next = state.todos.where((item) => item.id != todo.id).toList();
      state = state.copyWith(
        todos: next,
        hasPendingMutations: _repository.hasPendingMutations,
      );
      await _updateSurfaces();
    } on StateError catch (error) {
      if (error.message == 'conflict' || error.message == 'deleted') {
        await refresh(full: true);
      } else {
        state = state.copyWith(
          errorMessage: 'Delete failed: $error',
          hasPendingMutations: _repository.hasPendingMutations,
        );
      }
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Delete failed: $error',
        hasPendingMutations: _repository.hasPendingMutations,
      );
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final items = [...state.todos];
    if (newIndex > oldIndex) newIndex -= 1;
    final todo = items.removeAt(oldIndex);
    items.insert(newIndex, todo);
    state = state.copyWith(
      todos: items,
      hasPendingMutations: _repository.hasPendingMutations,
    );

    try {
      final updated = await _repository.reorderTodos(items);
      state = state.copyWith(
        todos: updated,
        errorMessage: null,
        hasPendingMutations: _repository.hasPendingMutations,
      );
      await _updateSurfaces();
    } on StateError catch (error) {
      state = state.copyWith(
        errorMessage: 'Reorder conflict: $error',
        hasPendingMutations: _repository.hasPendingMutations,
      );
      await refresh(full: true);
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Reorder failed: $error',
        hasPendingMutations: _repository.hasPendingMutations,
      );
      await refresh(full: true);
    }
  }

  Future<void> _loadCache() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cached = await _repository.loadFromCache();
      cached.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      state = state.copyWith(todos: cached, isLoading: false);
      state = state.copyWith(
        hasPendingMutations: _repository.hasPendingMutations,
      );
      await _updateSurfaces();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Cache load failed: $error',
        hasPendingMutations: _repository.hasPendingMutations,
      );
    }
  }

  void _startTimers() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refresh();
    });

    _surfaceTimer?.cancel();
    _surfaceTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateSurfaces();
    });
  }

  Future<void> _updateSurfaces() async {
    await _notificationService.updateTopTodo(state.topTodo, state.todos);
    await _trayService.update(state.topTodo, state.todos);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _surfaceTimer?.cancel();
    _repositorySub?.cancel();
    super.dispose();
  }
}

final todoControllerProvider =
    StateNotifierProvider<TodoController, TodoState>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  final notification = ref.watch(notificationServiceProvider);
  final tray = ref.watch(trayServiceProvider);

  final controller = TodoController(repository, notification, tray);
  Future<void>.microtask(controller.initialize);
  ref.onDispose(controller.dispose);
  return controller;
});
