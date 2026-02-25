import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../models/filtered_data.dart';
import 'garage_bike_card.dart';
import 'garage_uninstalled_card.dart';
import 'chips/bike_list_filter_widget.dart';

class GarageList extends StatefulWidget {
  final Future<void> Function(int oldIndex, int newIndex) onReorderBikes;
  final Future<void> Function() addComponent;

  const GarageList({
    super.key,
    required this.onReorderBikes,
    required this.addComponent,
  });

  @override
  State<GarageList> createState() => _GarageListState();
}

class _GarageListState extends State<GarageList> {
  String? _componentToShowDetails;

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

  void _onPressedComponent(Component component) {
    setState(() {
      _componentToShowDetails = _componentToShowDetails == component.id 
          ? null 
          : component.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = context.watch<FilteredData>();
    final bikesList = filteredData.bikes.values.toList();

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          return Transform.scale(
            scale: scale,
            child: GarageBikeCard(
              bike: bikesList[index],
              index: index,
              elevation: elevation,
              addComponent: widget.addComponent,
              componentToShowDetails: _componentToShowDetails,
              onPressedComponent: _onPressedComponent,
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
            footer: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(height: 50),
                GarageUninstalledCard(
                  componentToShowDetails: _componentToShowDetails, 
                  onPressedComponent: _onPressedComponent
                ),
              ],
            ),
            proxyDecorator: proxyDecorator,
            onReorder: widget.onReorderBikes,
            itemBuilder: (context, index) {
              final bike = bikesList[index];
              return GarageBikeCard(
                key: ValueKey(bike.id),
                bike: bike,
                index: index,
                addComponent: widget.addComponent,
                componentToShowDetails: _componentToShowDetails,
                onPressedComponent: _onPressedComponent,
              );
            },
          );
  }
}
