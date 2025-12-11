import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String appVersion = '1.0.2';
  static const String buildNumber = '4';
  static const String releaseDate = 'December 2025';

  static const String supportEmail = 'jonaskeller14.app+support@gmail.com';
  static const String featuresEmail = 'jonaskeller14.app+features@gmail.com';
  static const String bugsEmail = 'jonaskeller14.app+bugs@gmail.com';

  static const String privacyPolicyUrl = 'https://jonaskeller14.com/bike_setup_tracker/privacy_policy.html';
  static const String eulaUrl = 'https://jonaskeller14.com/bike_setup_tracker/eula.html';
  
String _getEmailContext() {
    final now = DateTime.now().toIso8601String().substring(0, 16);
    return '''
------------------
App Version: $appVersion
Build Number: $buildNumber
Current Time: $now
------------------



''';
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) { // Check if browser exists
      if (await launchUrl(uri)) {
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
    final bodyContext = _getEmailContext();
    final encodedBody = Uri.encodeComponent((body ?? '') + bodyContext);
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
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
      onTap: () => _launchEmail(context, email, subject: subject),
    );
  }

  Widget _buildLegalTile({required BuildContext context, required String title, required String url}) {
    return ListTile(
      leading: Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      onTap: () => _launchUrl(context, url),
      trailing: const Icon(Icons.open_in_new, size: 16.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
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
            _buildInfoTile(title: 'Version', subtitle: appVersion),
            _buildInfoTile(title: 'Build Number', subtitle: buildNumber),
            _buildInfoTile(title: 'Release Date', subtitle: releaseDate),

            const Divider(height: 32.0),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
              child: Text(
                'Contact & Feedback',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _buildContactTile(
              context: context,
              title: 'General Support',
              email: supportEmail,
              icon: Icons.headset_mic_outlined,
              subject: 'Bike Setup Tracker Support Request',
            ),
            _buildContactTile(
              context: context,
              title: 'Suggestions & Features',
              email: featuresEmail,
              icon: Icons.lightbulb_outline,
              subject: 'Bike Setup Tracker Feature Suggestion',
            ),
            _buildContactTile(
              context: context,
              title: 'Report Bugs',
              email: bugsEmail,
              icon: Icons.bug_report_outlined,
              subject: 'BUG Report: Bike Setup Tracker',
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
