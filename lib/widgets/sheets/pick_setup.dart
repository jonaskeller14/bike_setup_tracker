import 'package:flutter/material.dart';

import '../../models/setup.dart';
import 'setup_day_list.dart';
import 'sheet_header.dart';

Future<Setup?> showPickSetupSheet(
  BuildContext context, {
  required String title,
  required List<Setup> options,
  String? selectedId,
  String? suggestedId,
  Set<String> disabledIds = const {},
  Map<String, String> sideLabels = const {},
  bool showBikeNames = false,
  String Function(String setupId)? semanticsIdentifier,
}) {
  return showModalBottomSheet<Setup>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: title),
          const SizedBox(height: 8),
          Flexible(
            child: SetupDayList(
              setups: options,
              tileBuilder: (setup) {
                final selected = setup.id == selectedId;
                return ColoredBox(
                  color: selected ? Theme.of(context).colorScheme.secondaryContainer : Colors.transparent,
                  child: SetupPickTile(
                    key: Key('pick-setup-option-${setup.id}'),
                    setup: setup,
                    badges: [
                      if (sideLabels[setup.id] case final label?) _SideBadge(label: label),
                      if (setup.id == suggestedId) const _SuggestedBadge(),
                    ],
                    showBikeName: showBikeNames,
                    selected: selected,
                    semanticsIdentifier: semanticsIdentifier?.call(setup.id),
                    trailing: selected
                        ? const Icon(Icons.check, size: 20)
                        : const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: disabledIds.contains(setup.id) ? null : () => Navigator.pop(context, setup),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _SideBadge extends StatelessWidget {
  final String label;

  const _SideBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SuggestedBadge extends StatelessWidget {
  const _SuggestedBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Text(
        'Suggested',
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
