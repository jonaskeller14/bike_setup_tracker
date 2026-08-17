import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/setup.dart';
import '../../repositories/app_repository.dart';
import '../../services/setup_comparison_service.dart';
import '../compare_setups/setup_comparison_header.dart';
import '../compare_setups/setup_comparison_section.dart';
import 'sheet.dart';

Future<void> showCompareSetupsSheet(
  BuildContext context, {
  Setup? setupA,
  required Setup setupB,
}) async {
  final repository = context.read<AppRepository>();
  final resolution = SetupComparisonService.resolveTargets(
    setupA: setupA,
    setupB: setupB,
    setups: repository.setups.values,
  );
  if (resolution is! SetupComparisonTargets) {
    final message = resolution is SetupComparisonTargetsEqualInput
        ? 'Choose two different setups to compare.'
        : 'No current setup is available to compare.';
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
    return;
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => CompareSetups(
      setupAId: resolution.setupA.id,
      setupBId: resolution.setupB.id,
    ),
  );
}

class CompareSetups extends StatefulWidget {
  final String setupAId;
  final String setupBId;

  const CompareSetups({
    super.key,
    required this.setupAId,
    required this.setupBId,
  });

  @override
  State<CompareSetups> createState() => _CompareSetupsState();
}

class _CompareSetupsState extends State<CompareSetups> {
  bool _differencesOnly = true;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AppRepository>();
    final setupA = repository.setups[widget.setupAId];
    final setupB = repository.setups[widget.setupBId];
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    if (setupA == null || setupB == null) {
      return SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SheetFilterEmptyHint(
            icon: Icons.error_outline,
            title: 'A setup is no longer available',
            hint: 'Close this sheet and choose two available setups to compare.',
            onTap: () => Navigator.pop(context),
          ),
        ),
      );
    }

    final comparison = SetupComparisonService.build(
      setupA: setupA,
      setupB: setupB,
      components: repository.components.values,
      persons: repository.persons.values,
    );
    final groups = comparison.visibleGroups(differencesOnly: _differencesOnly);

    return SizedBox(
      height: maxHeight,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 0,
            collapsedHeight: 0,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Theme.of(context).colorScheme.surface,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(232),
              child: SetupComparisonHeader(
                setupA: setupA,
                setupB: setupB,
                differenceCount: comparison.differenceCount,
                differencesOnly: _differencesOnly,
                onDifferencesOnlyChanged: (value) {
                  setState(() => _differencesOnly = value);
                },
              ),
            ),
          ),
          if (groups.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: SheetFilterEmptyHint(
                  icon: Icons.check_circle_outline,
                  title: 'These setups have no differences',
                  hint: 'Show every recorded value instead.',
                  onTap: () => setState(() => _differencesOnly = false),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.list(
                children: [
                  for (final group in groups)
                    SetupComparisonSection(
                      group: group,
                      differencesOnly: _differencesOnly,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
