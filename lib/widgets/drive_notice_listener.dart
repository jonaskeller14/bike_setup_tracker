import 'dart:async';

import 'package:flutter/material.dart';

import '../services/drive_move.dart';
import '../utils/drive_move_actions.dart';

/// Opens the Google Drive notice once, when it first applies: the move into
/// cloud sync, or the hint for users without a subscription. Sits on the home
/// route and waits while a page or sheet covers it.
class DriveNoticeListener extends StatefulWidget {
  final Widget child;

  const DriveNoticeListener({super.key, required this.child});

  @override
  State<DriveNoticeListener> createState() => _DriveNoticeListenerState();
}

class _DriveNoticeListenerState extends State<DriveNoticeListener> {
  final Set<DriveNotice> _checked = {};
  bool _routeIsCurrent = true;

  Future<void> _offer(DriveNotice notice) async {
    if (await DriveNoticePrompts.wasShown(notice) || !mounted) return;
    // Covered during the wait: the build after it is uncovered offers it again.
    if (!_routeIsCurrent) {
      _checked.remove(notice);
      return;
    }
    unawaited(DriveNoticePrompts.markShown(notice));
    await showDriveNotice(context, notice);
  }

  @override
  Widget build(BuildContext context) {
    _routeIsCurrent = ModalRoute.isCurrentOf(context) ?? true;
    final notice = selectDriveNotice(context);
    if (_routeIsCurrent && notice != null && _checked.add(notice)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_offer(notice)));
    }
    return widget.child;
  }
}
