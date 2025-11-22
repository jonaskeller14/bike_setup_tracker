import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/adjustment.dart';

class AdjustmentEditList extends StatefulWidget {
  final List<Adjustment> adjustments;
  final void Function(Adjustment adjustment) editAdjustment;
  final void Function(Adjustment adjustment) removeAdjustment;
  final void Function(List<Adjustment> newOrder) onReorderAdjustments;

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
  late List<Adjustment> _adjustments;

  @override
  void initState() {
    super.initState();
    _adjustments = List.of(widget.adjustments);
  }

  @override
  Widget build(BuildContext context) {
    final List<Card> cards = <Card>[
      for (int index = 0; index < _adjustments.length; index += 1)
        Card(
          key: ValueKey(_adjustments[index]),
          child: ListTile(
            leading: _adjustments[index].getIcon(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              _adjustments[index].name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _adjustments[index].getProperties(),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_handle),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      widget.editAdjustment(_adjustments[index]);
                    } else if (value == 'remove') {
                      widget.removeAdjustment(_adjustments[index]);
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

    return ReorderableListView(
      padding: const EdgeInsets.all(0),
      proxyDecorator: proxyDecorator,
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = _adjustments.removeAt(oldIndex);
          _adjustments.insert(newIndex, item);
          widget.onReorderAdjustments(_adjustments);
        });
      },
      children: cards,
    );
  }
}
