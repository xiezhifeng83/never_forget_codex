import 'dart:io';

import 'package:system_tray/system_tray.dart';

import '../models/todo.dart';

class TrayService {
  TrayService();

  final SystemTray _systemTray = SystemTray();
  final AppWindow _appWindow = AppWindow();
  bool _initialized = false;

  Future<void> init() async {
    if (!Platform.isWindows) {
      return;
    }
    await _systemTray.initSystemTray(
      title: 'Speckit',
      iconPath: 'assets/tray/icon.ico',
      toolTip: 'Speckit Todo',
    );
    await _systemTray.registerSystemTrayEventHandler((eventName) async {
      if (eventName == 'leftMouseUp' || eventName == 'click') {
        await _systemTray.popUpContextMenu();
      }
    });
    await _updateMenu(null, const []);
    _initialized = true;
  }

  Future<void> update(Todo? top, List<Todo> todos) async {
    if (!Platform.isWindows || !_initialized) {
      return;
    }
    await _updateMenu(top, todos);
  }

  Future<void> _updateMenu(Todo? top, List<Todo> todos) async {
    final menu = Menu();
    await menu.buildFrom(<MenuItem>[
      MenuItemLabel(
        label: top != null ? 'Now: ${top.title}' : 'Nothing pending',
      ),
      MenuSeparator(),
      ...todos.where((todo) => todo.isActive).take(15).map(
            (todo) => MenuItemLabel(
              label: todo.title,
            ),
          ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Open Speckit',
        onClicked: (_) async {
          await _appWindow.show();
          await _appWindow.focus();
        },
      ),
      MenuItemLabel(
        label: 'Quit',
        onClicked: (_) => exit(0),
      ),
    ]);
    await _systemTray.setContextMenu(menu);
  }
}
