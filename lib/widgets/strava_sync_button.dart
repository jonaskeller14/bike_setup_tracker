import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../icons/simple_icons.dart';
import '../services/strava_service.dart';
import 'sheets/strava.dart';

class StravaSyncButton extends StatelessWidget {
  const StravaSyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    final stravaService = context.watch<StravaService>();

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(SimpleIcons.strava),
          onPressed: () => showStravaSheet(context: context),
        ),
        
        // The "Badge" with loading circle (only shown if isSyncing is true)
        if (stravaService.isBusy)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 14,
              height: 14,
              padding: const EdgeInsets.all(2),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],  
    );
  }
}
