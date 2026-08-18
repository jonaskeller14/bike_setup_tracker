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
        // Icon glyphs and anti-aliased curves vary slightly between Windows
        // baseline generation and the Ubuntu CI renderer.
        diffThreshold: 0.005,
      ),
    ),
    run: () async {
      await testMain();
    },
  );
}
