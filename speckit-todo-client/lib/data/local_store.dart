import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo.dart';

class LocalTodoStore {
  static const _boxName = 'todos';
  Box<Map>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_boxName);
  }

  List<Todo> loadAll() {
    final box = _requireBox();
    return box.values
        .map((value) => Todo.fromJson(Map<String, dynamic>.from(value)))
        .toList();
  }

  Future<void> upsert(Todo todo) async {
    final box = _requireBox();
    await box.put(todo.id, todo.toJson());
  }

  Future<void> upsertMany(Iterable<Todo> todos) async {
    final box = _requireBox();
    final entries = {
      for (final todo in todos) todo.id: todo.toJson(),
    };
    await box.putAll(entries);
  }

  Future<void> remove(String id) async {
    final box = _requireBox();
    await box.delete(id);
  }

  Box<Map> _requireBox() {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('LocalTodoStore not initialized');
    }
    return box;
  }
}
