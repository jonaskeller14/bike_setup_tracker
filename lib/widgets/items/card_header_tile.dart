import 'package:flutter/material.dart';

class CardHeaderTile extends StatelessWidget {
  final Color color;
  final Widget child;

  const CardHeaderTile({
    super.key,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: child,
    );
  }
}
