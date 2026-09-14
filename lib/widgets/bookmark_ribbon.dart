import 'package:flutter/material.dart';

class BookmarkRibbon extends StatelessWidget {
  static const double width = 12;
  static const double height = 16;

  /// Depth of the V cut into the bottom edge.
  static const double _notch = 5;

  final Color? color;

  const BookmarkRibbon({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(width, height),
      painter: _BookmarkRibbonPainter(color ?? Theme.of(context).colorScheme.primary),
    );
  }
}

class _BookmarkRibbonPainter extends CustomPainter {
  final Color color;

  const _BookmarkRibbonPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - BookmarkRibbon._notch)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BookmarkRibbonPainter oldDelegate) => oldDelegate.color != color;
}
