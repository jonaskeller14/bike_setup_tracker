import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/app_database.dart';
import '../services/file_save_service.dart';
import 'app_info.dart';
import 'file_export.dart';
import 'url.dart';

Future<void> openStorePage(BuildContext context) async {
  unawaited(HapticFeedback.lightImpact());
  final url = Theme.of(context).platform == TargetPlatform.iOS ? AppInfo.appStorePageUrl : AppInfo.playStoreUrl;
  await launchAppUrl(context, url: url, launchMode: LaunchMode.externalApplication);
}

Future<void> exportBackupForUpdate(
  BuildContext context,
  AppDatabase database, {
  FileSaveService? fileSaveService,
}) async {
  unawaited(HapticFeedback.lightImpact());
  await FileExport.exportFreshBackupBundle(context, database: database, fileSaveService: fileSaveService);
}
