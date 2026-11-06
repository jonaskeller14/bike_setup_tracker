import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../database/app_database.dart';
import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../services/subscription_service.dart';
import '../../utils/app_info.dart';
import '../../utils/url.dart';
import '../../widgets/app_snackbar.dart';
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

  /// [AppInfo.releaseDate] is written in English; show it in the app language.
  String get _releaseDate {
    try {
      final date = DateFormat('MMMM yyyy', 'en').parse(AppInfo.releaseDate);
      return DateFormat.yMMMM(Localizations.localeOf(context).toString()).format(date);
    } on FormatException {
      return AppInfo.releaseDate;
    }
  }

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
    final l10n = context.l10n;
    final userId = _userId;
    return ListTile(
      title: Text(l10n.aboutUserUid, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: userId == null
          ? Text(l10n.aboutUserUidUnavailable)
          : SelectableText(userId),
      trailing: userId == null
          ? null
          : IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16.0),
              tooltip: l10n.aboutCopy,
              onPressed: () {
                unawaited(Clipboard.setData(ClipboardData(text: userId)));
                ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.success(context, l10n.aboutUserUidCopied));
              },
            ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appSettings = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutTitle),
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
                        l10n.appTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(),
              SectionTitle(title: l10n.aboutSectionInformation),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: _showUserId ? null : () => setState(() => _showUserId = true),
                      child: _buildInfoTile(title: l10n.aboutVersion, subtitle: "${AppInfo.appVersion} (+${AppInfo.buildNumber})"),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoTile(title: l10n.aboutReleaseDate, subtitle: _releaseDate),
                  ),
                ],
              ),
              if (_showUserId) ...[
                _buildUserIdTile(),
                _buildInfoTile(
                  title: 'App Database',
                  subtitle: 'Schema v${context.read<AppDatabase>().schemaVersion}',
                ),
              ],

              const Divider(),
              SectionTitle(title: l10n.aboutSectionLegal),
              _buildLegalTile(
                title: l10n.aboutPrivacyPolicy,
                url: AppInfo.privacyPolicyUrl,
              ),
              _buildLegalTile(
                title: l10n.aboutEula,
                url: AppInfo.eulaUrl,
              ),
              if (appSettings.enableStrava)
                _buildLegalTile(
                  title: l10n.aboutTermsOfService,
                  url: AppInfo.tosUrl,
                ),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text(l10n.aboutLicenses),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                  applicationVersion: '${AppInfo.appVersion} (+${AppInfo.buildNumber})',
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/icons/logo_256.png', width: 64, height: 64),
                  ),
                  applicationLegalese: l10n.aboutLegalese,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.copyright),
                title: Text(l10n.aboutTrademarks),
                subtitle: Text(
                  appSettings.enableStrava ? l10n.aboutTrademarksStravaAndDrive : l10n.aboutTrademarksDrive,
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
