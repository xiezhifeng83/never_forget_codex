import 'dart:convert';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

/// Persists the device token required for backend communication.
class DeviceTokenStore {
  static const _boxName = 'device_token_box';
  static const _key = 'deviceToken';

  Box<String>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<String>(_boxName);
    } else {
      _box = Hive.box<String>(_boxName);
    }
  }

  Future<String> getOrCreate() async {
    final box = _ensureBox();
    final existing = box.get(_key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = _generateToken();
    await box.put(_key, generated);
    return generated;
  }

  Box<String> _ensureBox() {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('DeviceTokenStore not initialised');
    }
    return box;
  }

  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
