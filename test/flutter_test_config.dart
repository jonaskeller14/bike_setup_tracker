import 'dart:async';

import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: CiGoldensConfig(
        enabled: true,
        obscureText: true,
        renderShadows: false,
        diffThreshold: 0,
      ),
    ),
    run: () async {
      await testMain();
    },
  );
}
