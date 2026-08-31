import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_info.dart';
import '../utils/file_export.dart';
import '../widgets/app_snackbar.dart';

class LoadingErrorPage extends StatelessWidget {
  const LoadingErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 60,
              ),
              Text(
                "Failed to load data. \nClose and restart the app.",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.headset_mic_outlined),
                      title: const Text('Contact Support'),
                      subtitle: const Text(AppInfo.supportEmail),
                      trailing: const Icon(Icons.open_in_new, size: 16.0),
                      onTap: () async {
                        final uri = Uri.parse('mailto:${AppInfo.supportEmail}?subject=App Load Error');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            AppSnackBar.error(context, 'Could not open email client.'),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: const Text('Download latest Backup'),
                      subtitle: const Text('Download app data as JSON file'),
                      onTap: () async {
                        await FileExport.exportLatestBackup(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
