import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_data.dart';
import '../../utils/file_import.dart';
import '../../database/app_database.dart';
import 'data_select.dart';
import 'import_merge_overwrite.dart';
import 'sheet.dart';
import 'backup.dart';

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
      return ImportSheetFlow();
    },
  );

  if (importResult == null) return;
  if (!context.mounted) return;

  try {
    final localData = context.read<AppData>();
    switch (importResult.importMethod) {
      case ImportMethod.overwrite:
        FileImport.overwrite(remoteData: importResult.appData, localData: localData);
      case ImportMethod.merge:
        FileImport.merge(remoteData: importResult.appData, localData: localData);
    }
    scaffoldMessenger.showSnackBar(
      SnackBar(
        persist: false,
        showCloseIcon: true,
        content: switch (importResult.importMethod) {
          ImportMethod.merge => const Text("Data merged successfully"),
          ImportMethod.overwrite => const Text("Data overwritten successfully"),
        },
      )
    );
  } catch (e) {
    scaffoldMessenger.showSnackBar(SnackBar(
      persist: false,
      showCloseIcon: true,
      closeIconColor: onErrorContainerColor,
      content: switch (importResult.importMethod) {
        ImportMethod.merge => Text("Merge failed: $e", style: TextStyle(color: onErrorContainerColor)),
        ImportMethod.overwrite => Text("Overwriting failed: $e", style: TextStyle(color: onErrorContainerColor)),
      },
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
}

class ImportResult {
  final ImportMethod importMethod;
  final AppData appData;
  const ImportResult({required this.importMethod, required this.appData});
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

  AppData? _remoteAllData;
  AppData? _remoteSelectedData;

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
            onFile: (AppData appData) {
              _remoteAllData = appData;
              if (_remoteAllData == null) return;
              _setNextStep(ImportSheetFlowSteps.step3SelectDataMethod);
            }, 
            onBackup: () => _setNextStep(ImportSheetFlowSteps.step2SelectBackup),
          ),
          ImportSheetFlowSteps.step2SelectBackup => BackupSheetContent(
            onRestore: (AppData appData) async {
              _remoteAllData = appData;
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
            allData: _remoteAllData!,
            onConfirm: (AppData selectedData) {
              _remoteSelectedData = selectedData;
              _setNextStep(ImportSheetFlowSteps.step5SelectImportMethod);
            }, 
            onBack: _onBack,
          ),
          ImportSheetFlowSteps.step5SelectImportMethod => SelectImportMethodSheetContent(
            onOverwrite: () => Navigator.of(context).pop(ImportResult(
              importMethod: ImportMethod.overwrite, 
              appData: _remoteSelectedData!,
            )), 
            onMerge: () => Navigator.of(context).pop(ImportResult(
              importMethod: ImportMethod.merge, 
              appData: _remoteSelectedData!,
            )), 
            onBack: _onBack,
          ),
        },
      ),
    );
  }
}

class SelectImportSourceSheetContent extends StatefulWidget {
  final Function(AppData) onFile;
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                sheetTitle(context, 'Import Data'),
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
                    onTap: widget.onBackup
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
