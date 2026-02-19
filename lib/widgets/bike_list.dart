import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/bike.dart';
import 'bike_list_card.dart';
import 'chips/bike_list_filter_widget.dart';

class BikeList extends StatelessWidget {
  final Map<String, Bike> bikes;
  final Future<void> Function(Bike bike) editBike;
  final Future<void> Function(Bike bike) removeBike;
  final Future<void> Function(int oldIndex, int newIndex) onReorderBikes;

  const BikeList({
    super.key,
    required this.bikes,
    required this.editBike,
    required this.removeBike,
    required this.onReorderBikes,
  });

  Widget _emptyPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BikeListFilterWidget(),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final bikesList = bikes.values.toList();

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          return Transform.scale(
            scale: scale,
            child: BikeListCard(
              bike: bikesList[index],
              index: index,
              elevation: elevation,
              editBike: editBike, 
              removeBike: removeBike,
            ),
          );
        },
        child: child,
      );
    }

    return bikesList.isEmpty
        ? _emptyPlaceholder(context)
        : ReorderableListView.builder(
            itemCount: bikesList.length,
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            header: BikeListFilterWidget(),
            proxyDecorator: proxyDecorator,
            onReorder: onReorderBikes,
            itemBuilder: (context, index) {
              final bike = bikesList[index];
              return BikeListCard(
                key: ValueKey(bike.id),
                bike: bike,
                index: index,
                editBike: editBike,
                removeBike: removeBike,
              );
            },
          );
  }
}
