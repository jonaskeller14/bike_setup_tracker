import 'package:flutter/material.dart';

/// Round badge showing how many pins a map cluster contains.
class MapClusterBubble extends StatelessWidget {
  final int count;

  const MapClusterBubble({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.secondaryContainer,
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black26,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: TextStyle(
            color: scheme.onSecondaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
