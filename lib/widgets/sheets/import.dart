import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../database/app_database.dart';
import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/selected_data.dart';
import '../../models/service_error.dart';
import '../../repositories/app_repository.dart';
import '../../services/attachment_storage_service.dart';
import '../../utils/file_import.dart';
import '../app_snackbar.dart';
import 'backup.dart';
import 'data_select.dart';
import 'import_merge_overwrite.dart';
import 'sheet_header.dart';
import 'sheet_progress_content.dart';

Future<void> importData(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return ImportSheetFlow(
        onImport: (importResult) => _runImport(context, importResult),
      );
    },
  );
}

// Uses the caller's context (not the sheet's) so snackbars outlive the sheet.
Future<void> _runImport(BuildContext context, ImportResult importResult) async {
  if (!context.mounted) return;
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    final database = context.read<AppDatabase>();
    final appRepository = context.read<AppRepository>();
    switch (importResult.importMethod) {
      case ImportMethod.overwrite:
        await FileImport.overwrite(remoteData: importResult.dataToImport, database: database);
      case ImportMethod.merge:
        await FileImport.merge(remoteData: importResult.dataToImport, database: database);
      case ImportMethod.replace:
        await FileImport.replace(remoteData: importResult.dataToImport, database: database);
    }
    // The import wrote task entries directly to the DB with their imported
    // (foreign / stale) snapshots. Recompute them against the local Strava
    // activities and installation history.
    await appRepository.refreshTaskEntrySnapshots();
    if (!context.mounted) return;
    scaffoldMessenger.showSnackBar(
      AppSnackBar.success(
        context,
        switch (importResult.importMethod) {
          ImportMethod.merge => context.l10n.importDoneMerge,
          ImportMethod.overwrite => context.l10n.importDoneOverwrite,
          ImportMethod.replace => context.l10n.importDoneReplace,
        },
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    scaffoldMessenger.showSnackBar(
      AppSnackBar.error(
        context,
        switch (importResult.importMethod) {
          ImportMethod.merge => context.l10n.importFailedMerge(e.toString()),
          ImportMethod.overwrite => context.l10n.importFailedOverwrite(e.toString()),
          ImportMethod.replace => context.l10n.importFailedReplace(e.toString()),
        },
      ),
    );
  }
}

enum ImportSourceOptions {
  file,
  backup,
}

enum ImportMethod {
  overwrite,
  merge,
  replace,
}

class ImportResult {
  final ImportMethod importMethod;
  final SelectedData dataToImport;
  const ImportResult({required this.importMethod, required this.dataToImport});
}

enum ImportSheetFlowSteps {
  step1SelectSource,
  step2SelectBackup,
  step3SelectDataMethod,
  step4SelectDataItems,
  step5SelectImportMethod,
  step6Importing,
}

class ImportSheetFlow extends StatefulWidget {
  final Future<void> Function(ImportResult importResult) onImport;
  const ImportSheetFlow({super.key, required this.onImport});

  @override
  State<ImportSheetFlow> createState() => _ImportSheetFlowState();
}

class _ImportSheetFlowState extends State<ImportSheetFlow> {
  ImportSheetFlowSteps _step = ImportSheetFlowSteps.step1SelectSource;
  final List<ImportSheetFlowSteps> _previousSteps = [];

  SelectedData? _remoteAllData;
  SelectedData? _remoteSelectedData;
  ImportMethod? _importMethod;

  Future<void> _import(ImportMethod importMethod) async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _importMethod = importMethod;
      _step = ImportSheetFlowSteps.step6Importing;
    });
    try {
      await widget.onImport(ImportResult(importMethod: importMethod, dataToImport: _remoteSelectedData!));
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _setNextStep(ImportSheetFlowSteps nextStep) {
    setState(() {
      _previousSteps.add(_step);
      _step = nextStep;
    });
  }

  void _onBack() {
    if (_previousSteps.isEmpty) return;

    switch (_step) {
      case ImportSheetFlowSteps.step1SelectSource:
        break;
      case ImportSheetFlowSteps.step2SelectBackup:
        _remoteAllData = null;
        break;
      case ImportSheetFlowSteps.step3SelectDataMethod:
        _remoteAllData = null;
        _remoteSelectedData = null;
        break;
      case ImportSheetFlowSteps.step4SelectDataItems:
        _remoteSelectedData = null;
        break;
      case ImportSheetFlowSteps.step5SelectImportMethod:
        break;
      case ImportSheetFlowSteps.step6Importing:
        return;
    }

    setState(() {
      _step = _previousSteps.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == ImportSheetFlowSteps.step1SelectSource,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // If the pop already happened (Step One), do nothing.
        if (_previousSteps.isNotEmpty) {
          _onBack();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_step) {
          ImportSheetFlowSteps.step1SelectSource => SelectImportSourceSheetContent(
            onFile: (SelectedData appRepository) {
              _remoteAllData = appRepository;
              if (_remoteAllData == null) return;
              _setNextStep(ImportSheetFlowSteps.step3SelectDataMethod);
            },
            onBackup: () => _setNextStep(ImportSheetFlowSteps.step2SelectBackup),
          ),
          ImportSheetFlowSteps.step2SelectBackup => BackupSheetContent(
            onRestore: (SelectedData appRepository) async {
              _remoteAllData = appRepository;
              if (_remoteAllData == null) return;
              _setNextStep(ImportSheetFlowSteps.step3SelectDataMethod);
            },
            onBack: _onBack,
          ),
          ImportSheetFlowSteps.step3SelectDataMethod => SelectDataMethodSheetContent(
            onAllSelected: () {
              _remoteSelectedData = _remoteAllData;
              _setNextStep(ImportSheetFlowSteps.step5SelectImportMethod);
            },
            onManualSelected: () {
              _setNextStep(ImportSheetFlowSteps.step4SelectDataItems);
            },
            onBack: _onBack,
          ),
          ImportSheetFlowSteps.step4SelectDataItems => SelectDataItemsSheetContent(
            allData: SelectedData(
              persons: _remoteAllData!.persons,
              bikes: _remoteAllData!.bikes,
              components: _remoteAllData!.components,
              setups: _remoteAllData!.setups,
              taskRules: _remoteAllData!.taskRules,
              taskEntries: _remoteAllData!.taskEntries,
              feedbacks: _remoteAllData!.feedbacks,
              testSessions: _remoteAllData!.testSessions,
            ),
            onConfirm: (SelectedData selectedData) {
              _remoteSelectedData = selectedData;
              _setNextStep(ImportSheetFlowSteps.step5SelectImportMethod);
            },
            onBack: _onBack,
          ),
          ImportSheetFlowSteps.step5SelectImportMethod => SelectImportMethodSheetContent(
            onOverwrite: () => _import(ImportMethod.overwrite),
            onMerge: () => _import(ImportMethod.merge),
            onReplace: () => _import(ImportMethod.replace),
            onBack: _onBack,
          ),
          ImportSheetFlowSteps.step6Importing => SheetProgressContent(
            title: context.l10n.importSheetTitle,
            message: switch (_importMethod!) {
              ImportMethod.merge => context.l10n.importProgressMerge,
              ImportMethod.overwrite => context.l10n.importProgressOverwrite,
              ImportMethod.replace => context.l10n.importProgressReplace,
            },
          ),
        },
      ),
    );
  }
}

