import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../repositories/app_repository.dart';
import '../../services/account_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/account_actions.dart';
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
