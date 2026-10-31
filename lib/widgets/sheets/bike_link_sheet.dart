import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/bike.dart';
import '../../models/person.dart';
import '../../repositories/app_repository.dart';
import '../../theme.dart';
import 'sheet.dart';
import 'sheet_header.dart';

/// Lets the user choose which bikes [person] rides. Nothing is written here:
/// Save returns the ids of the bikes to link, and dismissing returns `null`.
Future<Set<String>?> showBikeLinkSheet(BuildContext context, {required Person person}) {
  return showModalBottomSheet<Set<String>>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => BikeLinkSheetContent(person: person),
  );
}

class BikeLinkSheetContent extends StatefulWidget {
  const BikeLinkSheetContent({super.key, required this.person});

  final Person person;

  @override
  State<BikeLinkSheetContent> createState() => _BikeLinkSheetContentState();
}

class _BikeLinkSheetContentState extends State<BikeLinkSheetContent> {
  late final Set<String> _initial = {
    for (final bike in context.read<AppRepository>().bikes.values)
      if (bike.person == widget.person.id) bike.id,
  };
  late final Set<String> _draft = {..._initial};

  int get _toLink => _draft.difference(_initial).length;
  int get _toUnlink => _initial.difference(_draft).length;

  void _toggle(Bike bike) {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _draft.contains(bike.id) ? _draft.remove(bike.id) : _draft.add(bike.id));
  }

  void _save() {
    unawaited(HapticFeedback.lightImpact());
    Navigator.pop(context, _draft);
  }

  /// Says what Save will do, e.g. "Link 2 bikes" or "Link 1 · Unlink 1".
  String _saveLabel() {
    final l10n = context.l10n;
    if (_toLink > 0 && _toUnlink > 0) return l10n.bikeLinkSaveBoth(_toLink, _toUnlink);
    if (_toLink > 0) return l10n.bikeLinkSaveLink(_toLink);
    if (_toUnlink > 0) return l10n.bikeLinkSaveUnlink(_toUnlink);
    return l10n.save;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bikes = context.select<AppRepository, Map<String, Bike>>((repository) => repository.bikes).values;
    final persons = context.select<AppRepository, Map<String, Person>>((repository) => repository.persons);
    final hasChanges = _toLink + _toUnlink > 0;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: context.l10n.bikeLinkSheetTitle, leadingIcon: const Icon(Icons.link)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.l10n.bikeLinkIntro(widget.person.name),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: bikes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: SheetFilterEmptyHint(
                        icon: Bike.iconData,
                        title: context.l10n.bikeLinkEmptyTitle,
                        hint: context.l10n.riderAddBikeHint,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        for (final bike in bikes)
                          _BikeLinkRow(
                            key: ValueKey(bike.id),
                            bike: bike,
                            linked: _draft.contains(bike.id),
                            changed: _draft.contains(bike.id) != _initial.contains(bike.id),
                            otherRider: bike.person == widget.person.id ? null : persons[bike.person],
                            onToggle: () => _toggle(bike),
                          ),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              spacing: 16,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: hasChanges ? _save : null,
                    icon: const Icon(Icons.check),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_saveLabel(), maxLines: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BikeLinkRow extends StatelessWidget {
  static const Duration _transitionDuration = Duration(milliseconds: 300);

  const _BikeLinkRow({
    super.key,
    required this.bike,
    required this.linked,
    required this.changed,
    required this.otherRider,
    required this.onToggle,
  });

  final Bike bike;
  final bool linked;

  /// Whether [linked] differs from the saved state.
  final bool changed;

  /// The rider the bike is saved with, when that is someone else. Linking
  /// moves the bike away from them.
  final Person? otherRider;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlights = Theme.of(context).extension<ValueHighlightColors>()!;

    return ListTile(
      onTap: onToggle,
      tileColor: changed ? highlights.changedFill : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: changed ? BorderSide(color: highlights.changed.withValues(alpha: 0.5)) : BorderSide.none,
      ),
      contentPadding: const EdgeInsets.only(left: 12, right: 8),
      leading: AnimatedSwitcher(
        duration: _transitionDuration,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          linked ? Icons.link : Icons.link_off,
          key: ValueKey<bool>(linked),
          color: changed ? highlights.changed : (linked ? colorScheme.primary : colorScheme.onSurfaceVariant),
        ),
      ),
      title: Text(
        bike.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: otherRider == null
          ? null
          : Text(
              context.l10n.bikeLinkRiddenBy(otherRider!.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: changed ? highlights.changed : colorScheme.onSurfaceVariant),
            ),
      trailing: _PillButton(
        label: linked ? context.l10n.bikeLinkUnlink : context.l10n.bikeLinkLink,
        icon: linked ? Icons.link_off : Icons.add_link,
        tooltip: linked ? context.l10n.bikeLinkUnlinkTooltip(bike.name) : context.l10n.bikeLinkLinkTooltip(bike.name),
        filled: !linked,
        onPressed: onToggle,
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.tooltip,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final String tooltip;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = filled ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? colorScheme.secondaryContainer : Colors.transparent,
        shape: StadiumBorder(side: filled ? BorderSide.none : BorderSide(color: colorScheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Icon(icon, size: 16, color: foreground),
                Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
