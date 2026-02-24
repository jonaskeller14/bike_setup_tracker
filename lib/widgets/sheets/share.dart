import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_data.dart';
import '../../utils/file_export.dart';
import '../../utils/to_text.dart';
import 'data_select.dart';
import 'share_json_text.dart';


Future<void> shareData(BuildContext context) async {
  final shareResult = await showModalBottomSheet<ShareResult?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return ShareSheetFlow(appData: context.read<AppData>());
    },
  );

  if (shareResult == null) return;
  if (!context.mounted) return;

  switch (shareResult.format) {
    case ShareFormats.json: FileExport.shareJson(
      context: context,
      data: shareResult.appData,
    );
    case ShareFormats.text: 
      final String content = toText(
        context: context, 
        appData: context.read<AppData>(),
        selectedPersons: shareResult.appData.persons.keys.toList(), 
        selectedBikes: shareResult.appData.bikes.keys.toList(), 
        selectedComponents: shareResult.appData.components.keys.toList(), 
        selectedSetups: shareResult.appData.setups.keys.toList(),
      );
      await FileExport.shareText(
        context: context,
        content: content,
      );
  }
}

class ShareResult {
  final ShareFormats format;
  final AppData appData;
  const ShareResult({required this.format, required this.appData});
}

enum ShareFormats {
  json,
  text,
}

enum ShareSheetFlowSteps {
  step1SelectFormat,
  step2SelectDataMehod,
  step3SelectDataItems,
}

class ShareSheetFlow extends StatefulWidget {
  final AppData appData;

  const ShareSheetFlow({super.key, required this.appData});

  @override
  State<StatefulWidget> createState() => _ShareSheetFlowState();
}

class _ShareSheetFlowState extends State<ShareSheetFlow> {
  ShareSheetFlowSteps _step = ShareSheetFlowSteps.step1SelectFormat;
  ShareFormats? _shareFormat;

  void _onBack() {
    switch (_step) {
      case ShareSheetFlowSteps.step1SelectFormat: break;
      case ShareSheetFlowSteps.step2SelectDataMehod: setState(() => _step = ShareSheetFlowSteps.step1SelectFormat);
      case ShareSheetFlowSteps.step3SelectDataItems: setState(() => _step = ShareSheetFlowSteps.step2SelectDataMehod);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == ShareSheetFlowSteps.step1SelectFormat, 
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;  // If the pop already happened (Step One), do nothing.
        _onBack();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_step) {
          ShareSheetFlowSteps.step1SelectFormat => SelectShareFormatSheetContent(
            onJson: () {
              _shareFormat = ShareFormats.json;
              setState(() => _step = ShareSheetFlowSteps.step2SelectDataMehod);
            },
            onText: () {
              _shareFormat = ShareFormats.text;
              setState(() => _step = ShareSheetFlowSteps.step2SelectDataMehod);
            },
          ),
          ShareSheetFlowSteps.step2SelectDataMehod => SelectDataMethodSheetContent(
            onAllSelected: () => Navigator.of(context).pop(ShareResult(format: _shareFormat!, appData: widget.appData)),
            onManualSelected: () => setState(() => _step = ShareSheetFlowSteps.step3SelectDataItems),
            onBack: _onBack, 
          ),
          ShareSheetFlowSteps.step3SelectDataItems => SelectDataItemsSheetContent(
            allData: widget.appData,
            onConfirm: (AppData selectedData) {
              Navigator.of(context).pop(ShareResult(format: _shareFormat!, appData: selectedData));
            },
            onBack: _onBack,
          ),
        },
      ),
    );
  }
}
