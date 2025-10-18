import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers.dart';
import 'data/local_store.dart';
import 'data/device_token_store.dart';
import 'data/pending_mutation_store.dart';
import 'services/notification_service.dart';
import 'services/tray_service.dart';
import 'services/connectivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStore = LocalTodoStore();
  await localStore.init();

  final deviceTokenStore = DeviceTokenStore();
  await deviceTokenStore.init();

  final pendingMutationStore = PendingMutationStore();
  await pendingMutationStore.init();

  final notificationService = NotificationService();
  await notificationService.init();

  final trayService = TrayService();
  await trayService.init();

  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        deviceTokenStoreProvider.overrideWithValue(deviceTokenStore),
        pendingMutationStoreProvider.overrideWithValue(pendingMutationStore),
        notificationServiceProvider.overrideWithValue(notificationService),
        trayServiceProvider.overrideWithValue(trayService),
        connectivityServiceProvider.overrideWithValue(connectivityService),
      ],
      child: const SpeckitApp(),
    ),
  );
}
