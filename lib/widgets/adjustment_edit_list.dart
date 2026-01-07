import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/adjustment/adjustment.dart';

class AdjustmentEditList extends StatefulWidget {
  final List<Adjustment> adjustments;
  final void Function(Adjustment adjustment) editAdjustment;
  final void Function(Adjustment adjustment) removeAdjustment;
  final void Function(int oldIndex, int newIndex) onReorderAdjustments;

  const AdjustmentEditList({
    super.key,
    required this.adjustments,
    required this.editAdjustment,
    required this.removeAdjustment,
    required this.onReorderAdjustments,
  });

  @override
  State<AdjustmentEditList> createState() => _AdjustmentEditListState();
}

class _AdjustmentEditListState extends State<AdjustmentEditList> {
  @override
  Widget build(BuildContext context) {
    final List<Card> cards = <Card>[
      for (int index = 0; index < widget.adjustments.length; index++)
        Card(
          key: ValueKey(widget.adjustments[index]),
          child: ListTile(
            leading: widget.adjustments[index].getIcon(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              widget.adjustments[index].name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              widget.adjustments[index].getProperties(),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                    if (value == 'edit') {
                      widget.editAdjustment(widget.adjustments[index]);
                    } else if (value == 'remove') {
                      widget.removeAdjustment(widget.adjustments[index]);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
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
            ),
          ),
        ),
    ];

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.03, animValue)!;
          return Transform.scale(
            scale: scale,
            child: Card(elevation: elevation, color: cards[index].color, child: cards[index].child),
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
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
      onReorder: widget.onReorderAdjustments,
    );
  }
}
