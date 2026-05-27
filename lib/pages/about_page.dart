import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../icons/simple_icons.dart';
import '../models/app_settings.dart';
import '../utils/url.dart';
import '../widgets/text/section_title.dart';
import 'faq_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String appVersion = '1.3.2';
  static const String buildNumber = '24';
  static const String releaseDate = 'May 2026';

  static const String supportEmail = 'jonaskeller14.app+support@gmail.com';
  static const String featuresEmail = 'jonaskeller14.app+features@gmail.com';
  static const String bugsEmail = 'jonaskeller14.app+bugs@gmail.com';

  static const String privacyPolicyUrl = 'https://jonaskeller14.com/bike_setup_tracker/privacy_policy.html';
  static const String eulaUrl = 'https://jonaskeller14.com/bike_setup_tracker/eula.html';
  static const String tosURL = 'https://jonaskeller14.de/bike_setup_tracker/terms_of_service.html';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.jonaskeller14.bike_setup_tracker';
  static const String appStoreUrl = 'https://apps.apple.com/app/id6759974325?action=write-review';

  Widget _buildInfoTile({required String title, required String subtitle}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
    );
  }

  Widget _buildContactTile({required BuildContext context, required String title, required String email, required IconData icon, required String subject}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(email),
      trailing: const Icon(Icons.open_in_new, size: 16.0),
      onTap: () => launchAppEmail(context, email, subject: subject),
    );
  }

  Widget _buildLegalTile({required BuildContext context, required String title, required String url}) {
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(title),
      onTap: () => launchAppUrl(context, url: url),
      trailing: const Icon(Icons.open_in_new, size: 16.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
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
                    child: _buildInfoTile(title: 'Version', subtitle: "$appVersion (+$buildNumber)"),
                  ),
                  Expanded(
                    child: _buildInfoTile(title: 'Release Date', subtitle: releaseDate),
                  ),
                ],
              ),
              const Divider(),
              const SectionTitle(title: 'Contact & Feedback'),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Rate this app'),
                subtitle: Theme.of(context).platform == TargetPlatform.iOS 
                    ? const Text('Rate this app on Apple AppStore.')
                    : const Text('Rate this app on Google PlayStore.'),
                trailing: const Icon(Icons.open_in_new, size: 16.0),
                onTap: () {
                  final url = Theme.of(context).platform == TargetPlatform.iOS ? appStoreUrl : playStoreUrl;
                  unawaited(launchAppUrl(context, url: url, launchMode: LaunchMode.externalApplication));
                },
              ),
              _buildContactTile(
                context: context,
                title: 'General Support',
                email: supportEmail,
                icon: Icons.headset_mic_outlined,
                subject: 'Bike Setup Tracker: Support Request [v$appVersion+$buildNumber]',
              ),
              _buildContactTile(
                context: context,
                title: 'Suggest Features',
                email: featuresEmail,
                icon: Icons.lightbulb_outline,
                subject: 'Bike Setup Tracker: Feature Suggestion [v$appVersion+$buildNumber]',
              ),
              _buildContactTile(
                context: context,
                title: 'Report Bugs',
                email: bugsEmail,
                icon: Icons.bug_report_outlined,
                subject: 'Bike Setup Tracker: Bug Report [v$appVersion+$buildNumber]',
              ),
              
              const Divider(),
              const SectionTitle(title: 'Help'),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text("Show Onboarding"),
                subtitle: const Text("Show onboarding slides to get started."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () {
                  context.read<AppSettings>().showOnboarding = true;
                  Navigator.pop(context);
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
                onTap: () => launchAppUrl(context, url: 'https://www.strava.com/clubs/bike_setup_tracker'),
              ),
        
              const Divider(),
              const SectionTitle(title: 'Legal Agreements'),
              _buildLegalTile(
                context: context,
                title: 'Privacy Policy',
                url: privacyPolicyUrl,
              ),
              _buildLegalTile(
                context: context,
                title: 'End-User License Agreement (EULA)',
                url: eulaUrl,
              ),
              if (appSettings.enableStrava)
                _buildLegalTile(
                  context: context,
                  title: 'Terms of Service',
                  url: tosURL,
                ),
              const ListTile(
                leading: Icon(Icons.copyright),
                title: Text("Third-party trademarks"),
                subtitle: Text("Google Drive is a trademark of Google LLC."),
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
