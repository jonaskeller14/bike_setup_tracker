import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../utils/app_info.dart';
import '../../utils/url.dart';
import '../../widgets/sheets/tip_jar.dart';
import '../../widgets/text/section_title.dart';
import 'faq_page.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Widget _buildContactTile({required BuildContext context, required String title, required String email, required IconData icon, required String subject}) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionTitle(title: 'Help'),
              ListTile(
                leading: const Icon(Icons.pageview_outlined),
                title: const Text("Show Onboarding"),
                subtitle: const Text("Show onboarding slides to get started."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () {
                  final appSettings = context.read<AppSettings>();
                  appSettings.showAllHints();
                  appSettings.showOnboarding = true;
                  Navigator.pop(context);  // pop Help Page
                  Navigator.pop(context);  // pop Settings Page
                },
              ),
              ListTile(
                leading: const Icon(Icons.question_answer_outlined),
                title: const Text("FAQ"),
                subtitle: const Text("Show frequently asked questions."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const FAQPage())),
              ),
              ListTile(
                leading: const Icon(SimpleIcons.strava),
                title: const Text("Strava Club Forum"),
                subtitle: const Text("Get help and discuss the app with other users."),
                trailing: const Icon(Icons.open_in_new, size: 16.0),
                onTap: () => launchAppUrl(context, url: AppInfo.stravaClubForumUrl),
              ),

              const Divider(),
              const SectionTitle(title: 'Contact & Feedback'),
              ListTile(
                leading: const Icon(Icons.local_cafe_outlined),
                title: const Text('Buy me a coffee'),
                subtitle: const Text('Support development with a small tip.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => showTipJarSheet(context: context),
              ),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Rate this app'),
                subtitle: Theme.of(context).platform == TargetPlatform.iOS
                    ? const Text('Rate this app on Apple AppStore.')
                    : const Text('Rate this app on Google PlayStore.'),
                trailing: const Icon(Icons.open_in_new, size: 16.0),
                onTap: () {
                  final url = Theme.of(context).platform == TargetPlatform.iOS ? AppInfo.appStoreUrl : AppInfo.playStoreUrl;
                  unawaited(launchAppUrl(context, url: url, launchMode: LaunchMode.externalApplication));
                },
              ),
              _buildContactTile(
                context: context,
                title: 'General Support',
                email: AppInfo.supportEmail,
                icon: Icons.headset_mic_outlined,
                subject: 'Bike Setup Tracker: Support Request [v${AppInfo.appVersion}+${AppInfo.buildNumber}]',
              ),
              _buildContactTile(
                context: context,
                title: 'Suggest Features',
                email: AppInfo.featuresEmail,
                icon: Icons.lightbulb_outline,
                subject: 'Bike Setup Tracker: Feature Suggestion [v${AppInfo.appVersion}+${AppInfo.buildNumber}]',
              ),
              _buildContactTile(
                context: context,
                title: 'Report Bugs',
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
