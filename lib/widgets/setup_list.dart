import 'package:flutter/material.dart';
import '../models/setup.dart';
import '../pages/setup_display_page.dart';
import 'initial_changed_value_legend.dart';
import 'setup_list_card.dart';

class SetupList extends StatefulWidget {
  final Map<String, Setup> setups;
  final Future<void> Function(Setup setup) editSetup;
  final Future<void> Function(Setup setup) restoreSetup;
  final Future<void> Function(Setup setup) removeSetup;
  final bool displayOnlyChanges;
  final Widget filterWidget;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;
  final bool displayRatingAdjustmentValues;
  final bool accending;

  const SetupList({
    super.key,
    required this.setups,
    required this.editSetup,
    required this.restoreSetup,
    required this.removeSetup,
    required this.displayOnlyChanges,
    required this.filterWidget,
    required this.displayBikeAdjustmentValues,
    required this.displayPersonAdjustmentValues,
    required this.displayRatingAdjustmentValues,
    required this.accending,
  });

  @override
  State<SetupList> createState() => _SetupListState();
}

class _SetupListState extends State<SetupList> {
  int _maxItemCount = 10;
  static const int _itemCountIncrement = 10;

  @override
  Widget build(BuildContext context) {
    final visibleItemCount = widget.setups.length.clamp(0, _maxItemCount);
    
    final setups = widget.setups.values.toList();

    return widget.setups.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.filterWidget,
                Expanded(
                  child: Center(
                    child: Text(
                      'No setups yet',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
            children: [
              widget.filterWidget,
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleItemCount,
                itemBuilder: (context, index) {
                  final setup = widget.accending 
                      ? setups[index] 
                      : setups[widget.setups.length - 1 - index];
                  return InkWell(
                    onTap: () async {
                      Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDisplayPage(
                        setupIds: setups.map((s) => s.id).toList(),
                        initialSetup: setup,
                        editSetup: widget.editSetup,
                      )));
                    },
                    child: SetupListCard(
                      setupId: setup.id,
                      editSetup: widget.editSetup,
                      restoreSetup: widget.restoreSetup,
                      removeSetup: widget.removeSetup,
                      displayOnlyChanges: widget.displayOnlyChanges,
                      displayBikeAdjustmentValues: widget.displayBikeAdjustmentValues,
                      displayPersonAdjustmentValues: widget.displayPersonAdjustmentValues,
                      displayRatingAdjustmentValues: widget.displayRatingAdjustmentValues,  
                    ),
                  ); 
                },
              ),
              if (widget.setups.length > visibleItemCount)
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _maxItemCount += _itemCountIncrement),
                    icon: const Icon(Icons.expand_more),
                    label: const Text("Show more"),
                  ),
                ),
              const SizedBox(height: 60),
              const InitialChangedValueLegend(),
            ]
          );
  }
}
