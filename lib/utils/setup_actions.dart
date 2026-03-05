import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../models/setup.dart';
import '../pages/setup_page.dart';
import 'file_export.dart';
import 'to_text.dart';

class SetupActions {
  static Future<void> editSetup(BuildContext context, Setup setup) async {
    final data = context.read<AppData>();

    final editedSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage.edit(setup: setup)),
    );
    if (editedSetup == null) return;

    data.editSetup(editedSetup);
  }

  static Future<void> duplicateSetup(BuildContext context, Setup setup) async {
    final data = context.read<AppData>();
    
    final newSetup = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(builder: (context) => SetupPage.duplicate(setup: setup.deepCopy())),
    );
    if (newSetup == null) return;

    data.addSetup(newSetup);
  }

  static Future<void> removeSetup(BuildContext context, Setup setup) async {
    final data = context.read<AppData>();
    data.removeSetups([setup]);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Setup '${setup.name}' moved to trash."),
      duration: const Duration(seconds: 5),
      persist: false,
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () => data.restoreSetups([setup]),
      ),
    ));
  }

  static Future<void> shareSetup(BuildContext context, {required Setup setup}) async {
    final String content = setupToText(
      context: context,
      setup: setup,
    );
    
    await FileExport.shareText(
      context: context, 
      content: content
    );
  }
}
