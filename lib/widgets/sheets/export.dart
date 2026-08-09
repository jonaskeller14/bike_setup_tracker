import 'package:flutter/material.dart';
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

Future<void> exportData(BuildContext context) async {
  final ExportResult? exportResult = await showModalBottomSheet<ExportResult?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return ExportSheetFlow(allData: context.read<AppRepository>());
    },
  );

  if (exportResult == null) return;
  if (!context.mounted) return;

  switch (exportResult.exportDestination) {
    case ExportDestination.file:
      await FileExport.downloadJson(
      context: context,
      database: context.read<AppDatabase>(),
      selectedData: exportResult.selectedData,
    );
    case ExportDestination.backup:
      await BackupService.saveBackup(context: context, database: context.read<AppDatabase>(), force: true);
    case ExportDestination.googleDriveBackup:
      await context.read<GoogleDriveService>().saveBackup(context: context, force: true);
    case ExportDestination.imageBundle:
      await FileExport.downloadImageBundle(
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
  imageBundle,
}

class ExportResult {
  final ExportDestination exportDestination;
  final SelectedData selectedData;
  const ExportResult({required this.exportDestination, required this.selectedData});
}

enum ExportSheetFlowSteps {
  step1SelectDestination,
  step2SelectDataMethod,
  step3SelectDataItems
}

class ExportSheetFlow extends StatefulWidget {
  final AppRepository allData;
  const ExportSheetFlow({super.key, required this.allData});

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
            onBackup: () => Navigator.of(context).pop(
              ExportResult(
              exportDestination: ExportDestination.backup,
              selectedData: _allData,
              ),
            ),
            onGoogleDriveBackup: () => Navigator.of(context).pop(
              ExportResult(
              exportDestination: ExportDestination.googleDriveBackup,
              selectedData: _allData,
              ),
            ),
            onImageBundle: () {
              _destination = ExportDestination.imageBundle;
              setState(() => _step = ExportSheetFlowSteps.step2SelectDataMethod);
            },
          ),
          ExportSheetFlowSteps.step2SelectDataMethod => SelectDataMethodSheetContent(
            onAllSelected: () => Navigator.of(context).pop(
              ExportResult(
              exportDestination: _destination,
              selectedData: _allData,
              ),
            ),
            onManualSelected: () => setState(() => _step = ExportSheetFlowSteps.step3SelectDataItems),
            onBack: () => setState(() => _step = ExportSheetFlowSteps.step1SelectDestination),
          ),
          ExportSheetFlowSteps.step3SelectDataItems => SelectDataItemsSheetContent(
            allData: _allData,
            onConfirm: (SelectedData selected) => Navigator.of(context).pop(
              ExportResult(
              exportDestination: _destination,
              selectedData: selected,
              ),
            ),
            onBack: () => setState(() => _step = ExportSheetFlowSteps.step2SelectDataMethod),
          ),
        },
      ),
    );
  }
}

class SelectExportDestinationSheetContent extends StatelessWidget {
  final VoidCallback onFile;
  final VoidCallback onBackup;
  final VoidCallback onGoogleDriveBackup;
  final VoidCallback onImageBundle;

  const SelectExportDestinationSheetContent({
    super.key,
    required this.onFile,
    required this.onBackup,
    required this.onGoogleDriveBackup,
    required this.onImageBundle,
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
                    title: const Text("Download File"),
                    subtitle: const Text("Download json file containing the data"),
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
                  if (context.read<AppSettings>().enableSetupImages)
                    ListTile(
                      leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Export Image Bundle"),
                      subtitle: const Text("Export data and images as a ZIP bundle"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: onImageBundle,
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
