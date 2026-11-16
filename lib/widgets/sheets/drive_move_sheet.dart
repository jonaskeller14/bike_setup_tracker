import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../icons/simple_icons.dart';
import '../../l10n/l10n.dart';
import '../../services/drive_move.dart';
import 'sheet_header.dart';
import 'sheet_progress_content.dart';

Future<void> showDriveMoveSheet(BuildContext context, {required Future<DriveMoveState> Function() move}) {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => DriveMoveSheet(move: move),
  );
}

enum DriveEndingChoice { saveFile, cloudSync }

Future<DriveEndingChoice?> showDriveEndingSheet(BuildContext context, {required DriveEndingOffer offer}) {
  return showModalBottomSheet<DriveEndingChoice>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => DriveEndingSheet(offer: offer),
  );
}

/// Offers the one-time move from Google Drive into cloud sync and shows how it went.
class DriveMoveSheet extends StatefulWidget {
  final Future<DriveMoveState> Function() move;

  const DriveMoveSheet({super.key, required this.move});

  @override
  State<DriveMoveSheet> createState() => _DriveMoveSheetState();
}

class _DriveMoveSheetState extends State<DriveMoveSheet> {
  DriveMoveState _state = DriveMoveState.offered;

  Future<void> _move() async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _state = DriveMoveState.running);
    final result = await widget.move();
    if (mounted) setState(() => _state = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final Widget content = switch (_state) {
      DriveMoveState.running => SheetProgressContent(title: l10n.driveSheetTitle, message: l10n.driveMoveRunning),
      DriveMoveState.offered => _DriveNoticeContent(
        icon: const Icon(Icons.drive_file_move_outline),
        title: l10n.driveMoveOfferTitle,
        body: l10n.driveMoveOfferBody,
        primaryIcon: Icons.cloud_upload_outlined,
        primaryLabel: l10n.driveMoveStart,
        onPrimary: _move,
        secondaryLabel: l10n.driveNotNow,
      ),
      DriveMoveState.done || DriveMoveState.nothingToMove => _DriveNoticeContent(
        icon: Icon(Icons.cloud_done_outlined, color: colorScheme.primary),
        title: _state == DriveMoveState.done ? l10n.driveMoveDoneTitle : l10n.driveMoveNothingTitle,
        body: _state == DriveMoveState.done ? l10n.driveMoveDoneBody : l10n.driveMoveNothingBody,
        primaryIcon: Icons.check,
        primaryLabel: l10n.close,
        onPrimary: () => Navigator.pop(context),
      ),
      DriveMoveState.signInFailed || DriveMoveState.offline || DriveMoveState.failed => _DriveNoticeContent(
        icon: Icon(
          _state == DriveMoveState.offline ? Icons.wifi_off : Icons.error_outline,
          color: _state == DriveMoveState.offline ? null : colorScheme.error,
        ),
        title: switch (_state) {
          DriveMoveState.signInFailed => l10n.driveMoveSignInFailedTitle,
          DriveMoveState.offline => l10n.driveMoveOfflineTitle,
          _ => l10n.driveMoveFailedTitle,
        },
        body: switch (_state) {
          DriveMoveState.signInFailed => l10n.driveMoveSignInFailedBody,
          DriveMoveState.offline => l10n.driveMoveOfflineBody,
          _ => l10n.driveMoveFailedBody,
        },
        primaryIcon: Icons.refresh,
        primaryLabel: l10n.driveMoveRetry,
        onPrimary: _move,
        secondaryLabel: l10n.driveNotNow,
      ),
    };

    return PopScope(
      canPop: _state != DriveMoveState.running,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(key: ValueKey(_state), child: content),
      ),
    );
  }
}

/// Tells a Google Drive user without active cloud sync that Drive sync is
/// ending, and offers a backup file or the next step to cloud sync instead.
class DriveEndingSheet extends StatelessWidget {
  final DriveEndingOffer offer;

  const DriveEndingSheet({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (body, syncLabel) = switch (offer) {
      DriveEndingOffer.subscribe => (l10n.driveEndingBody, l10n.driveEndingGetCloudSync),
      DriveEndingOffer.turnOnSync => (l10n.driveEndingBodySync, l10n.driveEndingTurnOnSync),
      DriveEndingOffer.connectStrava => (l10n.driveEndingBodyConnect, l10n.driveEndingConnectStrava),
    };
    return _DriveNoticeContent(
      icon: const Icon(Icons.info_outline),
      title: l10n.driveEndingTitle,
      body: body,
      primaryIcon: Icons.save_alt,
      primaryLabel: l10n.driveEndingSaveFile,
      onPrimary: () => Navigator.pop(context, DriveEndingChoice.saveFile),
      tonalIcon: Icons.cloud_outlined,
      tonalLabel: syncLabel,
      onTonal: () => Navigator.pop(context, DriveEndingChoice.cloudSync),
      secondaryLabel: l10n.driveNotNow,
    );
  }
}

class _DriveNoticeContent extends StatelessWidget {
  final Widget icon;
  final String title;
  final String body;
  final IconData primaryIcon;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final IconData? tonalIcon;
  final String? tonalLabel;
  final VoidCallback? onTonal;
  final String? secondaryLabel;

  const _DriveNoticeContent({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryIcon,
    required this.primaryLabel,
    required this.onPrimary,
    this.tonalIcon,
    this.tonalLabel,
    this.onTonal,
    this.secondaryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tonalLabel = this.tonalLabel;
    final secondaryLabel = this.secondaryLabel;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: context.l10n.driveSheetTitle, leadingIcon: const Icon(SimpleIcons.googledrive)),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(size: 40, color: theme.colorScheme.onSurfaceVariant),
                      child: icon,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                FilledButton.icon(onPressed: onPrimary, icon: Icon(primaryIcon), label: Text(primaryLabel)),
                if (tonalLabel != null)
                  FilledButton.tonalIcon(onPressed: onTonal, icon: Icon(tonalIcon), label: Text(tonalLabel)),
              ],
            ),
          ),
          if (secondaryLabel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(onPressed: () => Navigator.pop(context), child: Text(secondaryLabel)),
            ),
          if (secondaryLabel == null) const SizedBox(height: 16),
        ],
      ),
    );
  }
}
