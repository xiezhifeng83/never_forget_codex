import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/todo.dart';
import 'device_token_store.dart';

class TodoApiClient {
  TodoApiClient({
    http.Client? httpClient,
    String? baseUrl,
    required DeviceTokenStore tokenStore,
  })  : _client = httpClient ?? http.Client(),
        _tokenStore = tokenStore,
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'BACKEND_URL',
              defaultValue: 'http://localhost:4000',
            );

  final http.Client _client;
  final DeviceTokenStore _tokenStore;
  final String _baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await _tokenStore.getOrCreate();
    final headers = <String, String>{
      'X-Device-Token': token,
    };
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  Future<List<Todo>> fetchTodos({DateTime? since}) async {
    final query = <String, String>{};
    if (since != null) {
      query['since'] = since.toUtc().toIso8601String();
    }
    final response = await _client.get(
      _uri('/todos', query),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load todos: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (decoded['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Todo.fromJson)
        .toList();
    return list;
  }

  Future<Todo> fetchTopTodo() async {
    final response = await _client.get(
      _uri('/todos/top'),
      headers: await _headers(),
    );
    if (response.statusCode == 404) {
      throw StateError('no-top');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch top todo: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Todo.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  Future<Todo> createTodo({
    required String title,
    required String lastWriteAt,
    String? id,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'lastWriteAt': lastWriteAt,
    };
    if (id != null) {
      payload['id'] = id;
    }
    final response = await _client.post(
      _uri('/todos'),
      headers: await _headers(json: true),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create todo: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Todo.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  Future<Todo> updateTodo({
    required String id,
    required String title,
    required int revision,
    required String lastWriteAt,
  }) async {
    final response = await _client.put(
      _uri('/todos/$id'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'title': title,
        'revision': revision,
        'lastWriteAt': lastWriteAt,
      }),
    );
    if (response.statusCode == 409) {
      throw StateError('conflict');
    }
    if (response.statusCode == 404) {
      throw StateError('deleted');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to update todo: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Todo.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  Future<Todo> deleteTodo(
    String id,
    int revision,
    String lastWriteAt,
  ) async {
    final response = await _client.delete(
      _uri('/todos/$id', {
        'revision': revision.toString(),
        'lastWriteAt': lastWriteAt,
      }),
      headers: await _headers(),
    );
    if (response.statusCode == 409) {
      throw StateError('conflict');
    }
    if (response.statusCode == 404) {
      throw StateError('deleted');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to delete todo: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Todo.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  Future<List<Todo>> reorderTodos(
    List<String> orderedIds,
    String lastWriteAt,
  ) async {
    final response = await _client.put(
      _uri('/todos/reorder'),
      headers: await _headers(json: true),
      body: jsonEncode({
        'orderedIds': orderedIds,
        'lastWriteAt': lastWriteAt,
      }),
    );
    if (response.statusCode == 409) {
      throw StateError('conflict');
    }
    if (response.statusCode == 404) {
      throw StateError('deleted');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to reorder todos: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Todo.fromJson)
        .toList();
  }

  Future<String> getDeviceToken() => _tokenStore.getOrCreate();

  void dispose() {
    _client.close();
  }
}
