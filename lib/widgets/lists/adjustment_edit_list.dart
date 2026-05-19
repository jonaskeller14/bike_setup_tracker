import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../widgets/items/adjustment_list_card.dart';

class AdjustmentEditList extends StatelessWidget {
  final List<Adjustment> adjustments;
  final Map<String, Adjustment>? initialAdjustments;
  final void Function(Adjustment adjustment) editAdjustment;
  final void Function(Adjustment adjustment) duplicateAdjustment;
  final void Function(Adjustment adjustment) removeAdjustment;
  final void Function(int oldIndex, int newIndex) onReorderAdjustments;

  const AdjustmentEditList({
    super.key,
    required this.adjustments,
    required this.initialAdjustments,
    required this.editAdjustment,
    required this.duplicateAdjustment,
    required this.removeAdjustment,
    required this.onReorderAdjustments,
  });

  @override
  Widget build(BuildContext context) {
    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          return Transform.scale(
            scale: scale,
            child: AdjustmentListCard(
              adjustment: adjustments[index],
              index: index,
              elevation: elevation,
              editAdjustment: editAdjustment,
              duplicateAdjustment: duplicateAdjustment,
              removeAdjustment: removeAdjustment,
            ),
          );
        },
        child: child,
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(0),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      proxyDecorator: proxyDecorator,
      itemCount: adjustments.length,
      itemBuilder: (context, index) {
        final adjustment = adjustments[index];
        return AdjustmentListCard(
          key: ValueKey(adjustment.id),
          adjustment: adjustment, 
          index: index, 
          editAdjustment: editAdjustment, 
          duplicateAdjustment: duplicateAdjustment, 
          removeAdjustment: removeAdjustment
        );
      },
      onReorderItem: onReorderAdjustments,
    );
  }
}
