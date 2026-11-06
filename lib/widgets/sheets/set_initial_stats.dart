import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../models/component_stats.dart';
import '../../models/context/context_position.dart';
import '../../theme.dart';
import '../../utils/localized_number.dart';
import '../../utils/number_input_formatters.dart';
import '../dialogs/discard_changes.dart';
import 'sheet_header.dart';

String? initialStatsSummary(ComponentStats stats, AppSettings appSettings, AppLocalizations l10n) {
  final number = NumberFormat('#,##0.#', l10n.localeName);
  final parts = [
    if (stats.distance > 0)
      "${number.format(AppSettings.convertDistanceFromMeters(stats.distance, appSettings.distanceUnit))} ${appSettings.distanceUnit}",
    if (stats.elevationGain > 0)
      "${number.format(AppSettings.convertElevationFromMeters(stats.elevationGain, appSettings.altitudeUnit))} ${appSettings.altitudeUnit}",
    if (stats.movingTime.inHours > 0) "${stats.movingTime.inHours} h",
    if (stats.elapsedTime.inHours > 0) "${stats.elapsedTime.inHours} h",
    if (stats.activityCount > 0) l10n.initialStatsActivities(stats.activityCount),
    if (stats.kilojoules > 0) "${number.format(stats.kilojoules)} kJ",
  ];
  if (parts.isEmpty) return null;
  return parts.join(" · ");
}

Future<ComponentStats?> showSetInitialStatsSheet({
  required BuildContext context,
  required ComponentStats initialStats,
  ComponentStats? originalStats,
  String? description,
}) async {
  return showModalBottomSheet<ComponentStats?>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return SetInitialStatsSheetContent(
        initialStats: initialStats,
        originalStats: originalStats,
        description: description,
      );
    },
  );
}

class SetInitialStatsSheetContent extends StatefulWidget {
  final ComponentStats initialStats;
  final ComponentStats? originalStats;
  final String? description;

  const SetInitialStatsSheetContent({
    super.key,
    required this.initialStats,
    this.originalStats,
    this.description,
  });

  @override
  State<SetInitialStatsSheetContent> createState() => _SetInitialStatsSheetContentState();
}

