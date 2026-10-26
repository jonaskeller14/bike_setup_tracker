import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/setup.dart';
import '../repositories/app_repository.dart';
import '../services/setup_carry_over.dart';
import '../widgets/sheets/carry_over_sheet.dart';

class CarryOverActions {
  /// For a copy of [setup] stamped now: asks whether its values recorded on
  /// replaced components move to the components in the same position. Null
  /// when there is nothing to move or the rider leaves them where they are.
  static Future<SetupCarryOver?> confirm(BuildContext context, {required Setup setup}) async {
    final appRepository = context.read<AppRepository>();
    final carryOver = SetupCarryOver.forSetup(
      setup: setup,
      setups: appRepository.setups.values.where((other) => other.bike == setup.bike),
      components: appRepository.components.values,
      hierarchy: appRepository.componentHierarchy,
      history: appRepository.setupHistory,
    );
    if (carryOver.isEmpty) return null;
    final apply = await showCarryOverSheet(context, setup: setup, carryOver: carryOver);
    return apply == true ? carryOver : null;
  }
}
