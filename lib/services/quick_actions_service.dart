import 'package:quick_actions/quick_actions.dart';
import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import 'navigation_service.dart';

class QuickActionsService {
  static final QuickActionsService _instance = QuickActionsService._internal();
  factory QuickActionsService() => _instance;

  QuickActionsService._internal();

  final QuickActions _quickActions = const QuickActions();
  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    _quickActions.initialize((String shortcutType) {
      _handleShortcut(shortcutType);
    });

    _quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'add_setup',
        localizedTitle: 'Add New Setup',
        icon: 'i_add', // Not used for now, using default or generic
      ),
    ]);
  }

  void _handleShortcut(String shortcutType) async {
    debugPrint('Received quick action: $shortcutType');

    if (shortcutType == 'add_setup') {
      _triggerAddSetup();
    }
  }

  Future<void> _triggerAddSetup() async {
    final context = NavigationService.context;
    if (context == null) {
      // If context is not ready, wait a bit and try again
      Future.delayed(const Duration(milliseconds: 500), _triggerAddSetup);
      return;
    }

    await HomePage.addSetup(context);
  }
}
