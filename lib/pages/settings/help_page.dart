import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../icons/simple_icons.dart';
import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../services/app_hint_service.dart';
import '../../utils/app_info.dart';
import '../../utils/url.dart';
import '../../widgets/sheets/tip_jar.dart';
import '../../widgets/text/section_title.dart';
import 'faq_page.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Widget _buildContactTile({
    required BuildContext context,
    required String title,
    required String email,
    required IconData icon,
    required String subject,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(email),
      trailing: const Icon(Icons.open_in_new, size: 16.0),
      onTap: () => launchAppEmail(context, email, subject: subject),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpTitle),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SectionTitle(title: l10n.helpSectionHelp),
              ListTile(
                leading: const Icon(Icons.pageview_outlined),
                title: Text(l10n.helpShowOnboarding),
                subtitle: Text(l10n.helpShowOnboardingSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () async {
                  final appSettings = context.read<AppSettings>();
                  await context.read<AppHintService>().resetAll();
                  if (!context.mounted) return;
                  appSettings.showOnboarding = true;
                  Navigator.pop(context); // pop Help Page
                  Navigator.pop(context); // pop Settings Page
                },
              ),
              ListTile(
                leading: const Icon(Icons.question_answer_outlined),
                title: Text(l10n.helpFaq),
                subtitle: Text(l10n.helpFaqSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const FAQPage())),
              ),
              ListTile(
                leading: const Icon(SimpleIcons.strava),
                title: Text(l10n.helpStravaForum),
                subtitle: Text(l10n.helpStravaForumSubtitle),
                trailing: const Icon(Icons.open_in_new, size: 16.0),
                onTap: () => launchAppUrl(context, url: AppInfo.stravaClubForumUrl),
              ),

              const Divider(),
              SectionTitle(title: l10n.helpSectionContact),
              ListTile(
                leading: const Icon(Icons.local_cafe_outlined),
                title: Text(l10n.helpCoffee),
                subtitle: Text(l10n.helpCoffeeSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => showTipJarSheet(context: context),
              ),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(l10n.helpRate),
                subtitle: Theme.of(context).platform == TargetPlatform.iOS
                    ? Text(l10n.helpRateAppStore)
                    : Text(l10n.helpRatePlayStore),
                trailing: const Icon(Icons.open_in_new, size: 16.0),
                onTap: () {
                  final url = Theme.of(context).platform == TargetPlatform.iOS
                      ? AppInfo.appStoreUrl
                      : AppInfo.playStoreUrl;
                  unawaited(launchAppUrl(context, url: url, launchMode: LaunchMode.externalApplication));
                },
              ),
              _buildContactTile(
                context: context,
                title: l10n.helpGeneralSupport,
                email: AppInfo.supportEmail,
                icon: Icons.headset_mic_outlined,
                subject: 'Bike Setup Tracker: Support Request [v${AppInfo.appVersion}+${AppInfo.buildNumber}]',
              ),
              _buildContactTile(
                context: context,
                title: l10n.helpSuggestFeatures,
                email: AppInfo.featuresEmail,
                icon: Icons.lightbulb_outline,
                subject: 'Bike Setup Tracker: Feature Suggestion [v${AppInfo.appVersion}+${AppInfo.buildNumber}]',
              ),
              _buildContactTile(
                context: context,
                title: l10n.helpReportBugs,
                email: AppInfo.bugsEmail,
                icon: Icons.bug_report_outlined,
                subject: 'Bike Setup Tracker: Bug Report [v${AppInfo.appVersion}+${AppInfo.buildNumber}]',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
