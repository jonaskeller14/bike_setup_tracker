import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/app_database.dart';
import '../../models/selected_data.dart';
import '../../repositories/app_repository.dart';
import '../../services/share_service.dart';
import '../../utils/file_export.dart';
import '../../utils/to_text.dart';
import 'data_select.dart';
import 'share_format.dart';

Future<void> shareData(BuildContext context) async {
  final shareResult = await showModalBottomSheet<ShareResult?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return ShareSheetFlow(appRepository: context.read<AppRepository>());
    },
  );

  if (shareResult == null) return;
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
}

class ShareSheetFlow extends StatefulWidget {
  final AppRepository appRepository;

  const ShareSheetFlow({super.key, required this.appRepository});

  @override
  State<StatefulWidget> createState() => _ShareSheetFlowState();
}

class _ShareSheetFlowState extends State<ShareSheetFlow> {
  ShareSheetFlowSteps _step = ShareSheetFlowSteps.step1SelectFormat;
  ShareFormats? _shareFormat;

  void _onBack() {
    switch (_step) {
      case ShareSheetFlowSteps.step1SelectFormat:
        break;
      case ShareSheetFlowSteps.step2SelectDataMehod:
        setState(() => _step = ShareSheetFlowSteps.step1SelectFormat);
      case ShareSheetFlowSteps.step3SelectDataItems:
        setState(() => _step = ShareSheetFlowSteps.step2SelectDataMehod);
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
            onAllSelected: () => Navigator.of(context).pop(
              ShareResult(
              format: _shareFormat!, 
              selectedData: SelectedData(
                persons: widget.appRepository.persons,
                bikes: widget.appRepository.bikes,
                components: widget.appRepository.components,
                setups: widget.appRepository.setups,
                ratings: widget.appRepository.ratings,
                ratingEntries: widget.appRepository.ratingEntries,
                taskRules: widget.appRepository.taskRules,
                taskEntries: widget.appRepository.taskEntries,
                ),
              ),
            ),
            onManualSelected: () => setState(() => _step = ShareSheetFlowSteps.step3SelectDataItems),
            onBack: _onBack, 
          ),
          ShareSheetFlowSteps.step3SelectDataItems => SelectDataItemsSheetContent(
            allData: SelectedData(
              persons: widget.appRepository.persons,
              bikes: widget.appRepository.bikes,
              components: widget.appRepository.components,
              setups: widget.appRepository.setups,
              ratings: widget.appRepository.ratings,
              ratingEntries: widget.appRepository.ratingEntries,
              taskRules: widget.appRepository.taskRules,
              taskEntries: widget.appRepository.taskEntries,
            ),
            onConfirm: (SelectedData selected) {
              Navigator.of(context).pop(ShareResult(format: _shareFormat!, selectedData: selected));
            },
            onBack: _onBack,
          ),
        },
      ),
    );
  }
}
