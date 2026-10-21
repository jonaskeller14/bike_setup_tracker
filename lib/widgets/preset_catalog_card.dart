import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/component/component.dart';
import '../repositories/component_catalog_repository.dart';
import '../utils/component_catalog_application.dart';
import '../utils/component_preset_resolver.dart';

class PresetCatalogCard extends StatefulWidget {
  final ComponentType componentType;
  final VoidCallback onTap;

  /// What the component links to, as deep as its preset still resolves.
  final ResolvedPreset? applied;
  final VoidCallback onUnlink;

  /// Tells an unlinked component that linking a product with a setup guide
  /// gets it recommended values.
  final bool showGuideHint;

  const PresetCatalogCard({
    super.key,
    required this.componentType,
    required this.onTap,
    this.applied,
    required this.onUnlink,
    this.showGuideHint = false,
  });

  @override
  State<PresetCatalogCard> createState() => _PresetCatalogCardState();
}

class _PresetCatalogCardState extends State<PresetCatalogCard> {
  String? _teaser;
  bool _hasGuides = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTeaser());
  }

  @override
  void didUpdateWidget(PresetCatalogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.componentType != widget.componentType) {
      _teaser = null;
      _hasGuides = false;
      unawaited(_loadTeaser());
    }
  }

  Future<void> _loadTeaser() async {
    try {
      final products =
          await context.read<ComponentCatalogRepository>().forType(widget.componentType);
      if (!mounted) return;
      final hasGuides = products.any((product) => product.node.guide != null);
      if (hasGuides != _hasGuides) setState(() => _hasGuides = hasGuides);
      final brands = <String>[];
      for (final product in products) {
        if (!brands.contains(product.catalog.brand)) brands.add(product.catalog.brand);
      }
      if (brands.isEmpty) return; // Keep the generic subtitle.
      const shown = 3;
      final teaser = brands.take(shown).join(' · ');
      setState(() =>
          _teaser = brands.length > shown ? '$teaser · …' : teaser);
    } catch (_) {
      // Teaser is optional; leave the generic subtitle in place on failure.
    }
  }

  /// The title names the required choices; the optional ones follow here.
  String _appliedSubtitle(ResolvedPreset applied) {
    final years = applied.year ?? applied.node.years;
    return [
      for (final axis in applied.optionalAxes) ?applied.selections[axis.id]?.label,
      if (years != null) years.toString(),
      'Tap to change',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final applied = widget.applied;
    final isApplied = applied != null;
    // Neutral surface once applied: picking a preset is no longer the page's primary action.
    final foreground = isApplied ? colors.onSurface : colors.onPrimaryContainer;
    final subtitleColor = isApplied ? colors.onSurfaceVariant : colors.onPrimaryContainer.withValues(alpha: 0.8);
    return Card(
      margin: EdgeInsets.zero,
      color: isApplied ? colors.surfaceContainerHighest : colors.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.auto_awesome, color: isApplied ? null : colors.onPrimaryContainer),
        title: Text(
          isApplied ? presetDisplayName(applied) : 'Choose from catalog',
          maxLines: isApplied ? 1 : null,
          overflow: isApplied ? TextOverflow.ellipsis : null,
          style: TextStyle(fontWeight: FontWeight.w600, color: foreground),
        ),
        subtitle: Text(
          isApplied
              ? _appliedSubtitle(applied)
              : [
                  _teaser ?? 'Prefill from a ${widget.componentType.label.toLowerCase()} model',
                  if (widget.showGuideHint && _hasGuides) 'Link to a catalog product to get recommended values',
                ].join('\n'),
          maxLines: isApplied ? 1 : null,
          overflow: isApplied ? TextOverflow.ellipsis : null,
          style: TextStyle(color: subtitleColor),
        ),
        trailing: isApplied
            ? IconButton(
                icon: const Icon(Icons.link_off),
                color: subtitleColor,
                tooltip: 'Unlink preset (keeps values)',
                onPressed: widget.onUnlink,
              )
            : Icon(Icons.arrow_forward_ios, size: 16, color: foreground),
        onTap: widget.onTap,
      ),
    );
  }
}
