import 'package:bike_setup_tracker/widgets/lists/list_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tracks and resets a list scroll', (tester) async {
    final controller = ListScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          controller: controller.scrollController,
          slivers: const [
            SliverToBoxAdapter(child: SizedBox(height: 3000)),
          ],
        ),
      ),
    );

    controller.scrollController.jumpTo(1600);
    await tester.pump();
    expect(controller.showBackToTop, isTrue);

    final reset = controller.scrollBackToTop();
    await tester.pumpAndSettle();
    await reset;
    expect(controller.scrollController.offset, 0);
    expect(controller.showBackToTop, isFalse);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
