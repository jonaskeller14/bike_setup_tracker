import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_settings.dart';
import '../../services/strava_service.dart';
import '../../utils/url.dart';
import '../../widgets/dialogs/strava_disconnect.dart';
import '../../widgets/items/strava_subscription_card.dart';
import '../../widgets/sheets/app_settings_radio_group.dart';
import 'about_page.dart';
import 'features_page.dart';
import 'help_page.dart';
import 'preferences_page.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  static const Map<bool, Text> _offOnOptionWidgets = {
    false: Text('Off'),
    true: Text('On'),
  };

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final strava = context.watch<StravaService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
                  title: const Text("Manage Subscription"),
                  subtitle: const Text("Cancel or change your plan in the store"),
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
                    title: const Text("Disconnect Strava"),
                    subtitle: const Text("Revoke access and delete synced activities"),
                    onTap: () async {
                      final confirmed = await showStravaDisconnectDialog(context);
                      if (confirmed) await strava.disconnect();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_active),
                    title: const Text("Strava Notifications"),
                    subtitle: _offOnOptionWidgets[appSettings.enableStravaNotifications] ?? const Text("-"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () => appSettingsRadioGroupSheet<bool>(
                      context: context,
                      title: "Strava Notifications",
                      value: appSettings.enableStravaNotifications,
                      optionWidgets: _offOnOptionWidgets,
                      onChanged: (bool? newValue) {
                        if (newValue == null) return;
                        appSettings.enableStravaNotifications = newValue;
                        unawaited(context.read<StravaService>().setStravaNotificationsEnabled(newValue));
                        Navigator.pop(context);
                      },
                      infoText: 'Receive push notifications when Strava activities are imported.',
                    ),
                  ),
                ],
                const Divider(),
              ],
              // Category navigation (hub → sub-pages).
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Preferences'),
                subtitle: const Text('Appearance, formats and units'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const PreferencesPage())),
              ),
              ListTile(
                leading: const Icon(Icons.extension),
                title: const Text('Features'),
                subtitle: const Text('Enable or disable optional functionality'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const FeaturesPage())),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About & Legal'),
                subtitle: const Text('Version, privacy policy and agreements'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const AboutPage())),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                subtitle: const Text('FAQ, onboarding and contact'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const HelpPage())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
