import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ListScrollController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();

  bool _showBackToTop = false;
  bool _isNearTop = true;
  final List<VoidCallback> _scrollToTopListeners = [];

  ListScrollController() {
    scrollController.addListener(_updateBackToTopVisibility);
  }

  bool get showBackToTop => _showBackToTop && scrollController.hasClients;

  bool get isNearTop => _isNearTop || !scrollController.hasClients;

  void _updateBackToTopVisibility() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final show = position.pixels > position.viewportDimension * 2;
    final nearTop = position.pixels < position.viewportDimension * 0.5;
    if (show == _showBackToTop && nearTop == _isNearTop) return;
    _showBackToTop = show;
    _isNearTop = nearTop;
    notifyListeners();
  }

  void addScrollToTopListener(VoidCallback listener) {
    _scrollToTopListeners.add(listener);
  }

  void removeScrollToTopListener(VoidCallback listener) {
    _scrollToTopListeners.remove(listener);
  }

  Future<void> scrollBackToTop() async {
    unawaited(HapticFeedback.lightImpact());
    for (final listener in List<VoidCallback>.of(_scrollToTopListeners)) {
      listener();
    }
    if (!scrollController.hasClients) return;
    await scrollController.animateTo(
      scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    scrollController
      ..removeListener(_updateBackToTopVisibility)
      ..dispose();
    super.dispose();
  }
}
