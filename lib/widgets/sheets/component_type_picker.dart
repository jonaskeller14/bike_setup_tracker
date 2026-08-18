import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/component.dart';
import '../../theme.dart';
import '../text/sheet_section_title.dart';
import 'sheet_header.dart';

/// Lets the user pick a single [ComponentType], grouped by category.
/// Returns the picked type, or null if the sheet was dismissed.
///
/// Highlighting mirrors the type field on ComponentPage (and the categorical
/// value sheet). Pass [initialComponentType] — the saved type — to enable it;
/// leave it null (adding a component) for a plain, unhighlighted sheet:
///   still the saved type                 -> plain selected look
///   picked over the saved type           -> picked chip uses `changed`
///   the saved type, currently not picked -> "previous value" marker
Future<ComponentType?> showComponentTypePickerSheet({
  required BuildContext context,
  ComponentType? selectedComponentType,
  ComponentType? initialComponentType,
}) {
  return showModalBottomSheet<ComponentType>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _ComponentTypePickerSheet(
      selectedComponentType: selectedComponentType,
      initialComponentType: initialComponentType,
    ),
  );
}

class _ComponentTypePickerSheet extends StatefulWidget {
  final ComponentType? selectedComponentType;
  final ComponentType? initialComponentType;

  const _ComponentTypePickerSheet({
    this.selectedComponentType,
    this.initialComponentType,
  });

  @override
  State<_ComponentTypePickerSheet> createState() => _ComponentTypePickerSheetState();
}

class _ComponentTypePickerSheetState extends State<_ComponentTypePickerSheet> {
  late ComponentType? _selected = widget.selectedComponentType;

  bool _popping = false;

  void _select(ComponentType type) {
    if (_popping) return;
    _popping = true;
    unawaited(HapticFeedback.selectionClick());
    // Show the picked chip briefly before closing.
    setState(() => _selected = type);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) Navigator.pop(context, type);
    });
  }

  @override
  Widget build(BuildContext context) {
    final highlights = Theme.of(context).extension<ValueHighlightColors>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Select Component Type'),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ComponentTypeCategory.values.map((category) {
                  final typesInCategory =
                      ComponentType.values.where((t) => t.category == category).toList();
                  if (typesInCategory.isEmpty) return const SizedBox.shrink();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SheetSectionTitle(title: category.label),
                      Wrap(
                        spacing: 6,
                        children: typesInCategory.map((type) {
                          final bool isSelected = type == _selected;
                          return _TypeChip(
                            componentType: type,
                            selected: isSelected,
                            highlightColor: widget.initialComponentType == null ||
                                    !isSelected ||
                                    type == widget.initialComponentType
                                ? null
                                : highlights?.changed ?? Colors.orange,
                            isPrevious: !isSelected && type == widget.initialComponentType,
                            onTap: () => _select(type),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final ComponentType componentType;
  final bool selected;

  /// Tint for a picked chip that differs from the saved type; `null` leaves the
  /// plain selected look (type unchanged).
  final Color? highlightColor;

  /// The saved type, currently not picked. Stays a normal, tappable chip, just
  /// marked so the old value stays visible.
  final bool isPrevious;
  final VoidCallback onTap;

  const _TypeChip({
    required this.componentType,
    required this.selected,
    required this.highlightColor,
    required this.isPrevious,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color? labelColor = highlightColor ?? (isPrevious ? scheme.onSurfaceVariant : null);
    final TextStyle? labelStyle =
        labelColor == null ? null : theme.textTheme.labelLarge?.copyWith(color: labelColor);
    final BorderSide? side = highlightColor != null
        ? BorderSide(color: highlightColor!)
        : (isPrevious ? BorderSide(color: scheme.outline) : null);

    final Widget chip = ChoiceChip(
      label: Text(componentType.label),
      selected: selected,
      avatar: selected
          ? null
          : Icon(
              isPrevious ? Icons.history : componentType.getIconData(),
              size: 18,
              color: isPrevious ? scheme.onSurfaceVariant : null,
            ),
      labelStyle: labelStyle,
      side: side,
      selectedColor: highlightColor?.withValues(alpha: 0.18),
      checkmarkColor: highlightColor,
      onSelected: (_) => onTap(),
    );

    return isPrevious ? Tooltip(message: 'Previous value', child: chip) : chip;
  }
}
