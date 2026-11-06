import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../services/strava_service.dart';
import '../../utils/automation_ids.dart';
import '../../utils/url.dart';
import '../../widgets/dialogs/strava_disconnect.dart';
import '../../widgets/items/strava_subscription_card.dart';
import '../../widgets/sheets/radio_group.dart';
import 'about_page.dart';
import 'attachments_page.dart';
import 'features_page.dart';
import 'help_page.dart';
import 'preferences_page.dart';
import 'reset_page.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  static Map<bool, Text> _offOnOptionWidgets(AppLocalizations l10n) => {
    false: Text(l10n.valueOff),
    true: Text(l10n.valueOn),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appSettings = context.watch<AppSettings>();
    final strava = context.watch<StravaService>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appSettings.enableStrava) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: StravaSubscriptionCard(),
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts),
                  title: Text(l10n.settingsManageSubscription),
                  subtitle: Text(l10n.settingsManageSubscriptionSubtitle),
                  trailing: const Icon(Icons.open_in_new, size: 16.0),
                  onTap: () {
                    final url = Platform.isIOS
                        ? 'https://apps.apple.com/account/subscriptions'
                        : 'https://play.google.com/store/account/subscriptions'
                            '?sku=strava_sync'
                            '&package=com.jonaskeller14.bike_setup_tracker';
                    unawaited(launchAppUrl(
                      context,
                      url: url,
                      launchMode: LaunchMode.externalApplication,
                    ));
                  },
                ),
                if (strava.isConnected) ...[
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(l10n.settingsDisconnectStrava),
                    subtitle: Text(l10n.settingsDisconnectStravaSubtitle),
                    onTap: () async {
                      final confirmed = await showStravaDisconnectDialog(context);
                      if (confirmed) await strava.disconnect();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_active),
                    title: Text(l10n.settingsStravaNotifications),
                    subtitle: _offOnOptionWidgets(l10n)[appSettings.enableStravaNotifications] ?? const Text("-"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () => radioGroupSheet<bool>(
                      context: context,
                      title: l10n.settingsStravaNotifications,
                      value: appSettings.enableStravaNotifications,
                      optionWidgets: _offOnOptionWidgets(l10n),
                      onChanged: (bool? newValue) {
                        if (newValue == null) return;
                        appSettings.enableStravaNotifications = newValue;
                        unawaited(context.read<StravaService>().setStravaNotificationsEnabled(newValue));
                        Navigator.pop(context);
                      },
                      infoText: l10n.settingsStravaNotificationsInfo,
                    ),
                  ),
                ],
                const Divider(),
              ],
              // Category navigation (hub → sub-pages).
              Semantics(
                container: true,
                identifier: AutomationIds.settingsPreferences,
                child: ListTile(
                  leading: const Icon(Icons.tune),
                  title: Text(l10n.settingsPreferences),
                  subtitle: Text(l10n.settingsPreferencesSubtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const PreferencesPage())),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.extension),
                title: Text(l10n.settingsFeatures),
                subtitle: Text(l10n.settingsFeaturesSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const FeaturesPage())),
              ),
              if (appSettings.enableAttachments)
                ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(l10n.settingsAttachments),
                  subtitle: Text(l10n.settingsAttachmentsSubtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const AttachmentsPage())),
                ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.settingsAbout),
                subtitle: Text(l10n.settingsAboutSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const AboutPage())),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(l10n.settingsHelp),
                subtitle: Text(l10n.settingsHelpSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const HelpPage())),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
                title: Text(l10n.settingsReset),
                subtitle: Text(l10n.settingsResetSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const ResetPage())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
