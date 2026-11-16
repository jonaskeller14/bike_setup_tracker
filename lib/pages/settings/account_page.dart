import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../repositories/app_repository.dart';
import '../../services/account_service.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/account_actions.dart';
import '../../utils/localized_number.dart';
import '../../widgets/text/section_title.dart';

/// The account this device is signed in to: who it belongs to, its devices,
/// signing out and deleting it. Only reachable while on an account.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final Stream<List<AccountDevice>> _devices = context.read<AccountService>().watchDevices();
  bool _busy = false;

  Future<void> _run(Future<void> Function(BuildContext context, {VoidCallback? onConfirmed}) action) async {
    try {
      await action(context, onConfirmed: () => setState(() => _busy = true));
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountTitle),
        bottom: _busy ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator()) : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AccountHeader(),
              const Divider(),
              if (context.select<AppSettings, bool>((settings) => settings.enableCloudSync)) ...[
                SectionTitle(title: l10n.accountSectionCloudSync),
                _CloudSyncTile(enabled: !_busy),
                if (context.select<CloudSyncService, String?>((sync) => sync.activeUid) case final uid?)
                  _StorageUsageTile(key: ValueKey(uid), enabled: !_busy),
                const Divider(),
              ],
              SectionTitle(title: l10n.accountSectionDevices),
              _DeviceList(devices: _devices, enabled: !_busy),
              const Divider(),
              ListTile(
                enabled: !_busy,
                leading: const Icon(Icons.logout),
                title: Text(l10n.accountSignOut),
                subtitle: Text(l10n.accountSignOutSubtitle),
                onTap: () => _run(AccountActions.signOut),
              ),
              ListTile(
                enabled: !_busy,
                leading: Icon(Icons.delete_forever_outlined, color: _busy ? null : errorColor),
                title: Text(l10n.accountDelete),
                subtitle: Text(l10n.accountDeleteSubtitle),
                onTap: () => _run(AccountActions.deleteAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final athlete = context.select<AppRepository, String?>((repository) {
      final athlete = repository.stravaAthletes.values.firstOrNull;
      if (athlete == null) return null;
      final name = [athlete.firstname, athlete.lastname].whereType<String>().join(' ').trim();
      return name.isEmpty ? null : name;
    });
    final entitlement = context.select<SubscriptionService, ({bool active, DateTime? expiresAt, bool renews})>(
      (subscription) => (
        active: subscription.hasStravaEntitlement,
        expiresAt: subscription.entitlement?.expiresAt,
        renews: subscription.entitlement?.autoRenewing ?? false,
      ),
    );
    final dateFormat = context.select<AppSettings, String>((settings) => settings.dateFormat);
    final expiresAt = entitlement.expiresAt;
    final date = expiresAt == null ? null : DateFormat(dateFormat, l10n.localeName).format(expiresAt);

    return ListTile(
      leading: const Icon(Icons.account_circle, size: 40),
      title: Text(athlete ?? l10n.accountFallbackName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          l10n.accountSignedInThroughStrava,
          switch (date) {
            final date? when entitlement.active && entitlement.renews => l10n.accountPremiumRenews(date),
            final date? when entitlement.active => l10n.accountPremiumActive(date),
            _ => l10n.accountPremiumInactive,
          },
        ].join('\n'),
      ),
      isThreeLine: true,
    );
  }
}

/// The sync status of this device and "Sync now".
class _CloudSyncTile extends StatelessWidget {
  final bool enabled;

  const _CloudSyncTile({required this.enabled});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final sync = context
        .select<
          CloudSyncService,
          ({bool active, CloudSyncStatus status, DateTime? lastSyncAt, int pending, int pendingFiles, bool storageFull})
        >(
          (sync) => (
            active: sync.isActive,
            status: sync.status,
            lastSyncAt: sync.lastSyncAt,
            pending: sync.pendingCount,
            pendingFiles: sync.pendingAttachmentUploads,
            storageFull: sync.attachmentQuotaFull,
          ),
        );
    final premium = context.select<SubscriptionService, bool>((subscription) => subscription.hasStravaEntitlement);
    final formats = context.select<AppSettings, (String, String)>((settings) => (settings.dateFormat, settings.timeFormat));
    final lastSyncAt = sync.lastSyncAt?.toLocal();
    final lastSynced = lastSyncAt == null
        ? l10n.accountSyncNever
        : l10n.accountSyncLastSynced(
            '${DateFormat(formats.$1, l10n.localeName).format(lastSyncAt)} '
            '${DateFormat(formats.$2, l10n.localeName).format(lastSyncAt)}',
          );
    final syncing = sync.status == CloudSyncStatus.syncing;

