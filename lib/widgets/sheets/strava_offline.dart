import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../services/strava_service.dart';
import 'sheet_header.dart';

class StravaOfflineNotice extends StatefulWidget {
  const StravaOfflineNotice({super.key});

  @override
  State<StravaOfflineNotice> createState() => _StravaOfflineNoticeState();
}

class _StravaOfflineNoticeState extends State<StravaOfflineNotice> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await context.read<StravaService>().checkAvailability(force: true);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(
            title: 'Strava Sync',
            leadingIcon: Icon(SimpleIcons.strava, color: Color(0xFFFC4C02)),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "You're offline",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We can't reach our servers to check Strava availability. "
                    "Connect to the internet and try again.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            )
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _retrying ? null : _retry,
              icon: _retrying
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text("Try again"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ),
        ],
      ),
    );
  }
}
