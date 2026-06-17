import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../services/subscription_service.dart';
import '../../utils/app_info.dart';
import '../../utils/url.dart';
import '../../widgets/text/section_title.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  bool _showUserId = false;

  /// The anonymous Firebase UID, regardless of the `enableStrava` rollout gate.
  /// [SubscriptionService.userId] is only populated once Strava is enabled and
  /// the service has bound the user, so we fall back to FirebaseAuth's current
  /// user (the same shared anonymous account) to cover the gated-off case.
  String? get _userId =>
      context.read<SubscriptionService>().userId ?? 
      FirebaseAuth.instance.currentUser?.uid;

  Widget _buildInfoTile({required String title, required String subtitle}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
    );
  }

  Widget _buildLegalTile({required String title, required String url}) {
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(title),
      onTap: () => launchAppUrl(context, url: url),
      trailing: const Icon(Icons.open_in_new, size: 16.0),
    );
  }

  Widget _buildUserIdTile() {
    final userId = _userId;
    return ListTile(
      title: const Text('User UID', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: userId == null
          ? const Text('Not available yet')
          : SelectableText(userId),
      trailing: userId == null
          ? null
          : IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16.0),
              tooltip: 'Copy',
              onPressed: () {
                unawaited(Clipboard.setData(ClipboardData(text: userId)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User UID copied')),
                );
              },
            ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Legal'),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 64.0,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bike Setup Tracker',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(),
              const SectionTitle(title: 'App Information'),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: _showUserId ? null : () => setState(() => _showUserId = true),
                      child: _buildInfoTile(title: 'Version', subtitle: "${AppInfo.appVersion} (+${AppInfo.buildNumber})"),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoTile(title: 'Release Date', subtitle: AppInfo.releaseDate),
                  ),
                ],
              ),
              if (_showUserId) _buildUserIdTile(),

              const Divider(),
              const SectionTitle(title: 'Legal Agreements'),
              _buildLegalTile(
                title: 'Privacy Policy',
                url: AppInfo.privacyPolicyUrl,
              ),
              _buildLegalTile(
                title: 'End-User License Agreement (EULA)',
                url: AppInfo.eulaUrl,
              ),
              if (appSettings.enableStrava)
                _buildLegalTile(
                  title: 'Terms of Service',
                  url: AppInfo.tosUrl,
                ),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('Open-Source Licenses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Bike Setup Tracker',
                  applicationVersion: '${AppInfo.appVersion} (+${AppInfo.buildNumber})',
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/icons/logo_256.png', width: 64, height: 64),
                  ),
                  applicationLegalese: '© 2025-2026 Jonas Keller. All rights reserved.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.copyright),
                title: const Text("Third-party trademarks"),
                subtitle: Text(
                  appSettings.enableStrava
                      ? "Strava is a trademark of Strava, Inc.\nGoogle Drive is a trademark of Google LLC."
                      : "Google Drive is a trademark of Google LLC.",
                ),
                dense: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
