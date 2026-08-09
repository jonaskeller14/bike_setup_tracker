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
    final hasTrailing = onEdit != null || showClose;
    final centerTitle = onBack != null || !hasTrailing;

    final titleRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[leadingIcon!, const SizedBox(width: 6)],
        Flexible(child: sheetTitle(context, title)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (onBack != null) sheetBackButton(context, onPressed: onBack!),
          Expanded(
            child: centerTitle ? Center(child: titleRow) : titleRow,
          ),
          if (onEdit != null) sheetEditButton(context, onPressed: onEdit!),
          if (showClose) sheetCloseButton(context),
        ],
      ),
    );
  }
}
