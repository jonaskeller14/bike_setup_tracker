import 'package:flutter/material.dart';

/// Shape of the chips in the bulk-edit sheets, shared so the partial fill
/// lines up with the chip outline.
const bulkChipShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)));

/// Half-fills [child], a chip with [bulkChipShape], diagonally with the
/// selected color to mark a value only part of a bulk selection carries.
///
/// The chip needs a transparent `backgroundColor` and
/// `MaterialTapTargetSize.shrinkWrap`, so the fill shows through and matches
/// its painted bounds.
class PartialChipFill extends StatelessWidget {
  const PartialChipFill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The chip's own Material falls back to an opaque canvasColor, which would
    // hide the fill behind it, so it is made transparent for these chips only.
    return CustomPaint(
      painter: _PartialFillPainter(color: Theme.of(context).colorScheme.secondaryContainer),
      child: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
        child: child,
      ),
    );
  }
}

/// A small half-filled chip outline for hints that explain [PartialChipFill].
class PartialChipSwatch extends StatelessWidget {
  const PartialChipSwatch({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 28,
      height: 18,
      child: CustomPaint(
        painter: _PartialFillPainter(color: colors.secondaryContainer),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: bulkChipShape.copyWith(side: BorderSide(color: colors.outlineVariant)),
          ),
        ),
      ),
    );
  }
}

class _PartialFillPainter extends CustomPainter {
  const _PartialFillPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(bulkChipShape.getOuterPath(rect));
    canvas.drawPath(
      Path()
        ..moveTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close(),
      Paint()..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PartialFillPainter oldDelegate) => oldDelegate.color != color;
}
