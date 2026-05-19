import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/app_repository.dart';
import '../../utils/rating_actions.dart';
import '../chips/rating_list_filter_widget.dart';
import '../items/rating_list_card.dart';

class RatingList extends StatelessWidget {
  const RatingList({super.key});

  Widget _emptyPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RatingListFilterWidget(),
          Expanded(
            child: Center(
              child: Text(
                'No ratings yet',
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
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            header: const RatingListFilterWidget(),
            proxyDecorator: proxyDecorator,
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
