import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo.dart';
import '../state/todo_controller.dart';
import 'widgets/add_todo_field.dart';
import 'widgets/todo_list_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    ref.listen<TodoState>(todoControllerProvider, (previous, next) {
      final prevCount = previous?.todos.length ?? 0;
      if (next.todos.length > prevCount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todoControllerProvider);
    final notifier = ref.watch(todoControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speckit'),
        actions: [
          IconButton(
            icon: state.isSyncing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed:
                state.isSyncing ? null : () => notifier.refresh(full: true),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            AddTodoField(
              onSubmitted: notifier.addTodo,
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(
                message: state.errorMessage!,
                onRetry: () => notifier.refresh(full: true),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => notifier.refresh(full: true),
                      child: state.todos.isEmpty
                          ? const _EmptyState()
                          : ReorderableListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: state.todos.length,
                              scrollController: _scrollController,
                              onReorder: (oldIndex, newIndex) =>
                                  notifier.reorder(oldIndex, newIndex),
                              itemBuilder: (context, index) {
                                final todo = state.todos[index];
                                return TodoListTile(
                                  key: ValueKey(todo.id),
                                  todo: todo,
                                  reorderIndex: index,
                                  onRename: (value) =>
                                      notifier.renameTodo(todo, value),
                                  onDelete: () => notifier.deleteTodo(todo),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      content: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        )
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Everything is clear',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add the next thing you need to remember.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
