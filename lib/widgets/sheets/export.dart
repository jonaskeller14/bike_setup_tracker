import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../database/app_database.dart';
import '../../icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../models/selected_data.dart';
import '../../repositories/app_repository.dart';
import '../../services/backup_service.dart';
import '../../services/google_drive_service.dart';
import '../../utils/file_export.dart';
import 'data_select.dart';
import 'sheet_header.dart';
import 'sheet_progress_content.dart';

Future<void> exportData(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return ExportSheetFlow(
        allData: context.read<AppRepository>(),
        onExport: (exportResult) => _runExport(context, exportResult),
      );
    },
  );
}

// Uses the caller's context (not the sheet's) so snackbars outlive the sheet.
Future<void> _runExport(BuildContext context, ExportResult exportResult) async {
  if (!context.mounted) return;

  switch (exportResult.exportDestination) {
    case ExportDestination.file:
      await FileExport.saveJson(
      context: context,
      database: context.read<AppDatabase>(),
      selectedData: exportResult.selectedData,
    );
    case ExportDestination.backup:
      await BackupService.saveBackup(context: context, database: context.read<AppDatabase>(), force: true);
    case ExportDestination.googleDriveBackup:
      await context.read<GoogleDriveService>().saveBackup(context: context, force: true);
    case ExportDestination.attachmentBundle:
      await FileExport.saveAttachmentBundle(
      context: context,
      database: context.read<AppDatabase>(),
      selectedData: exportResult.selectedData,
    );
  }
}

enum ExportDestination {
  file,
  backup,
  googleDriveBackup,
  attachmentBundle,
}

class ExportResult {
  final ExportDestination exportDestination;
  final SelectedData selectedData;
  const ExportResult({required this.exportDestination, required this.selectedData});
}

enum ExportSheetFlowSteps {
  step1SelectDestination,
  step2SelectDataMethod,
  step3SelectDataItems,
  step4Exporting
}

class ExportSheetFlow extends StatefulWidget {
  final AppRepository allData;
  final Future<void> Function(ExportResult exportResult) onExport;
  const ExportSheetFlow({super.key, required this.allData, required this.onExport});

  @override
  State<ExportSheetFlow> createState() => _ExportSheetFlowState();
}

class _ExportSheetFlowState extends State<ExportSheetFlow> {
  ExportSheetFlowSteps _step = ExportSheetFlowSteps.step1SelectDestination;
  ExportDestination _destination = ExportDestination.file;

  SelectedData get _allData => SelectedData(
    persons: widget.allData.persons,
    bikes: widget.allData.bikes,
    components: widget.allData.components,
    setups: widget.allData.setups,
    ratings: widget.allData.ratings,
    ratingEntries: widget.allData.ratingEntries,
    taskRules: widget.allData.taskRules,
    taskEntries: widget.allData.taskEntries,
  );

  Future<void> _export(ExportDestination destination, SelectedData selectedData) async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _step = ExportSheetFlowSteps.step4Exporting);
    try {
      await widget.onExport(ExportResult(exportDestination: destination, selectedData: selectedData));
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == ExportSheetFlowSteps.step1SelectDestination,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        switch (_step) {
          case ExportSheetFlowSteps.step1SelectDestination: return;
          case ExportSheetFlowSteps.step2SelectDataMethod: setState(() => _step = ExportSheetFlowSteps.step1SelectDestination);
          case ExportSheetFlowSteps.step3SelectDataItems: setState(() => _step = ExportSheetFlowSteps.step2SelectDataMethod);
          case ExportSheetFlowSteps.step4Exporting: return;
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_step) {
          ExportSheetFlowSteps.step1SelectDestination => SelectExportDestinationSheetContent(
            onFile: () {
              _destination = ExportDestination.file;
              setState(() => _step = ExportSheetFlowSteps.step2SelectDataMethod);
            },
            onBackup: () => _export(ExportDestination.backup, _allData),
            onGoogleDriveBackup: () => _export(ExportDestination.googleDriveBackup, _allData),
            onAttachmentBundle: () {
              _destination = ExportDestination.attachmentBundle;
              setState(() => _step = ExportSheetFlowSteps.step2SelectDataMethod);
            },
          ),
          ExportSheetFlowSteps.step2SelectDataMethod => SelectDataMethodSheetContent(
            onAllSelected: () => _export(_destination, _allData),
            onManualSelected: () => setState(() => _step = ExportSheetFlowSteps.step3SelectDataItems),
            onBack: () => setState(() => _step = ExportSheetFlowSteps.step1SelectDestination),
          ),
          ExportSheetFlowSteps.step3SelectDataItems => SelectDataItemsSheetContent(
            allData: _allData,
            onConfirm: (SelectedData selected) => _export(_destination, selected),
            onBack: () => setState(() => _step = ExportSheetFlowSteps.step2SelectDataMethod),
          ),
          ExportSheetFlowSteps.step4Exporting => ExportProgressSheetContent(destination: _destination),
        },
      ),
    );
  }
}

class SelectExportDestinationSheetContent extends StatelessWidget {
  final VoidCallback onFile;
  final VoidCallback onBackup;
  final VoidCallback onGoogleDriveBackup;
  final VoidCallback onAttachmentBundle;

  const SelectExportDestinationSheetContent({
    super.key,
    required this.onFile,
    required this.onBackup,
    required this.onGoogleDriveBackup,
    required this.onAttachmentBundle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Export Data'),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Save File"),
                    subtitle: const Text("Choose where to save the JSON file"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onFile,
                  ),
                  ListTile(
                    leading: Icon(Icons.file_present_sharp, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Save Backup"),
                    subtitle: const Text("Save current state as a local backup"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onBackup,
                  ),
                  if (context.read<AppSettings>().enableGoogleDrive)
                    ListTile(
                      leading: Icon(SimpleIcons.googledrive, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Save Google Drive Backup"),
                      subtitle: const Text("Save current state as Backup in Google Drive"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: onGoogleDriveBackup,
                    ),
                  if (context.read<AppSettings>().enableAttachments)
                    ListTile(
                      leading: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Export Attachment Bundle"),
                      subtitle: const Text("Export data and attachments as a ZIP bundle"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: onAttachmentBundle,
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

class ExportProgressSheetContent extends StatelessWidget {
  final ExportDestination destination;

  const ExportProgressSheetContent({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final message = switch (destination) {
      ExportDestination.file => "Preparing JSON file…",
      ExportDestination.backup => "Saving backup…",
      ExportDestination.googleDriveBackup => "Uploading backup to Google Drive…",
      ExportDestination.attachmentBundle => "Packing data and attachments…",
    };

    return SheetProgressContent(title: 'Export Data', message: message);
  }
}