class _SetInitialStatsSheetContentState extends State<SetInitialStatsSheetContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _distanceController;
  late TextEditingController _elevationGainController;
  late TextEditingController _movingTimeController;
  late TextEditingController _elapsedTimeController;
  late TextEditingController _activityCountController;
  late TextEditingController _kilojoulesController;

  /// Parsed from the prefilled fields rather than taken from
  /// [SetInitialStatsSheetContent.initialStats], so hour truncation and unit
  /// round-trips don't register as a change.
  late ComponentStats _initialParsedStats;

  @override
  void initState() {
    super.initState();
    final appSettings = context.read<AppSettings>();
    final stats = widget.initialStats;
    final distance = AppSettings.convertDistanceFromMeters(stats.distance, appSettings.distanceUnit) ?? 0.0;
    _distanceController = TextEditingController(text: formatEditableDouble(distance, locale: context.untrackedLocaleName));
    final elevationGain = AppSettings.convertElevationFromMeters(stats.elevationGain, appSettings.altitudeUnit) ?? 0.0;
    _elevationGainController = TextEditingController(text: formatEditableDouble(elevationGain, locale: context.untrackedLocaleName));
    _movingTimeController = TextEditingController(text: stats.movingTime.inHours.toString());
    _elapsedTimeController = TextEditingController(text: stats.elapsedTime.inHours.toString());
    _activityCountController = TextEditingController(text: stats.activityCount.toString());
    _kilojoulesController = TextEditingController(text: formatEditableDouble(stats.kilojoules, locale: context.untrackedLocaleName));
    _initialParsedStats = _readStats(appSettings);
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _elevationGainController.dispose();
    _movingTimeController.dispose();
    _elapsedTimeController.dispose();
    _activityCountController.dispose();
    _kilojoulesController.dispose();
    super.dispose();
  }

  ComponentStats _readStats(AppSettings appSettings) {
    final distanceInput = parseLocalizedDouble(_distanceController.text) ?? 0.0;
    final elevationGainInput = parseLocalizedDouble(_elevationGainController.text) ?? 0.0;
    return ComponentStats(
      distance: AppSettings.convertDistanceToMeters(distanceInput, appSettings.distanceUnit) ?? 0.0,
      elevationGain: ContextPosition.convertAltitudeToMeters(elevationGainInput, appSettings.altitudeUnit) ?? 0.0,
      movingTime: Duration(hours: int.tryParse(_movingTimeController.text.trim()) ?? 0),
      elapsedTime: Duration(hours: int.tryParse(_elapsedTimeController.text.trim()) ?? 0),
      activityCount: int.tryParse(_activityCountController.text.trim()) ?? 0,
      kilojoules: parseLocalizedDouble(_kilojoulesController.text) ?? 0.0,
    );
  }

  bool get _hasChanges => _readStats(context.read<AppSettings>()) != _initialParsedStats;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_readStats(context.read<AppSettings>()));
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    if (!_hasChanges) {
      Navigator.of(context).pop(null);
      return;
    }

    final shouldDiscard = await showDiscardChangesDialog(context);
    if (!mounted) return;
    if (!shouldDiscard) return;
    Navigator.of(context).pop(null);
  }

  Widget _statField({
    required TextEditingController controller,
    required String label,
    required bool decimal,
    required bool isChanged,
    String? suffixText,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      keyboardType: TextInputType.numberWithOptions(decimal: decimal, signed: false),
      inputFormatters: [decimal ? const UnsignedDecimalInputFormatter() : FilteringTextInputFormatter.digitsOnly],
      controller: controller,
      textInputAction: textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (value) => setState(() {}), // see filled/fillColor and Save button
      onFieldSubmitted: textInputAction == TextInputAction.done ? (_) => _save() : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        visualDensity: VisualDensity.compact,
        suffixText: suffixText,
        fillColor: Theme.of(context).extension<ValueHighlightColors>()!.changedFill,
        filled: isChanged,
      ),
      validator: (String? newValue) {
        final parsed = decimal ? parseLocalizedDouble(newValue ?? '') : int.tryParse(newValue ?? '');
        if (parsed == null) return context.l10n.enterValidValue;
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final original = widget.originalStats;
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Padding(
        padding: EdgeInsets.only(bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SheetHeader(title: l10n.initialStatsTitle),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Text(
                          widget.description ?? l10n.initialStatsComponentDescription,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: _statField(
                                controller: _distanceController,
                                label: l10n.initialStatsDistance,
                                decimal: true,
                                suffixText: appSettings.distanceUnit,
                                isChanged:
                                    original != null &&
                                    parseLocalizedDouble(_distanceController.text) !=
                                        AppSettings.convertDistanceFromMeters(
                                          original.distance,
                                          appSettings.distanceUnit,
                                        ),
                              ),
                            ),
                            Expanded(
                              child: _statField(
                                controller: _elevationGainController,
                                label: l10n.initialStatsElevationGain,
                                decimal: true,
                                suffixText: appSettings.altitudeUnit,
                                isChanged:
                                    original != null &&
                                    parseLocalizedDouble(_elevationGainController.text) !=
                                        AppSettings.convertElevationFromMeters(
                                          original.elevationGain,
                                          appSettings.altitudeUnit,
                                        ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: _statField(
                                controller: _movingTimeController,
                                label: l10n.initialStatsMovingTime,
                                decimal: false,
                                suffixText: "h",
                                isChanged:
                                    original != null &&
                                    int.tryParse(_movingTimeController.text.trim()) != original.movingTime.inHours,
                              ),
                            ),
                            Expanded(
                              child: _statField(
                                controller: _elapsedTimeController,
                                label: l10n.initialStatsElapsedTime,
                                decimal: false,
                                suffixText: "h",
                                isChanged:
                                    original != null &&
                                    int.tryParse(_elapsedTimeController.text.trim()) != original.elapsedTime.inHours,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: _statField(
                                controller: _activityCountController,
                                label: l10n.initialStatsActivityCount,
                                decimal: false,
                                isChanged:
                                    original != null &&
                                    int.tryParse(_activityCountController.text.trim()) != original.activityCount,
                              ),
                            ),
                            Expanded(
                              child: _statField(
                                controller: _kilojoulesController,
                                label: l10n.initialStatsEnergy,
                                decimal: true,
                                suffixText: "kJ",
                                textInputAction: TextInputAction.done,
                                isChanged:
                                    original != null &&
                                    parseLocalizedDouble(_kilojoulesController.text) != original.kilojoules,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _hasChanges ? _save : null,
                      child: Text(l10n.save),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
