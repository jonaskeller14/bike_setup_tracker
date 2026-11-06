import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'sheet_header.dart';

class SelectImportMethodSheetContent extends StatelessWidget {
  final VoidCallback onOverwrite;
  final VoidCallback onMerge;
  final VoidCallback onReplace;
  final VoidCallback onBack;

  const SelectImportMethodSheetContent({
    super.key, 
    required this.onOverwrite,
    required this.onMerge,
    required this.onReplace,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: context.l10n.importSheetTitle,
            onBack: onBack,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.published_with_changes, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.l10n.importMethodOverwrite),
                    subtitle: Text(context.l10n.importMethodOverwriteSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onOverwrite,
                  ),
                  ListTile(
                    leading: Icon(Icons.merge, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.l10n.importMethodMerge),
                    subtitle: Text(context.l10n.importMethodMergeSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onMerge,
                  ),
                  ListTile(
                    leading: Icon(Icons.find_replace, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.l10n.importMethodReplace),
                    subtitle: Text(context.l10n.importMethodReplaceSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onReplace,
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
