import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../database/app_database.dart';
import '../../models/selected_data.dart';
import '../../repositories/app_repository.dart';
import '../../services/share_service.dart';
import '../../utils/file_export.dart';
import '../../utils/to_text.dart';
import 'data_select.dart';
import 'share_format.dart';
import 'sheet_progress_content.dart';

Future<void> shareData(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return ShareSheetFlow(
        appRepository: context.read<AppRepository>(),
        onShare: (shareResult) => _runShare(context, shareResult),
      );
    },
  );
}

// Uses the caller's context (not the sheet's) so snackbars and the share sheet outlive the sheet.
Future<void> _runShare(BuildContext context, ShareResult shareResult) async {
  if (!context.mounted) return;

  switch (shareResult.format) {
    case ShareFormats.json:
      await FileExport.shareJson(
      context: context,
      database: context.read<AppDatabase>(),
      selectedData: shareResult.selectedData,
    );
    case ShareFormats.text: 
      final String content = toText(
        context: context, 
        selectedData: shareResult.selectedData,
      );
      await ShareService.shareText(context: context, text: content);
    case ShareFormats.csv:
      await FileExport.shareCsv(
      context: context,
      data: shareResult.selectedData,
    );
    case ShareFormats.xlsx:
      await FileExport.shareXlsx(
      context: context,
      data: shareResult.selectedData,
    );
  }
}

class ShareResult {
  final ShareFormats format;
  final SelectedData selectedData;
  const ShareResult({required this.format, required this.selectedData});
}

enum ShareFormats {
  json,
  text,
  csv,
  xlsx,
}

enum ShareSheetFlowSteps {
  step1SelectFormat,
  step2SelectDataMehod,
  step3SelectDataItems,
  step4Sharing,
}

class ShareSheetFlow extends StatefulWidget {
  final AppRepository appRepository;
  final Future<void> Function(ShareResult shareResult) onShare;

  const ShareSheetFlow({super.key, required this.appRepository, required this.onShare});

  @override
  State<StatefulWidget> createState() => _ShareSheetFlowState();
}

class _ShareSheetFlowState extends State<ShareSheetFlow> {
  ShareSheetFlowSteps _step = ShareSheetFlowSteps.step1SelectFormat;
  ShareFormats? _shareFormat;

  SelectedData get _allData => SelectedData(
    persons: widget.appRepository.persons,
    bikes: widget.appRepository.bikes,
    components: widget.appRepository.components,
    setups: widget.appRepository.setups,
    taskRules: widget.appRepository.taskRules,
    taskEntries: widget.appRepository.taskEntries,
    feedbacks: widget.appRepository.feedbacks,
    testSessions: widget.appRepository.testSessions,
  );

  Future<void> _share(SelectedData selectedData) async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _step = ShareSheetFlowSteps.step4Sharing);
    try {
      await widget.onShare(ShareResult(format: _shareFormat!, selectedData: selectedData));
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _onBack() {
    switch (_step) {
      case ShareSheetFlowSteps.step1SelectFormat:
        break;
      case ShareSheetFlowSteps.step2SelectDataMehod:
        setState(() => _step = ShareSheetFlowSteps.step1SelectFormat);
      case ShareSheetFlowSteps.step3SelectDataItems:
        setState(() => _step = ShareSheetFlowSteps.step2SelectDataMehod);
      case ShareSheetFlowSteps.step4Sharing:
        break;
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
            onCsv: () {
              _shareFormat = ShareFormats.csv;
              setState(() => _step = ShareSheetFlowSteps.step2SelectDataMehod);
            },
            onXlsx: () {
              _shareFormat = ShareFormats.xlsx;
              setState(() => _step = ShareSheetFlowSteps.step2SelectDataMehod);
            },
          ),
          ShareSheetFlowSteps.step2SelectDataMehod => SelectDataMethodSheetContent(
            onAllSelected: () => _share(_allData),
            onManualSelected: () => setState(() => _step = ShareSheetFlowSteps.step3SelectDataItems),
            onBack: _onBack, 
          ),
          ShareSheetFlowSteps.step3SelectDataItems => SelectDataItemsSheetContent(
            allData: _allData,
            onConfirm: _share,
            onBack: _onBack,
          ),
          ShareSheetFlowSteps.step4Sharing => SheetProgressContent(
            title: 'Share Data',
            message: switch (_shareFormat!) {
              ShareFormats.json => "Preparing JSON file…",
              ShareFormats.text => "Preparing text…",
              ShareFormats.csv => "Preparing CSV file…",
              ShareFormats.xlsx => "Preparing Excel file…",
            },
          ),
        },
      ),
    );
  }
}