class SelectImportSourceSheetContent extends StatefulWidget {
  final void Function(SelectedData) onFile;
  final VoidCallback onBackup;

  const SelectImportSourceSheetContent({
    super.key,
    required this.onFile,
    required this.onBackup,
  });

  @override
  State<SelectImportSourceSheetContent> createState() => _SelectImportSourceSheetContentState();
}

class _SelectImportSourceSheetContentState extends State<SelectImportSourceSheetContent> {
  DataError? _filePickingError;
  String? _readingMessage;

  @override
  Widget build(BuildContext context) {
    if (_readingMessage != null) {
      return PopScope(
        canPop: false,
        child: SheetProgressContent(title: context.l10n.importSheetTitle, message: _readingMessage!),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: context.l10n.importSheetTitle),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_filePickingError != null)
                    ListTile(
                      leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      title: SelectableText(_filePickingError!.message(context.l10n)),
                      dense: true,
                    ),
                  ListTile(
                    leading: Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.l10n.importFile),
                    subtitle: Text(context.l10n.importFileSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () async {
                      final appDatabase = context.read<AppDatabase>();
                      final result = await FileImport.pickAndReadJsonFile(
                        appDatabase: appDatabase,
                        onPicked: () => setState(() => _readingMessage = context.l10n.importReadingFile),
                      );
                      if (!mounted) return;
                      setState(() => _readingMessage = null);
                      switch (result) {
                        case DataSuccess(:final value):
                          widget.onFile(value);
                        case DataFailure(:final error):
                          setState(() => _filePickingError = error);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.file_present_sharp, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.l10n.importRestoreBackup),
                    subtitle: Text(context.l10n.importRestoreBackupSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: widget.onBackup,
                  ),
                  ListTile(
                    leading: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.primary),
                    title: Text(context.l10n.importAttachmentBundle),
                    subtitle: Text(context.l10n.importAttachmentBundleSubtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () async {
                      final result = await AttachmentStorageService().importBundle(
                        onPicked: () => setState(() => _readingMessage = context.l10n.importUnpackingBundle),
                      );
                      if (!mounted) return;
                      setState(() => _readingMessage = null);
                      switch (result) {
                        case BundleImported(:final data):
                          widget.onFile(data);
                        case BundleImportFailed(:final error):
                          setState(() => _filePickingError = error);
                        case BundleImportCancelled():
                          break;
                      }
                    },
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
