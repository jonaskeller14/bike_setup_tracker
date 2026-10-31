import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_language.dart';
import '../../l10n/l10n.dart';
import '../../l10n/locale_resolution.dart';
import 'sheet_header.dart';

/// The name shown for a stored language code, where null follows the device.
String languageName(AppLocalizations l10n, String? localeCode) {
  return AppLanguage.fromCode(localeCode)?.nativeName ?? l10n.preferencesLanguageSystem;
}

/// [localeCode] null means the system language; [onSelected] gets null for it.
Future<void> languageSheet({
  required BuildContext context,
  required String? localeCode,
  required ValueChanged<String?> onSelected,
}) {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => _LanguageSheet(localeCode: localeCode, onSelected: onSelected),
  );
}

class _LanguageSheet extends StatelessWidget {
  final String? localeCode;
  final ValueChanged<String?> onSelected;

  const _LanguageSheet({required this.localeCode, required this.onSelected});

  void _select(BuildContext context, String? code) {
    unawaited(HapticFeedback.selectionClick());
    Navigator.pop(context);
    onSelected(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deviceLanguage = resolveAppLocale(
      enabled: true,
      deviceLocales: View.of(context).platformDispatcher.locales,
    ).languageCode;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: l10n.preferencesLanguage, leadingIcon: const Icon(Icons.language)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                spacing: 8,
                children: [
                  _LanguageTile(
                    selected: localeCode == null,
                    onTap: () => _select(context, null),
                    leading: const Icon(Icons.smartphone),
                    title: l10n.preferencesLanguageSystem,
                    subtitle: languageName(l10n, deviceLanguage),
                  ),
                  for (final language in AppLanguage.values)
                    _LanguageTile(
                      selected: localeCode == language.name,
                      onTap: () => _select(context, language.name),
                      leading: Text(language.flag, style: const TextStyle(fontSize: 22)),
                      title: language.nativeName,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String? subtitle;

  const _LanguageTile({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2 : 1),
    );

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            // The selected border is 1px thicker; the padding gives that pixel back so the content never shifts.
            padding: EdgeInsets.symmetric(horizontal: 16 + (selected ? 0 : 1), vertical: 12 + (selected ? 0 : 1)),
            child: Row(
              spacing: 16,
              children: [
                SizedBox(width: 28, child: Center(child: leading)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle, color: cs.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
