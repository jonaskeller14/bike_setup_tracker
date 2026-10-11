import 'package:bike_setup_tracker/widgets/hints/setup_calendar_hint.dart';
import 'package:bike_setup_tracker/widgets/hints/setup_task_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget hint) => MaterialApp(home: Scaffold(body: hint));

  testWidgets('Task hint delegates activation and dismissal', (tester) async {
    var activated = false;
    var dismissed = false;

    await tester.pumpWidget(
      wrap(SetupTaskHint(onActivate: () async => activated = true, onDismiss: () => dismissed = true)),
    );
    await tester.tap(find.text('Activate Tasks'));
    await tester.pumpAndSettle();
    expect((activated, dismissed), (true, false));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      wrap(SetupTaskHint(onActivate: () async => activated = false, onDismiss: () => dismissed = true)),
    );
    await tester.tap(find.text('No thanks'));
    await tester.pumpAndSettle();
    expect((activated, dismissed), (true, true));
  });

  testWidgets('Calendar hint delegates activation and dismissal', (tester) async {
    var activated = false;
    var dismissed = false;

    await tester.pumpWidget(
      wrap(SetupCalendarHint(onActivate: () async => activated = true, onDismiss: () => dismissed = true)),
    );
    await tester.tap(find.text('Turn on Calendar'));
    await tester.pumpAndSettle();
    expect((activated, dismissed), (true, false));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      wrap(SetupCalendarHint(onActivate: () async => activated = false, onDismiss: () => dismissed = true)),
    );
    await tester.tap(find.text('No thanks'));
    await tester.pumpAndSettle();
    expect((activated, dismissed), (true, true));
  });
}
