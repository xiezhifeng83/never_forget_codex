import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/api_client.dart';
import 'data/local_store.dart';
import 'data/device_token_store.dart';
import 'data/todo_repository.dart';
import 'data/pending_mutation_store.dart';
import 'services/notification_service.dart';
import 'services/tray_service.dart';
import 'services/connectivity_service.dart';

final localStoreProvider = Provider<LocalTodoStore>((ref) {
  throw UnimplementedError('localStoreProvider must be overridden');
});

final deviceTokenStoreProvider = Provider<DeviceTokenStore>((ref) {
  throw UnimplementedError('deviceTokenStoreProvider must be overridden');
});

final pendingMutationStoreProvider = Provider<PendingMutationStore>((ref) {
  throw UnimplementedError('pendingMutationStoreProvider must be overridden');
});

final apiClientProvider = Provider<TodoApiClient>((ref) {
  final tokenStore = ref.watch(deviceTokenStoreProvider);
  return TodoApiClient(tokenStore: tokenStore);
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final store = ref.watch(localStoreProvider);
  final pendingStore = ref.watch(pendingMutationStoreProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final repository = TodoRepository(
    apiClient: apiClient,
    localStore: store,
    pendingStore: pendingStore,
    connectivityService: connectivity,
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('notificationServiceProvider must be overridden');
});

final trayServiceProvider = Provider<TrayService>((ref) {
  throw UnimplementedError('trayServiceProvider must be overridden');
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  throw UnimplementedError('connectivityServiceProvider must be overridden');
});