    final (icon, title) = switch (sync.status) {
      _ when !premium => (Icon(Icons.cloud_off_outlined, color: colorScheme.onSurfaceVariant), l10n.accountSyncNeedsPremium),
      CloudSyncStatus.syncing => (
        const SizedBox.square(dimension: 24, child: Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2))),
        l10n.accountSyncSyncing,
      ),
      CloudSyncStatus.offline => (const Icon(Icons.cloud_off_outlined), l10n.accountSyncOffline),
      CloudSyncStatus.error => (Icon(Icons.sync_problem_outlined, color: colorScheme.error), l10n.accountSyncError),
      CloudSyncStatus.idle => (const Icon(Icons.cloud_done_outlined), lastSynced),
    };
    final subtitle = [
      if (premium && sync.status != CloudSyncStatus.idle) lastSynced,
      if (sync.pending > 0) l10n.accountSyncPending(sync.pending),
      if (sync.pendingFiles > 0) l10n.accountSyncPendingFiles(sync.pendingFiles),
      if (sync.storageFull) l10n.accountSyncStorageFull,
    ].join('\n');

    return ListTile(
      enabled: enabled,
      leading: icon,
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: !premium
          ? null
          : IconButton(
              tooltip: l10n.accountSyncNow,
              icon: const Icon(Icons.sync),
              onPressed: enabled && sync.active && !syncing ? () => AccountActions.syncNow(context) : null,
            ),
    );
  }
}

/// How much of the cloud storage quota the account uses. Read once per page
/// visit (and per account, through the key) instead of listening, since every
/// snapshot costs a read.
class _StorageUsageTile extends StatefulWidget {
  final bool enabled;

  const _StorageUsageTile({super.key, required this.enabled});

  @override
  State<_StorageUsageTile> createState() => _StorageUsageTileState();
}

class _StorageUsageTileState extends State<_StorageUsageTile> {
  static const _megabyte = 1024 * 1024;
  static const _warnFraction = 0.9;

  late Future<int> _bytes = context.read<CloudSyncService>().readStorageBytes();

  void _reload() => setState(() {
    _bytes = context.read<CloudSyncService>().readStorageBytes();
  });

  /// Whole megabytes, with one decimal below 10 MB so a few photos don't read as 0.
  static String _megabytes(int bytes, String locale) => formatLocalizedDouble(
    bytes / _megabyte,
    fractionDigits: bytes > 0 && bytes < 10 * _megabyte ? 1 : 0,
    locale: locale,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    const quota = CloudSyncService.storageQuotaBytes;

    return FutureBuilder<int>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ListTile(
            enabled: widget.enabled,
            leading: Icon(Icons.error_outline, color: colorScheme.error),
            title: Text(l10n.accountStorageTitle),
            subtitle: Text(l10n.accountStorageLoadFailed),
            onTap: _reload,
          );
        }
        final bytes = snapshot.data;
        // The counter is driven by Storage events, so it can drift below zero.
        final used = bytes == null ? null : math.max(bytes, 0);
        return ListTile(
          enabled: widget.enabled,
          leading: const Icon(Icons.data_usage),
          title: Text(l10n.accountStorageTitle),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(
                  value: used == null ? null : (used / quota).clamp(0.0, 1.0),
                  color: used != null && used >= quota * _warnFraction ? colorScheme.error : null,
                ),
              ),
              if (used != null)
                Text(l10n.accountStorageUsed(_megabytes(used, l10n.localeName), _megabytes(quota, l10n.localeName))),
            ],
          ),
        );
      },
    );
  }
}

class _DeviceList extends StatelessWidget {
  final Stream<List<AccountDevice>> devices;
  final bool enabled;

  const _DeviceList({required this.devices, required this.enabled});

  static const _platformLabels = {
    'android': 'Android',
    'ios': 'iOS',
    'macos': 'macOS',
    'windows': 'Windows',
    'linux': 'Linux',
    'web': 'Web',
  };

  static String label(AccountDevice device) {
    final platform = _platformLabels[device.platform] ?? device.platform;
    return device.deviceName.isEmpty ? platform : device.deviceName;
  }

  static IconData _icon(String platform) => switch (platform) {
    'android' || 'ios' => Icons.smartphone,
    'web' => Icons.public,
    _ => Icons.computer,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final thisDevice = context.select<AccountService, String?>((account) => account.deviceId);
    final dateFormat = context.select<AppSettings, String>((settings) => settings.dateFormat);

    return StreamBuilder<List<AccountDevice>>(
      stream: devices,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ListTile(
            leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            title: Text(l10n.accountDevicesLoadFailed),
          );
        }
        final devices = snapshot.data;
        if (devices == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (devices.isEmpty) {
          return ListTile(
            leading: const Icon(Icons.devices_other),
            title: Text(l10n.accountDevicesEmpty),
          );
        }
        return Column(
          children: [
            for (final device in devices)
              _DeviceTile(
                device: device,
                label: label(device),
                isThisDevice: device.deviceId == thisDevice,
                lastSeen: device.lastSeenAt == null
                    ? null
                    : l10n.accountDeviceLastSeen(DateFormat(dateFormat, l10n.localeName).format(device.lastSeenAt!)),
                icon: _icon(device.platform),
                enabled: enabled,
              ),
          ],
        );
      },
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final AccountDevice device;
  final String label;
  final bool isThisDevice;
  final String? lastSeen;
  final IconData icon;
  final bool enabled;

  const _DeviceTile({
    required this.device,
    required this.label,
    required this.isThisDevice,
    required this.lastSeen,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtitle = [if (isThisDevice) l10n.accountThisDevice, ?lastSeen].join(' · ');
    return ListTile(
      enabled: enabled,
      leading: Icon(icon),
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty ? null : Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: isThisDevice
          ? null
          : IconButton(
              tooltip: l10n.accountSignOutDeviceTooltip,
              icon: const Icon(Icons.logout),
              onPressed: enabled ? () => AccountActions.signOutDevice(context, device, deviceLabel: label) : null,
            ),
    );
  }
}
