import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../repositories/app_repository.dart';
import '../../utils/bike_actions.dart';
import '../chips/bike_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../hints/getting_started_guide_hint.dart';
import '../items/bike_list_card.dart';

class BikeList extends StatelessWidget {
  const BikeList({super.key});

  Widget _emptyPlaceholder(BuildContext context) {
    final showGuide = context.watch<AppSettings>().showGettingStartedGuideHint;
    if (showGuide) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BikeListFilterWidget(),
            SizedBox(height: 8),
            GettingStartedGuideHint(),
          ],
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(child: BikeListFilterWidget()),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: EmptyStatePlaceholder(
              icon: Bike.iconData,
              title: 'No bikes yet',
              subtitle: 'Add your first bike to get started.',
              actionLabel: 'Add a bike',
              onAction: () => BikeActions.addBike(context),
            ),
          ),
        ),
      ],
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
            header: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                GettingStartedGuideHint(),
                BikeListFilterWidget(),
              ],
            ),
            proxyDecorator: proxyDecorator,
            onReorderStart: (_) => unawaited(HapticFeedback.lightImpact()),
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
