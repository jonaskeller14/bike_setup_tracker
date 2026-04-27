import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/person.dart';
import '../models/rating.dart';
import 'lists/adjustment_set_list.dart';
import 'display_adjustment/display_dangling_adjustment.dart';
import 'initial_changed_value_legend.dart';
import '../models/adjustment/adjustment.dart';

class TabContentWrapper extends StatefulWidget {
  final Widget child;
  const TabContentWrapper({super.key, required this.child});

  @override
  State<TabContentWrapper> createState() => _TabContentWrapperState();
}

class _TabContentWrapperState extends State<TabContentWrapper> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; 

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// A shared scaffold for all setup page tabs to ensure consistent layout and behavior.
class _SetupTabScaffold extends StatelessWidget {
  final String scrollKey;
  final List<Widget> children;
  final bool showLegend;

  const _SetupTabScaffold({
    required this.scrollKey,
    required this.children,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    return TabContentWrapper(
      child: CustomScrollView(
        key: PageStorageKey<String>(scrollKey),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...children,
                  if (showLegend) const InitialChangedValueLegend(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildEmptyPlaceholder(BuildContext context, String message) {
  return SizedBox(
    height: 100,
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
      ),
    ),
  );
}

class SetupBikeTab extends StatelessWidget {
  final List<Component> bikeComponents;
  final Map<String, dynamic> bikeAdjustmentValues;
  final Map<String, dynamic> previousBikeAdjustmentValues;
  final Map<String, dynamic> initialBikeAdjustmentValues;
  final Map<String, dynamic> danglingBikeAdjustmentValues;
  final void Function({required Adjustment adjustment, required dynamic newValue}) onAdjustmentValueChanged;
  final void Function({required Adjustment adjustment}) onRemoveFromAdjustmentValues;
  final Function(String) onDanglingRemove; 

  const SetupBikeTab({
    super.key,
    required this.bikeComponents,
    required this.bikeAdjustmentValues,
    required this.previousBikeAdjustmentValues,
    required this.initialBikeAdjustmentValues,
    required this.danglingBikeAdjustmentValues,
    required this.onAdjustmentValueChanged,
    required this.onRemoveFromAdjustmentValues,
    required this.onDanglingRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _SetupTabScaffold(
      scrollKey: 'tab1_bike',
      children: [
        if (bikeComponents.isEmpty)
          _buildEmptyPlaceholder(context, 'No components available.')
        else
          ...bikeComponents.map((bikeComponent) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   ListTile(
                    title: Text(bikeComponent.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(Intl.plural(
                      bikeComponent.adjustments.length,
                      zero: "No adjustments yet.",
                      one: "1 adjustment",
                      other: '${bikeComponent.adjustments.length} adjustments',
                    )),
                    leading: Icon(bikeComponent.componentType.getIconData()),
                    enabled: bikeComponent.adjustments.isNotEmpty,
                  ),
                  AdjustmentSetList(
                    key: ValueKey(Object.hash(bikeComponent.id, Object.hashAll(previousBikeAdjustmentValues.values), Object.hashAll(bikeAdjustmentValues.values))),
                    adjustments: bikeComponent.adjustments,
                    initialAdjustmentValues: previousBikeAdjustmentValues,
                    adjustmentValues: bikeAdjustmentValues,
                    onAdjustmentValueChanged: onAdjustmentValueChanged,
                    removeFromAdjustmentValues: onRemoveFromAdjustmentValues,
                  ),
                ],
              ),
            );
          }),
        if (danglingBikeAdjustmentValues.isNotEmpty)
          Opacity(
            opacity: 0.4,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text("Dangling Adjustment Values", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(Intl.plural(
                      danglingBikeAdjustmentValues.length, 
                      one: "1 adjustment value found that is not associated with this bike. Cannot be edited.",
                      other: "${danglingBikeAdjustmentValues.length} adjustment values found that are not associated with this bike. Cannot be edited.",
                    )),
                    leading: const Icon(Icons.question_mark),
                  ),
                  ...danglingBikeAdjustmentValues.entries.map((danglingAdjustmentValue) {
                    return DisplayDanglingAdjustmentWidget(
                      name: danglingAdjustmentValue.key, 
                      initialValue: initialBikeAdjustmentValues[danglingAdjustmentValue.key], 
                      value: danglingAdjustmentValue.value,
                      onRemove: () {
                        onDanglingRemove(danglingAdjustmentValue.key);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class SetupPersonTab extends StatelessWidget {
  final String? personId;
  final Map<String, Person> persons;
  final Map<String, dynamic> personAdjustmentValues;
  final Map<String, dynamic> previousPersonAdjustmentValues;
  final Map<String, dynamic> initialPersonAdjustmentValues;
  final Map<String, dynamic> danglingPersonAdjustmentValues;
  final void Function({required Adjustment adjustment, required dynamic newValue}) onAdjustmentValueChanged;
  final void Function({required Adjustment adjustment}) onRemoveFromAdjustmentValues;
  final VoidCallback changeListener;
  final Function(String) onDanglingRemove;

  const SetupPersonTab({
    super.key,
    required this.personId,
    required this.persons,
    required this.personAdjustmentValues,
    required this.previousPersonAdjustmentValues,
    required this.initialPersonAdjustmentValues,
    required this.danglingPersonAdjustmentValues,
    required this.onAdjustmentValueChanged,
    required this.onRemoveFromAdjustmentValues,
    required this.changeListener,
    required this.onDanglingRemove,
  });

  @override
  Widget build(BuildContext context) {
    final person = persons[personId];
    return _SetupTabScaffold(
      scrollKey: 'tab2_person',
      children: [
        if (person == null)
           _buildEmptyPlaceholder(context, 'No person linked to this bike. \nExit and edit bike to link a person.')
        else
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(Intl.plural(
                    person.adjustments.length,
                    zero: "No attributes yet.",
                    one: "1 attribute",
                    other: '${person.adjustments.length} attributes',
                  )),
                  leading: const Icon(Person.iconData),
                  enabled: person.adjustments.isNotEmpty,
                ),
                AdjustmentSetList(
                  key: ValueKey(Object.hash(personId, Object.hashAll(previousPersonAdjustmentValues.values), Object.hashAll(personAdjustmentValues.values))),
                  adjustments: person.adjustments,
                  initialAdjustmentValues: previousPersonAdjustmentValues,
                  adjustmentValues: personAdjustmentValues,
                  onAdjustmentValueChanged: onAdjustmentValueChanged,
                  removeFromAdjustmentValues: onRemoveFromAdjustmentValues,
                ),
              ],
            ),
          ),
        if (danglingPersonAdjustmentValues.isNotEmpty)
          Opacity(
            opacity: 0.4,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text("Dangling Attribute Values", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(Intl.plural(
                      danglingPersonAdjustmentValues.length, 
                      one: "1 attribute value found that is not associated with this person. Cannot be edited.",
                      other: "${danglingPersonAdjustmentValues.length} attribute values found that are not associated with this person. Cannot be edited.",
                    )),
                    leading: const Icon(Icons.question_mark),
                  ),
                  ...danglingPersonAdjustmentValues.entries.map((danglingAdjustmentValue) {
                    return DisplayDanglingAdjustmentWidget(
                      name: danglingAdjustmentValue.key, 
                      initialValue: initialPersonAdjustmentValues[danglingAdjustmentValue.key], 
                      value: danglingAdjustmentValue.value,
                      onRemove: () {
                        onDanglingRemove(danglingAdjustmentValue.key);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class SetupRatingTab extends StatelessWidget {
  final Map<String, Rating> filteredRatings;
  final Map<String, Bike> bikes;
  final Map<String, Person> persons;
  final Map<String, Component> components;
  final Map<String, dynamic> ratingAdjustmentValues;
  final Map<String, dynamic> previousBikeAdjustmentValues; // used for key
  final Map<String, dynamic> initialRatingAdjustmentValues;
  final Map<String, dynamic> danglingRatingAdjustmentValues;
  final void Function({required Adjustment adjustment, required dynamic newValue}) onAdjustmentValueChanged;
  final void Function({required Adjustment adjustment}) onRemoveFromAdjustmentValues;
  final VoidCallback changeListener;
  final Function(String) onDanglingRemove;

  const SetupRatingTab({
    super.key,
    required this.filteredRatings,
    required this.bikes,
    required this.persons,
    required this.components,
    required this.ratingAdjustmentValues,
    required this.previousBikeAdjustmentValues,
    required this.initialRatingAdjustmentValues,
    required this.danglingRatingAdjustmentValues,
    required this.onAdjustmentValueChanged,
    required this.onRemoveFromAdjustmentValues,
    required this.changeListener,
    required this.onDanglingRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _SetupTabScaffold(
      scrollKey: 'tab3_rating',
      showLegend: false,
      children: [
        if (filteredRatings.isEmpty)
          _buildEmptyPlaceholder(context, 'No ratings available. \nExit and add rating procedure.')
        else
          ...filteredRatings.values.map((rating) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(rating.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(Intl.plural(
                          rating.adjustments.length,
                          zero: "No adjustments yet.",
                          one: "1 adjustment",
                          other: '${rating.adjustments.length} adjustments',
                        )),
                        const Spacer(),
                        _getFilterIcon(rating),
                        const SizedBox(width: 2),
                        _getFilterText(rating),
                      ],
                    ),
                    leading: const Icon(Rating.iconData),
                    enabled: rating.adjustments.isNotEmpty,
                  ),
                  AdjustmentSetList(
                    key: ValueKey(Object.hash(rating.id, Object.hashAll(previousBikeAdjustmentValues.values), Object.hashAll(ratingAdjustmentValues.values))),
                    adjustments: rating.adjustments,
                    initialAdjustmentValues: initialRatingAdjustmentValues,
                    adjustmentValues: ratingAdjustmentValues,
                    onAdjustmentValueChanged: onAdjustmentValueChanged,
                    removeFromAdjustmentValues: onRemoveFromAdjustmentValues,
                  ),
                ],
              ),
            );
          }),
        if (danglingRatingAdjustmentValues.isNotEmpty)
          Opacity(
            opacity: 0.4,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text("Dangling Rating Values", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(Intl.plural(
                      danglingRatingAdjustmentValues.length, 
                      one: "1 rating value found that is not associated with this bike/person/components. Cannot be edited.",
                      other: "${danglingRatingAdjustmentValues.length} rating values found that are not associated with this bike/person/components. Cannot be edited.",
                    )),
                    leading: const Icon(Icons.question_mark),
                  ),
                  ...danglingRatingAdjustmentValues.entries.map((danglingAdjustmentValue) {
                    return DisplayDanglingAdjustmentWidget(
                      name: danglingAdjustmentValue.key, 
                      initialValue: null,
                      value: danglingAdjustmentValue.value,
                      onRemove: () {
                        onDanglingRemove(danglingAdjustmentValue.key);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _getFilterIcon(Rating rating) {
    return switch (rating.filterType) {
      FilterType.bike => const Icon(Bike.iconData),
      FilterType.person => const Icon(Person.iconData),
      FilterType.component => Icon((components[rating.filter]?.componentType ?? ComponentType.other).getIconData()),
      FilterType.componentType => Icon((ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter) ?? ComponentType.other).getIconData()),
      FilterType.global => const SizedBox.shrink(),
    };
  }

  Widget _getFilterText(Rating rating) {
    return switch (rating.filterType) {
      FilterType.bike => Text(bikes[rating.filter]?.name ?? "-", overflow: TextOverflow.ellipsis),
      FilterType.person => Text(persons[rating.filter]?.name ?? "-", overflow: TextOverflow.ellipsis),
      FilterType.componentType => Text(
        ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter)?.label ?? "-",
        overflow: TextOverflow.ellipsis,
      ),
      FilterType.component => Text(
        components[rating.filter]?.name ?? "-",
        overflow: TextOverflow.ellipsis,
      ),
      FilterType.global => const SizedBox.shrink(),
    };
  }
}
