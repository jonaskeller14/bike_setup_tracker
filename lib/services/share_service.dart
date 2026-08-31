import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../widgets/app_snackbar.dart';

class ShareService {
  static Future<void> shareFile({
    required BuildContext context,
    required String filePath,
    String? text,
    String? errorMessage,
  }) async {
    final fileName = p.basename(filePath);
    final box = context.findRenderObject() as RenderBox?;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text?.isEmpty ?? true ? null : text,
          files: [XFile(filePath)],
          fileNameOverrides: [fileName],
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
          downloadFallbackEnabled: true,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(AppSnackBar.error(context, '${errorMessage ?? 'Error sharing file'}: $e'));
    }
  }

  static Future<void> shareText({
    required BuildContext context,
    required String text,
    String? errorMessage,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
          downloadFallbackEnabled: true,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(AppSnackBar.error(context, '${errorMessage ?? 'Error sharing text'}: $e'));
    }
  }
}
