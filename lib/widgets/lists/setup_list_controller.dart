import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class SetupListController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();

  bool _showBackToTop = false;

  SetupListController() {
    scrollController.addListener(_updateBackToTopVisibility);
  }

  bool get showBackToTop => _showBackToTop && scrollController.hasClients;

  void _updateBackToTopVisibility() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final show = position.pixels > position.viewportDimension * 2;
    if (show == _showBackToTop) return;
    _showBackToTop = show;
    notifyListeners();
  }

  Future<void> scrollBackToTop() {
    if (!scrollController.hasClients) return Future.value();
    return Future.wait<void>([
      HapticFeedback.lightImpact(),
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      ),
    ]);
  }

  @override
  void dispose() {
    scrollController
      ..removeListener(_updateBackToTopVisibility)
      ..dispose();
    super.dispose();
  }
}
