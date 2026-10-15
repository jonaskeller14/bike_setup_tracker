import 'package:bike_setup_tracker/widgets/hints/app_hint_deck.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildDeck({
    List<AppHintPage>? pages,
    VoidCallback? onDismiss,
    AppHintAction? action,
    Future<bool?> Function()? onLearnMore,
  }) => MaterialApp(
    home: Scaffold(
      body: AppHintDeck(
        icon: Icons.lightbulb_outline,
        label: 'Tip',
        pages:
            pages ??
            [AppHintPage(title: 'Deck title', action: action, onLearnMore: onLearnMore, content: const Text('Only page'))],
        onDismiss: onDismiss,
      ),
    ),
  );

  group('single card', () {
    testWidgets('"Got it" dismisses after the card flies away', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(buildDeck(onDismiss: () => dismissed++));

      await tester.tap(find.text('Got it'));
      await tester.pump();
      expect(dismissed, 0);

      await tester.pumpAndSettle();
      expect(dismissed, 1);
    });

    testWidgets('action runs after the fly-away, "No thanks" only dismisses', (tester) async {
      var activated = 0;
      var dismissed = 0;
      final action = AppHintAction(label: 'Activate', icon: Icons.add, onPressed: () async => activated++);

      await tester.pumpWidget(buildDeck(onDismiss: () => dismissed++, action: action));
      expect(find.text('Got it'), findsNothing);
      await tester.tap(find.text('Activate'));
      await tester.pumpAndSettle();
      expect((activated, dismissed), (1, 0));

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(buildDeck(onDismiss: () => dismissed++, action: action));
      await tester.tap(find.text('No thanks'));
      await tester.pumpAndSettle();
      expect((activated, dismissed), (1, 1));
    });

    testWidgets('an action that keeps the hint runs immediately and leaves the card', (tester) async {
      var activated = 0;
      await tester.pumpWidget(
        buildDeck(
          onDismiss: () {},
          action: AppHintAction(
            label: 'Step',
            icon: Icons.add,
            completesHint: false,
            onPressed: () async => activated++,
          ),
        ),
      );

      await tester.tap(find.text('Step'));
      await tester.pump();
      expect(activated, 1);

      await tester.tap(find.text('Step'));
      await tester.pump();
      expect(activated, 2);
    });

    testWidgets('"Learn more" runs the action only when the explainer confirms it', (tester) async {
      var activated = 0;
      bool? explainerResult;
      final action = AppHintAction(label: 'Activate', icon: Icons.add, onPressed: () async => activated++);

      await tester.pumpWidget(buildDeck(action: action, onLearnMore: () async => explainerResult));
      for (final result in [null, false]) {
        explainerResult = result;
        await tester.tap(find.byTooltip('Learn more'));
        await tester.pumpAndSettle();
      }
      expect(activated, 0);

      explainerResult = true;
      await tester.tap(find.byTooltip('Learn more'));
      await tester.pumpAndSettle();
      expect(activated, 1);
    });

    testWidgets('shows "Learn more" only with onLearnMore', (tester) async {
      await tester.pumpWidget(buildDeck());
      expect(find.byTooltip('Learn more'), findsNothing);
    });

    testWidgets('shows no dismiss buttons without onDismiss', (tester) async {
      await tester.pumpWidget(buildDeck());

      expect(find.text('Got it'), findsNothing);
      expect(find.text('No thanks'), findsNothing);
    });
  });

  group('multiple cards', () {
    const pages = [
      AppHintPage(content: Text('First tip')),
      AppHintPage(content: Text('Second tip')),
      AppHintPage(content: Text('Third tip')),
    ];

    // Cards behind the top one are rendered but ignore pointers.
    Finder topCard(String label) => find.text(label).hitTestable();

    testWidgets('swiping moves between cards without dismissing', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(buildDeck(pages: pages, onDismiss: () => dismissed++));
      expect(topCard('TIP 1 / 3'), findsOneWidget);

      await tester.fling(find.text('First tip'), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(topCard('TIP 2 / 3'), findsOneWidget);

      await tester.fling(topCard('Second tip'), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(topCard('TIP 1 / 3'), findsOneWidget);

      await tester.fling(topCard('First tip'), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(topCard('TIP 1 / 3'), findsOneWidget);
      expect(dismissed, 0);
    });

    testWidgets('"Next" advances and "Got it" on the last card dismisses', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(buildDeck(pages: pages, onDismiss: () => dismissed++));

      await tester.tap(topCard('Next'));
      await tester.pumpAndSettle();
      await tester.tap(topCard('Next'));
      await tester.pumpAndSettle();
      expect(topCard('TIP 3 / 3'), findsOneWidget);
      expect(topCard('Skip'), findsNothing);

      await tester.tap(topCard('Got it'));
      await tester.pumpAndSettle();
      expect(dismissed, 1);
    });

    testWidgets('"Skip" dismisses from any card', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(buildDeck(pages: pages, onDismiss: () => dismissed++));

      await tester.tap(topCard('Skip'));
      await tester.pumpAndSettle();
      expect(dismissed, 1);
    });

    testWidgets('a page action on an earlier card runs, then advances without dismissing', (tester) async {
      var activated = 0;
      var dismissed = 0;
      await tester.pumpWidget(
        buildDeck(
          onDismiss: () => dismissed++,
          pages: [
            AppHintPage(
              title: 'Page title',
              action: AppHintAction(label: 'Turn on', icon: Icons.add, onPressed: () async => activated++),
              content: const Text('First tip'),
            ),
            const AppHintPage(title: 'Deck title', content: Text('Second tip')),
          ],
        ),
      );
      expect(topCard('Page title'), findsOneWidget);
      expect(topCard('Skip'), findsNothing);

      await tester.tap(topCard('Turn on'));
      await tester.pumpAndSettle();
      expect((activated, dismissed), (1, 0));
      expect(topCard('TIP 2 / 2'), findsOneWidget);
      expect(topCard('Deck title'), findsOneWidget);
      expect(topCard('Turn on'), findsNothing);
    });

    testWidgets('"Learn more" belongs to its page and runs that page\'s action', (tester) async {
      var activated = 0;
      await tester.pumpWidget(
        buildDeck(
          pages: [
            const AppHintPage(content: Text('First tip')),
            AppHintPage(
              onLearnMore: () async => true,
              action: AppHintAction(label: 'Turn on', icon: Icons.add, onPressed: () async => activated++),
              content: const Text('Second tip'),
            ),
          ],
        ),
      );
      expect(find.byTooltip('Learn more').hitTestable(), findsNothing);

      await tester.tap(topCard('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Learn more').hitTestable());
      await tester.pumpAndSettle();
      expect(activated, 1);
    });
  });
}
