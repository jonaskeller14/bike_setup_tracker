import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchAppUrl(BuildContext context, {
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

Future<void> launchAppEmail(BuildContext context, String email, {String? subject, String? body}) async {
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

