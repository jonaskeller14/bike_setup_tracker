import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/app_repository.dart';
import '../models/component.dart';
import '../utils/bike_actions.dart';
import 'garage_bike_card.dart';
import 'garage_uninstalled_card.dart';
import 'chips/bike_list_filter_widget.dart';

class GarageList extends StatefulWidget {
  const GarageList({
    super.key,
  });

  @override
  State<GarageList> createState() => _GarageListState();
}

class _GarageListState extends State<GarageList> {
  String? _componentToShowDetails;
  final ValueNotifier<Component?> _draggedComponentNotifier = ValueNotifier<Component?>(null);

  void _onAcceptWithDetails({String? newBike}) {
    if (_draggedComponentNotifier.value == null) return;
    final Component component =  _draggedComponentNotifier.value!;
    final appRepository = context.read<AppRepository>();
    
    Future.microtask(() {
      appRepository.editComponent(component.copyWithNewInstallation(newBike));
      _draggedComponentNotifier.value = null;
    });
  }

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
    final appRepository = context.watch<AppRepository>();
    final bikesList = appRepository.filteredBikes.values.toList();

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
              componentToShowDetails: _componentToShowDetails,
              onPressedComponent: _onPressedComponent,
              onAcceptWithDetails: _onAcceptWithDetails,
              setDraggedComponent: (Component? c) => _draggedComponentNotifier.value = c,
              draggedComponentNotifier: _draggedComponentNotifier,
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
                  onPressedComponent: _onPressedComponent,
                  onAcceptWithDetails: _onAcceptWithDetails,
                  setDraggedComponent: (Component? c) => _draggedComponentNotifier.value = c,
                  draggedComponentNotifier: _draggedComponentNotifier,
                ),
              ],
            ),
            proxyDecorator: proxyDecorator,
            onReorder: (int oldIndex, int newIndex) => BikeActions.onReorderBikes(context, oldIndex: oldIndex, newIndex: newIndex),
            itemBuilder: (context, index) {
              final bike = bikesList[index];
              return GarageBikeCard(
                key: ValueKey(bike.id),
                bike: bike,
                index: index,
                componentToShowDetails: _componentToShowDetails,
                onPressedComponent: _onPressedComponent,
                onAcceptWithDetails: _onAcceptWithDetails,
                setDraggedComponent: (Component? c) => _draggedComponentNotifier.value = c,
                draggedComponentNotifier: _draggedComponentNotifier,
              );
            },
          );
  }
}
