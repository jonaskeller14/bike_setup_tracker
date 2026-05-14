import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_settings.dart';
import 'faq_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String appVersion = '1.2.2';
  static const String buildNumber = '21';
  static const String releaseDate = 'May 2026';

  static const String supportEmail = 'jonaskeller14.app+support@gmail.com';
  static const String featuresEmail = 'jonaskeller14.app+features@gmail.com';
  static const String bugsEmail = 'jonaskeller14.app+bugs@gmail.com';

  static const String privacyPolicyUrl = 'https://jonaskeller14.com/bike_setup_tracker/privacy_policy.html';
  static const String eulaUrl = 'https://jonaskeller14.com/bike_setup_tracker/eula.html';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.jonaskeller14.bike_setup_tracker';
  static const String appStoreUrl = 'https://apps.apple.com/app/id6759974325?action=write-review';

  Future<void> _launchUrl(BuildContext context, {
    required String url, 
    LaunchMode launchMode = LaunchMode.platformDefault,
  }) async {
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) { // Check if browser exists
      if (await launchUrl(uri, mode: launchMode)) {
        return;
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
          content: Text('Failed to open link: $url', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
          backgroundColor: Theme.of(context).colorScheme.errorContainer
        ));
      }
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text('Could not find a program to launch the link.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
    }
  }

  Future<void> _launchEmail(BuildContext context, String email, {String? subject, String? body}) async {
    final encodedBody = Uri.encodeComponent(body ?? "");
    final uri = Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject ?? '')}&body=$encodedBody');
    
    if (await canLaunchUrl(uri)) { // Check if email client exists
      if (await launchUrl(uri)) {
        return;
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
          content: Text('Failed to open email client for: $email', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
          backgroundColor: Theme.of(context).colorScheme.errorContainer
        ));
      }
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        persist: false,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        content: Text('Could not find an email app on your device.', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)), 
        backgroundColor: Theme.of(context).colorScheme.errorContainer
      ));
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

  Widget _buildContactTile({required BuildContext context, required String title, required String email, required IconData icon, required String subject}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(email),
      trailing: const Icon(Icons.open_in_new, size: 16.0),
      onTap: () => _launchEmail(context, email, subject: subject),
    );
  }

  Widget _buildLegalTile({required BuildContext context, required String title, required String url}) {
    return ListTile(
      leading: Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      onTap: () => _launchUrl(context, url: url),
      trailing: const Icon(Icons.open_in_new, size: 16.0),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                child: Text(
                  'App Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
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
              const Divider(height: 32.0),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                child: Text(
                  'Contact & Feedback',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListTile(
                leading: Icon(Icons.star_outline, color: Theme.of(context).colorScheme.primary),
                title: const Text('Rate this app'),
                subtitle: Theme.of(context).platform == TargetPlatform.iOS 
                    ? const Text('Rate this app on Apple AppStore.')
                    : const Text('Rate this app on Google PlayStore.'),
                trailing: const Icon(Icons.open_in_new, size: 16.0),
                onTap: () {
                  final url = Theme.of(context).platform == TargetPlatform.iOS ? appStoreUrl : playStoreUrl;
                  unawaited(_launchUrl(context, url: url, launchMode: LaunchMode.externalApplication));
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
              
              const Divider(height: 32.0),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                child: Text(
                  'Help',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListTile(
                leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
                title: const Text("Show Onboarding"),
                subtitle: const Text("Show onboarding slides to get started."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () {
                  context.read<AppSettings>().showOnboarding = true;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.question_answer_outlined, color: Theme.of(context).colorScheme.primary),
                title: const Text("FAQ"),
                subtitle: const Text("Show frequently asked questions."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.push<void>(context, MaterialPageRoute(builder: (context) => const FAQPage())),
              ),
              ListTile(
                leading: Icon(SimpleIcons.strava, color: Theme.of(context).colorScheme.primary),
                title: const Text("Strava Club Forum"),
                subtitle: const Text("Get help and discuss the app with other users."),
                trailing: const Icon(Icons.open_in_new, size: 16.0),
                onTap: () => _launchUrl(context, url: 'https://www.strava.com/clubs/bike_setup_tracker'),
              ),
        
              const Divider(height: 32.0),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                child: Text(
                  'Legal Agreements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
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
              ListTile(
                leading: Icon(Icons.copyright, color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: const Text("Third-party trademarks"),
                subtitle: const Text("Google Drive is a trademark of Google LLC."),
                dense: true,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
