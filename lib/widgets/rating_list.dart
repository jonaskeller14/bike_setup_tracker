import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../models/person.dart';
import '../models/bike.dart';
import '../models/rating.dart';
import '../models/component.dart';

const defaultVisibleCount = 3;

class RatingList extends StatefulWidget {
  final Map<String, Person> persons;
  final Map<String, Bike> bikes;
  final Map<String, Rating> ratings;
  final List<Component> components;
  final void Function(Rating rating) editRating;
  final void Function(Rating rating) duplicateRating;
  final void Function(Rating rating) removeRating;
  final void Function(int oldIndex, int newIndex) onReorderRating;

  const RatingList({
    super.key,
    required this.persons,
    required this.bikes,
    required this.ratings,
    required this.components,
    required this.editRating,
    required this.duplicateRating,
    required this.removeRating,
    required this.onReorderRating,
  });

  @override
  State<RatingList> createState() => _RatingListState();
}

class _RatingListState extends State<RatingList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visibleCount = _expanded
        ? widget.ratings.length
        : widget.ratings.length.clamp(0, defaultVisibleCount);
    
    final List<GestureDetector> gestureDetectors = <GestureDetector>[];
    for (var index = 0; index < visibleCount; index++) {
      final rating = widget.ratings.values.toList()[index];
      gestureDetectors.add(
        GestureDetector(
          key: ValueKey(rating.id),
          onTap: null, //TODO
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
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
                            FilterType.component => Component.getIcon(widget.components.firstWhereOrNull((c) => c.id == rating.filter)?.componentType ?? ComponentType.other, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            FilterType.componentType => Component.getIcon(ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter) ?? ComponentType.other, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          },

                          const SizedBox(width: 2),
                          
                          switch(rating.filterType) {
                            FilterType.global => Text(
                              "Global",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            FilterType.bike => Text(
                              widget.bikes[rating.filter]?.name ?? "-",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            FilterType.person => Text(
                              widget.persons[rating.filter]?.name ?? "-",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            FilterType.component => Text(
                              widget.components.firstWhereOrNull((c) => c.id == rating.filter)?.name ?? "-",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            FilterType.componentType => Text(
                              ComponentType.values.firstWhereOrNull((ct) => ct.toString() == rating.filter)?.value ?? "-",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          },
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
              )
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
          final card = gestureDetectors[index].child! as Card;
          return Transform.scale(
            scale: scale,
            child: Card(elevation: elevation, color: card.color, child: card.child),
          );
        },
        child: child,
      );
    }

    return ReorderableListView.builder(
      itemCount: visibleCount,
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
      footer: widget.ratings.length > defaultVisibleCount
        ? Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            icon: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
            ),
            label: Text(_expanded ? "Show less" : "Show more"),
          ),
        )
        : null,
      proxyDecorator: proxyDecorator,
      onReorder: widget.onReorderRating,
      itemBuilder: (context, index) {
        return gestureDetectors[index];
      },
    );
  }
}
