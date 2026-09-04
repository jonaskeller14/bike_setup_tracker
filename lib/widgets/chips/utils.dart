import 'package:flutter/material.dart';

class ChipLoadingIndicator extends StatelessWidget {
  const ChipLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final double indicatorSize = DefaultTextStyle.of(context).style.fontSize ?? 15;
    return SizedBox(
      width: indicatorSize,
      height: indicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: indicatorSize / 6, 
      ),
    );
  }
}
