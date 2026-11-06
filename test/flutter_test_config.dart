import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // A date format names its locale, and a plain test loads no Localizations.
  await initializeDateFormatting();
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
