import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/app_database.dart';
import '../../models/app_settings.dart';
import '../../models/selected_data.dart';
import '../../repositories/app_repository.dart';
import '../../services/image_storage_service.dart';
import '../../utils/file_import.dart';
import 'backup.dart';
import 'data_select.dart';
import 'import_merge_overwrite.dart';
import 'sheet_header.dart';

Future<void> importData(BuildContext context) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
  final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

  final ImportResult? importResult = await showModalBottomSheet<ImportResult?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return const ImportSheetFlow();
    },
  );

  if (importResult == null) return;
  if (!context.mounted) return;

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
    scaffoldMessenger.showSnackBar(
      SnackBar(
        persist: false,
        showCloseIcon: true,
        content: switch (importResult.importMethod) {
          ImportMethod.merge => const Text("Data merged successfully"),
          ImportMethod.overwrite => const Text("Data overwritten successfully"),
          ImportMethod.replace => const Text("Data replaced successfully"),
        },
      )
    );
  } catch (e) {
    scaffoldMessenger.showSnackBar(SnackBar(
      persist: false,
      showCloseIcon: true,
      closeIconColor: onErrorContainerColor,
      content: Text(
        switch (importResult.importMethod) {
          ImportMethod.merge => "Merge failed: $e",
          ImportMethod.overwrite => "Overwriting failed: $e",
          ImportMethod.replace => "Overwriting failed: $e",
        },
        style: TextStyle(color: onErrorContainerColor)
      ),
      backgroundColor: errorContainerColor,
    ));
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
}

class ImportSheetFlow extends StatefulWidget {
  const ImportSheetFlow({super.key});

  @override
  State<ImportSheetFlow> createState() => _ImportSheetFlowState();
}

class _ImportSheetFlowState extends State<ImportSheetFlow> {
  ImportSheetFlowSteps _step = ImportSheetFlowSteps.step1SelectSource;
  final List<ImportSheetFlowSteps> _previousSteps = [];

  SelectedData? _remoteAllData;
  SelectedData? _remoteSelectedData;

  void _setNextStep(ImportSheetFlowSteps nextStep) {
    setState(() {
      _previousSteps.add(_step);
      _step = nextStep;
    });
  }

  void _onBack() {
    if (_previousSteps.isEmpty) return;

    switch (_step) {
      case ImportSheetFlowSteps.step1SelectSource: break;
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
      case ImportSheetFlowSteps.step5SelectImportMethod: break;
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
        if (didPop) return;  // If the pop already happened (Step One), do nothing.
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
              ratings: _remoteAllData!.ratings,
              ratingEntries: _remoteAllData!.ratingEntries,
              taskRules: _remoteAllData!.taskRules,
              taskEntries: _remoteAllData!.taskEntries,
            ),
            onConfirm: (SelectedData selectedData) {
              _remoteSelectedData = selectedData;
              _setNextStep(ImportSheetFlowSteps.step5SelectImportMethod);
            }, 
            onBack: _onBack,
          ),
          ImportSheetFlowSteps.step5SelectImportMethod => SelectImportMethodSheetContent(
            onOverwrite: () => Navigator.of(context).pop(ImportResult(
              importMethod: ImportMethod.overwrite, 
              dataToImport: _remoteSelectedData!,
            )), 
            onMerge: () => Navigator.of(context).pop(ImportResult(
              importMethod: ImportMethod.merge, 
              dataToImport: _remoteSelectedData!,
            )),
            onReplace:  () => Navigator.of(context).pop(ImportResult(
              importMethod: ImportMethod.replace,
              dataToImport: _remoteSelectedData!,
            )),
            onBack: _onBack,
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
  String? _filePickingError;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Import Data'),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_filePickingError != null)
                    ListTile(
                      leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      title: SelectableText(_filePickingError!),
                      dense: true,
                    ),
                  ListTile(
                    leading: Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Import File"),
                    subtitle: const Text("Select json file which contains data to import"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: () async {
                      final appDatabase = context.read<AppDatabase>();
                      final result = await FileImport.pickAndReadJsonFile(appDatabase: appDatabase);
                      if (result.isError) {
                        setState(() => _filePickingError = result.errorMessage);
                      } else {
                        widget.onFile(result.appData!);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.file_present_sharp, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Restore Backup"),
                    subtitle: const Text("Restore local or cloud Backup"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: widget.onBackup,
                  ),
                  if (context.read<AppSettings>().enableSetupImages)
                    ListTile(
                      leading: Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Import Image Bundle"),
                      subtitle: const Text("Restore data and images from a ZIP bundle"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () async {
                        final result = await ImageStorageService().importBundle();
                        if (result.isCancelled) return;
                        if (result.isError) {
                          setState(() => _filePickingError = result.errorMessage);
                        } else {
                          widget.onFile(result.data!);
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
