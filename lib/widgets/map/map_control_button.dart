import 'package:flutter/material.dart';

class MapControlButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;

  const MapControlButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurfaceVariant,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(44, 44),
      ),
      onPressed: onPressed,
      icon: icon,
    );
  }
}
