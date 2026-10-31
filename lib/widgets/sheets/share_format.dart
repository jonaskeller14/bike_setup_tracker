import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'sheet_header.dart';

class SelectShareFormatSheetContent extends StatelessWidget {
  final VoidCallback onJson;
  final VoidCallback onText;
  final VoidCallback onCsv;
  final VoidCallback onXlsx;
  final VoidCallback? onBack;

  const SelectShareFormatSheetContent({
    super.key, 
    required this.onJson, 
    required this.onText, 
    required this.onCsv,
    required this.onXlsx,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: context.l10n.shareFormatTitle,
            onBack: onBack,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.l10n.shareFormatJson),
                    subtitle: Text(context.l10n.shareFormatJsonSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onJson,
                  ),
                  ListTile(
                    leading: Icon(Icons.table_view, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.l10n.shareFormatExcel),
                    subtitle: Text(context.l10n.shareFormatExcelSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onXlsx,
                  ),
                  ListTile(
                    leading: Icon(Icons.grid_on, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.l10n.shareFormatCsv),
                    subtitle: Text(context.l10n.shareFormatCsvSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onCsv,
                  ),
                  ListTile(
                    leading: Icon(Icons.text_snippet, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.l10n.shareFormatText),
                    subtitle: Text(context.l10n.shareFormatTextSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onText,
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
