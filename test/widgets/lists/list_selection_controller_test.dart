import 'dart:async';

import 'package:bike_setup_tracker/widgets/lists/list_selection_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ListSelectionController<String> controller;
  late int notifications;

  setUp(() {
    notifications = 0;
    controller = ListSelectionController<String>()..addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  test('toggling ids drives selection mode', () {
    expect(controller.isSelectionMode, isFalse);

    controller.toggle(['a']);
    controller.toggle(['b']);
    expect(controller.selected, {'a', 'b'});
    expect(controller.length, 2);
    expect(controller.isSelectionMode, isTrue);

    controller.toggle(['a']);
    expect(controller.selected, {'b'});

    controller.clear();
    expect(controller.isSelectionMode, isFalse);
    expect(notifications, 4);
  });

  test('toggle selects a partial group, then deselects the full group', () {
    controller.toggle(['a']);
    notifications = 0;

    controller.toggle(['a', 'b', 'c']);
    expect(controller.selected, {'a', 'b', 'c'});

    controller.toggle(['d']);
    controller.toggle(['a', 'b', 'c']);
    expect(controller.selected, {'d'});
    expect(notifications, 3);
  });

  test('clearing an empty selection does not notify', () {
    controller.clear();
    expect(notifications, 0);
  });

  test('retainWhere prunes hidden ids without notifying', () {
    controller
      ..toggle(['a'])
      ..toggle(['b']);
    notifications = 0;

    controller.retainWhere((id) => id == 'a');
    expect(controller.selected, {'a'});
    expect(notifications, 0);
  });

  test('run clears the selection and reports busy while in flight', () async {
    controller.toggle(['a']);
    final gate = Completer<void>();

    Set<String>? received;
    final pending = controller.run((selected) async {
      received = selected;
      await gate.future;
    });

    expect(controller.isBusy, isTrue);
    expect(controller.isSelectionMode, isTrue);

    gate.complete();
    await pending;

    expect(received, {'a'});
    expect(controller.isBusy, isFalse);
    expect(controller.isSelectionMode, isFalse);
  });

  test('run hands the action a snapshot that later toggles do not mutate', () async {
    controller.toggle(['a']);
    final gate = Completer<void>();

    Set<String>? received;
    final pending = controller.run((selected) async {
      received = selected;
      await gate.future;
    });

    controller.toggle(['b']);
    gate.complete();
    await pending;

    expect(received, {'a'});
  });

  test('runIfApplied keeps the selection when the action does not apply', () async {
    controller.toggle(['a']);

    await controller.runIfApplied((_) async => false);
    expect(controller.selected, {'a'});

    await controller.runIfApplied((_) async => true);
    expect(controller.isSelectionMode, isFalse);
  });

  test('a second action is ignored while one is running', () async {
    controller.toggle(['a']);
    final gate = Completer<void>();

    var runs = 0;
    final pending = controller.run((_) async {
      runs++;
      await gate.future;
    });
    await controller.run((_) async => runs++);

    gate.complete();
    await pending;

    expect(runs, 1);
  });

  test('an action on an empty selection is skipped', () async {
    var ran = false;
    await controller.run((_) async => ran = true);

    expect(ran, isFalse);
    expect(controller.isBusy, isFalse);
  });

  test('an action that completes after dispose does not notify', () async {
    final disposable = ListSelectionController<String>()..toggle(['a']);
    final gate = Completer<void>();
    final pending = disposable.run((_) => gate.future);

    disposable.dispose();
    gate.complete();

    await expectLater(pending, completes);
  });
}
