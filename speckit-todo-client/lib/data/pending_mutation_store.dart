import 'dart:convert';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

enum PendingMutationType { create, update, delete, reorder }

class PendingMutation {
  PendingMutation({
    required this.id,
    required this.type,
    required this.payload,
    required this.lastWriteAt,
    required this.createdAt,
  });

  final String id;
  final PendingMutationType type;
  final Map<String, dynamic> payload;
  final String lastWriteAt;
  final String createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': jsonEncode(payload),
        'lastWriteAt': lastWriteAt,
        'createdAt': createdAt,
      };

  static PendingMutation fromJson(Map<dynamic, dynamic> json) {
    return PendingMutation(
      id: json['id'] as String,
      type: PendingMutationType.values.firstWhere(
        (value) => value.name == json['type'],
      ),
      payload: jsonDecode(json['payload'] as String) as Map<String, dynamic>,
      lastWriteAt: json['lastWriteAt'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}

class PendingMutationStore {
  static const _boxName = 'pending_mutation_box';

  Box<Map<dynamic, dynamic>>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
    } else {
      _box = Hive.box<Map<dynamic, dynamic>>(_boxName);
    }
  }

  Future<PendingMutation> enqueue(
    PendingMutationType type,
    Map<String, dynamic> payload,
    String lastWriteAt,
  ) async {
    final mutation = PendingMutation(
      id: _generateId(),
      type: type,
      payload: payload,
      lastWriteAt: lastWriteAt,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _ensureBox().put(mutation.id, mutation.toJson());
    return mutation;
  }

  List<PendingMutation> all() {
    final box = _ensureBox();
    final entries = box.values
        .map((value) => PendingMutation.fromJson(value))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  Future<void> remove(String id) async {
    await _ensureBox().delete(id);
  }

  Future<void> clear() async {
    await _ensureBox().clear();
  }

  bool get isEmpty => _ensureBox().isEmpty;

  Box<Map<dynamic, dynamic>> _ensureBox() {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('PendingMutationStore not initialised');
    }
    return box;
  }

  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
