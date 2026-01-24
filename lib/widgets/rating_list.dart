import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../models/person.dart';
import '../models/bike.dart';
import '../models/rating.dart';
import '../models/component.dart';

class RatingList extends StatefulWidget {
  final Map<String, Rating> ratings;
  final void Function(Rating rating) editRating;
  final void Function(Rating rating) duplicateRating;
  final void Function(Rating rating) removeRating;
  final void Function(int oldIndex, int newIndex) onReorderRating;
  final Widget filterWidget;

  const RatingList({
    super.key,
    required this.ratings,
    required this.editRating,
    required this.duplicateRating,
    required this.removeRating,
    required this.onReorderRating,
    required this.filterWidget,
  });

  @override
  State<RatingList> createState() => _RatingListState();
}

class _RatingListState extends State<RatingList> {
  int _maxItemCount = 10;
  static const int _itemCountIncrement = 10;

  Column _ratingAdjustmentsColumn(Rating rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rating.adjustments.map((adjustment) {
        return Text(
          "● ${adjustment.name}", 
          maxLines: 1, 
          overflow: TextOverflow.ellipsis, 
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItemCount = widget.ratings.length.clamp(0, _maxItemCount);

    final appData = context.watch<AppData>();
    final persons = Map.fromEntries(appData.persons.entries.where((p) => !p.value.isDeleted));
    final bikes = Map.fromEntries(appData.bikes.entries.where((b) => !b.value.isDeleted));
    final components = Map.fromEntries(appData.components.entries.where((entry) => !entry.value.isDeleted));
    
    final List<InkWell> inkWells = <InkWell>[];
    for (int index = 0; index < visibleItemCount; index++) {
      final rating = widget.ratings.values.toList()[index];
      inkWells.add(
        InkWell(
          key: ValueKey(rating.id),
          onTap: null, //TODO
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Rating.iconData),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    rating.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              switch(rating.filterType) {
                                FilterType.global => Icon(Icons.circle_outlined, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                FilterType.bike => Icon(Bike.iconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                FilterType.person => Icon(Person.iconData, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                FilterType.component => Icon((components[rating.filter]?.componentType ?? ComponentType.other).getIconData(), size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                FilterType.componentType => Icon((ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter) ?? ComponentType.other).getIconData(), size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              },

                              const SizedBox(width: 2),
                              
                              Flexible(
                                child: switch(rating.filterType) {
                                  FilterType.global => Text(
                                    "Global",
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  FilterType.bike => Text(
                                    bikes[rating.filter]?.name ?? "-",
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  FilterType.person => Text(
                                    persons[rating.filter]?.name ?? "-",
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  FilterType.component => Text(
                                    components[rating.filter]?.name ?? "-",
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  FilterType.componentType => Text(
                                    ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter)?.value ?? "-",
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit': widget.editRating(rating);
                            case 'duplicate': widget.duplicateRating(rating);
                            case 'remove': widget.removeRating(rating);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 10),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 20),
                                SizedBox(width: 10),
                                Text('Duplicate'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20),
                                SizedBox(width: 10),
                                Text('Remove'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _ratingAdjustmentsColumn(rating),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          final card = inkWells[index].child! as Card;
          return Transform.scale(
            scale: scale,
            child: Card(elevation: elevation, color: card.color, child: card.child),
          );
        },
        child: child,
      );
    }

    return widget.ratings.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.filterWidget,
                Expanded(
                  child: Center(
                    child: Text(
                      'No bikes yet',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          )
        : ReorderableListView.builder(
            itemCount: visibleItemCount,
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            header: widget.filterWidget,
            footer: widget.ratings.length > visibleItemCount
                ? Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _maxItemCount += _itemCountIncrement),
                      icon: const Icon(Icons.expand_more),
                      label: const Text("Show more"),
                    ),
                  )
                : null,
            proxyDecorator: proxyDecorator,
            onReorder: widget.onReorderRating,
            itemBuilder: (context, index) {
              return inkWells[index];
            },
          );
  }
}
