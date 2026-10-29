import 'dart:math';

import 'package:flutter/material.dart';

import 'sheet.dart';

class SheetHeader extends StatelessWidget {
  static const _buttonExtent = kMinInteractiveDimension;
  static const _iconExtent = 24.0;

  const SheetHeader({
    super.key,
    required this.title,
    this.leadingIcon,
    this.onBack,
    this.showClose = true,
    this.onEdit,
    this.actions = const [],
    this.titleMaxLines,
  });

  final String title;
  final int? titleMaxLines;
  final Widget? leadingIcon;
  final VoidCallback? onBack;
  final bool showClose;
  final VoidCallback? onEdit;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final hasTrailing = actions.isNotEmpty || onEdit != null || showClose;
    final hasButtons = onBack != null || hasTrailing;
    final centerTitle = onBack != null || !hasTrailing;

    // Buttons are top-aligned so a wrapped title keeps them beside its first
    // line; the title and icon are centered within the first button-high row.
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    final lineHeight = MediaQuery.textScalerOf(context).scale(titleStyle?.fontSize ?? 22) * (titleStyle?.height ?? 1);
    final titleTop = hasButtons ? max(0.0, (_buttonExtent - lineHeight) / 2) : 0.0;
    final iconTop = hasButtons ? (_buttonExtent - _iconExtent) / 2 : 0.0;

    final titleRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leadingIcon != null) ...[
          Padding(padding: EdgeInsets.only(top: iconTop), child: leadingIcon),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Padding(
            padding: EdgeInsets.only(top: titleTop),
            child: sheetTitle(context, title, maxLines: titleMaxLines),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null) sheetBackButton(context, onPressed: onBack!),
          Expanded(
            child: centerTitle ? Center(child: titleRow) : titleRow,
          ),
          ...actions,
          if (onEdit != null) sheetEditButton(context, onPressed: onEdit!),
          if (showClose) sheetCloseButton(context),
        ],
      ),
    );
  }
}
