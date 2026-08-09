import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/component.dart';
import '../repositories/component_preset_repository.dart';

class PresetCatalogCard extends StatefulWidget {
  final ComponentType componentType;
  final VoidCallback onTap;

  const PresetCatalogCard({
    super.key,
    required this.componentType,
    required this.onTap,
  });

  @override
  State<PresetCatalogCard> createState() => _PresetCatalogCardState();
}

class _PresetCatalogCardState extends State<PresetCatalogCard> {
  String? _teaser;
  static const List<String> _popularBrands = ['fox', 'rockshox'];

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
      unawaited(_loadTeaser());
    }
  }

  Future<void> _loadTeaser() async {
    try {
      final variants =
          await context.read<ComponentPresetRepository>().forType(widget.componentType);
      if (!mounted) return;
      final brands = <String>[];
      for (final v in variants) {
        if (!brands.contains(v.brand)) brands.add(v.brand);
      }
      if (brands.isEmpty) return; // Keep the generic subtitle.
      // Surface popular brands first, keeping the alphabetical order otherwise.
      brands.sort((a, b) {
        final ia = _popularBrands.indexOf(a.toLowerCase());
        final ib = _popularBrands.indexOf(b.toLowerCase());
        if (ia != ib) return (ia == -1 ? 999 : ia).compareTo(ib == -1 ? 999 : ib);
        return a.compareTo(b);
      });
      const shown = 3;
      final teaser = brands.take(shown).join(' · ');
      setState(() =>
          _teaser = brands.length > shown ? '$teaser · …' : teaser);
    } catch (_) {
      // Teaser is optional; leave the generic subtitle in place on failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.auto_awesome, color: colors.onPrimaryContainer),
        title: Text(
          'Choose from catalog',
          style: TextStyle(fontWeight: FontWeight.w600, color: colors.onPrimaryContainer),
        ),
        subtitle: Text(
          _teaser ?? 'Prefill from a ${widget.componentType.label.toLowerCase()} model',
          style: TextStyle(color: colors.onPrimaryContainer.withValues(alpha: 0.8)),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colors.onPrimaryContainer),
        onTap: widget.onTap,
      ),
    );
  }
}
