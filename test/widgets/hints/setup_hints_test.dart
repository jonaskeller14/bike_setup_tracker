import 'package:bike_setup_tracker/widgets/hints/setup_calendar_hint.dart';
import 'package:bike_setup_tracker/widgets/hints/setup_task_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Task hint delegates activation and dismissal', (tester) async {
    var activated = false;
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SetupTaskHint(
            onActivate: () async => activated = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Activate Tasks'));
    await tester.tap(find.byTooltip('Dismiss'));

    expect(activated, isTrue);
    expect(dismissed, isTrue);
  });

  testWidgets('Calendar hint delegates activation and dismissal', (tester) async {
    var activated = false;
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SetupCalendarHint(
            onActivate: () async => activated = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Turn on Calendar'));
    await tester.tap(find.byTooltip('Dismiss'));

    expect(activated, isTrue);
    expect(dismissed, isTrue);
  });
}
