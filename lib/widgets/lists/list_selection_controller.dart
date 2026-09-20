import 'dart:async';
import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Page-scoped multi-select state for a list: which ids are selected and
/// whether a bulk action on them is currently running.
class ListSelectionController<T> extends ChangeNotifier {
  final Set<T> _selected = {};
  bool _isBusy = false;
  bool _isDisposed = false;

  Set<T> get selected => UnmodifiableSetView(_selected);
  int get length => _selected.length;
  bool get isSelectionMode => _selected.isNotEmpty;
  bool get isBusy => _isBusy;

  void toggle(T id) {
    unawaited(HapticFeedback.selectionClick());
    if (!_selected.remove(id)) _selected.add(id);
    _notify();
  }

  void clear() {
    if (_selected.isEmpty) return;
    _selected.clear();
    _notify();
  }

  /// Drops ids that are no longer visible. Deliberately silent: callers prune
  /// from [State.didChangeDependencies], where notifying would rebuild during
  /// build and the rebuild that follows picks the change up anyway.
  void retainWhere(bool Function(T id) test) => _selected.retainWhere(test);

  /// Runs [action] on a snapshot of the selection and clears it afterwards,
  /// blocking further actions while it is in flight.
  Future<void> run(Future<void> Function(Set<T> selected) action) {
    return runIfApplied((selected) async {
      await action(selected);
      return true;
    });
  }

  /// Like [run], but keeps the selection when [action] reports that it did not
  /// apply — e.g. the user dismissed its sheet.
  Future<void> runIfApplied(Future<bool> Function(Set<T> selected) action) async {
    if (_isBusy || _selected.isEmpty) return;

    _isBusy = true;
    _notify();
    try {
      if (await action(Set<T>.of(_selected))) clear();
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
