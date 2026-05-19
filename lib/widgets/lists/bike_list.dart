import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/app_repository.dart';
import '../../utils/bike_actions.dart';
import '../chips/bike_list_filter_widget.dart';
import '../items/bike_list_card.dart';

class BikeList extends StatelessWidget {
  const BikeList({super.key});

  Widget _emptyPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BikeListFilterWidget(),
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
    final appRepository = context.watch<AppRepository>();
    final bikesList = appRepository.bikes.values.toList();

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
            header: const BikeListFilterWidget(),
            proxyDecorator: proxyDecorator,
            onReorderItem: (int oldIndex, int newIndex) => BikeActions.onReorderBikes(context, oldIndex: oldIndex, newIndex: newIndex),
            itemBuilder: (context, index) {
              final bike = bikesList[index];
              return BikeListCard(
                key: ValueKey(bike.id),
                bike: bike,
                index: index,
              );
            },
          );
  }
}
