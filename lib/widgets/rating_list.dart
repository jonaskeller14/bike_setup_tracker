import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/rating.dart';
import 'chips/rating_list_filter_widget.dart';
import 'rating_list_card.dart';

class RatingList extends StatelessWidget {
  final Map<String, Rating> ratings;
  final Future<void> Function(Rating rating) editRating;
  final Future<void> Function(Rating rating) duplicateRating;
  final Future<void> Function(Rating rating) removeRating;
  final Future<void> Function(int oldIndex, int newIndex) onReorderRating;

  const RatingList({
    super.key,
    required this.ratings,
    required this.editRating,
    required this.duplicateRating,
    required this.removeRating,
    required this.onReorderRating,
  });

  Widget _emptyPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingListFilterWidget(),
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
    final ratingsList = ratings.values.toList();

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
              editRating: editRating,
              duplicateRating: duplicateRating,
              removeRating: removeRating,
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
            header: RatingListFilterWidget(),
            proxyDecorator: proxyDecorator,
            onReorder: onReorderRating,
            itemBuilder: (context, index) {
              final rating = ratingsList[index];
              return RatingListCard(
                key: ValueKey(rating.id),
                rating: rating,
                index: index,
                editRating: editRating,
                duplicateRating: duplicateRating,
                removeRating: removeRating
              );
            },
          );
  }
}
