import 'package:flutter/material.dart';
import 'sheet.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onBack != null)
                  sheetBackButton(context, onPressed: onBack!),
                sheetTitle(context, 'Share Format'),
                sheetCloseButton(context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                    title: const Text("JSON File"),
                    subtitle: const Text("Best for moving data to another device or saving a full backup."),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onJson,
                  ),
                  ListTile(
                    leading: Icon(Icons.table_view, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Excel Spreadsheet"),
                    subtitle: const Text("Best for analysis in Excel or Google Sheets (XLSX)."),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onXlsx,
                  ),
                  ListTile(
                    leading: Icon(Icons.grid_on, color: Theme.of(context).colorScheme.primary),
                    title: const Text("CSV File"),
                    subtitle: const Text("Simple tabular format (Comma Separated Values)."),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onCsv,
                  ),
                  ListTile(
                    leading: Icon(Icons.text_snippet, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Plain Text"),
                    subtitle: const Text("Best for sharing setup details in chats or notes."),
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
