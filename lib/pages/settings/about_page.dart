import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../utils/app_info.dart';
import '../../utils/url.dart';
import '../../widgets/text/section_title.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Widget _buildInfoTile({required String title, required String subtitle}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
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
                    child: _buildInfoTile(title: 'Version', subtitle: "${AppInfo.appVersion} (+${AppInfo.buildNumber})"),
                  ),
                  Expanded(
                    child: _buildInfoTile(title: 'Release Date', subtitle: AppInfo.releaseDate),
                  ),
                ],
              ),

              const Divider(),
              const SectionTitle(title: 'Legal Agreements'),
              _buildLegalTile(
                context: context,
                title: 'Privacy Policy',
                url: AppInfo.privacyPolicyUrl,
              ),
              _buildLegalTile(
                context: context,
                title: 'End-User License Agreement (EULA)',
                url: AppInfo.eulaUrl,
              ),
              if (appSettings.enableStrava)
                _buildLegalTile(
                  context: context,
                  title: 'Terms of Service',
                  url: AppInfo.tosUrl,
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
