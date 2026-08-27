import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_snackbar.dart';

/// Returns a shortened, human-readable form of [url] for display purposes,
/// e.g. "example.com/some/long/path/…" instead of the full
/// "https://www.example.com/some/long/path?query=1".
String shortenUrlForDisplay(String url, {int maxLength = 30}) {
  var display = url.trim();
  display = display.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
  display = display.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
  if (display.length > maxLength) {
    display = '${display.substring(0, maxLength - 1)}…';
  }
  return display;
}

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
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(context, 'Failed to open link: $url'));
    }
  } else {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(context, 'Could not find a program to launch the link.'));
  }
}

/// Opens [appUrl] when its app is installed, otherwise opens [fallbackUrl].
Future<void> launchAppUrlWithFallback(
  BuildContext context, {
  required String appUrl,
  required String fallbackUrl,
}) async {
  final appUri = Uri.parse(appUrl);

  try {
    if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) return;
  } on PlatformException {
    // Fall through to the web URL when no app handles the custom scheme.
  }

  if (!context.mounted) return;
  await launchAppUrl(
    context,
    url: fallbackUrl,
    launchMode: LaunchMode.externalApplication,
  );
}

/// Opens the installed Strava app, otherwise falls back to its Gear page.
Future<void> launchStrava(BuildContext context) async {
  await launchAppUrlWithFallback(
    context,
    appUrl: 'strava://',
    fallbackUrl: 'https://www.strava.com/settings/gear',
  );
}

Future<void> launchAppEmail(BuildContext context, String email, {String? subject, String? body}) async {
  final encodedBody = Uri.encodeComponent(body ?? "");
  final uri = Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject ?? '')}&body=$encodedBody');

  if (await canLaunchUrl(uri)) { // Check if email client exists
    if (await launchUrl(uri)) {
      return;
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(context, 'Failed to open email client for: $email'));
    }
  } else {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(context, 'Could not find an email app on your device.'));
  }
}

Future<void> launchLocationOnMap(BuildContext context, double latitude, double longitude, String displayName) async {
  final String urlScheme = Theme.of(context).platform == TargetPlatform.iOS ? 'maps' : 'geo';
  final String url = '$urlScheme:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(displayName)})';
  final uri = Uri.parse(url);

  if (await canLaunchUrl(uri)) {
    if (await launchUrl(uri)) {
      return;
    }
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    AppSnackBar.error(context, 'No maps app found. Please install Apple Maps, Google Maps, or another maps application.'),
  );
}
