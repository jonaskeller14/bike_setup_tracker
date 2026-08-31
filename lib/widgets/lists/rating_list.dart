import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/rating.dart';
import '../../repositories/app_repository.dart';
import '../../utils/rating_actions.dart';
import '../chips/rating_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../items/rating_list_card.dart';

class RatingList extends StatelessWidget {
  const RatingList({super.key});

  Widget _emptyPlaceholder(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverToBoxAdapter(child: RatingListFilterWidget()),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: EmptyStatePlaceholder(
              icon: Rating.iconData,
              title: 'No ratings yet',
              subtitle: 'Create a rating template to evaluate your setups.',
              actionLabel: 'Add a rating',
              onAction: () => RatingActions.addRating(context),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final ratingsList = appRepository.filteredRatings.values.toList();

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          return Transform.scale(
            scale: scale,
            child: RatingListCard(
              rating: ratingsList[index],
              index: index,
              elevation: elevation,
            ),
          );
        },
        child: child,
      );
    }

    return ratingsList.isEmpty
        ? _emptyPlaceholder(context)
        : ReorderableListView.builder(
            itemCount: ratingsList.length,
            padding: const EdgeInsets.only(left: 16, top: 8, right: 16, bottom: 16+100),
            header: const RatingListFilterWidget(),
            proxyDecorator: proxyDecorator,
            onReorderStart: (_) => unawaited(HapticFeedback.lightImpact()),
            onReorderItem: (int oldIndex, int newIndex) => RatingActions.onReorderRating(context, oldIndex: oldIndex, newIndex: newIndex),
            itemBuilder: (context, index) {
              final rating = ratingsList[index];
              return RatingListCard(
                key: ValueKey(rating.id),
                rating: rating,
                index: index,
              );
            },
          );
  }
}
