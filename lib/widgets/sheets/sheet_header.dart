import 'package:flutter/material.dart';
import 'sheet.dart';

class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    this.leadingIcon,
    this.onBack,
    this.showClose = true,
    this.onEdit,
  });

  final String title;
  final Widget? leadingIcon;
  final VoidCallback? onBack;
  final bool showClose;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    // No back button: icon + title flush left, buttons flush right
    if (onBack == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (leadingIcon != null) ...[leadingIcon!, const SizedBox(width: 6)],
            Expanded(child: sheetTitle(context, title)),
            if (onEdit != null) sheetEditButton(context, onPressed: onEdit!),
            if (showClose) sheetCloseButton(context),
          ],
        ),
      );
    }

    // With back button: back left, icon+title centered, buttons right
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          sheetBackButton(context, onPressed: onBack!),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[leadingIcon!, const SizedBox(width: 6)],
                  Flexible(child: sheetTitle(context, title)),
                ],
              ),
            ),
          ),
          if (onEdit != null) sheetEditButton(context, onPressed: onEdit!),
          if (showClose) sheetCloseButton(context),
        ],
      ),
    );
  }
}
