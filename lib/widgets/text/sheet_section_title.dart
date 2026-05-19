import 'package:flutter/material.dart';

class SheetSectionTitle extends StatelessWidget {
  final String title;

  const SheetSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsGeometry.only(top: 12, bottom: 6),
      child: Text(
        title, 
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
      ),
    );
  }
}
