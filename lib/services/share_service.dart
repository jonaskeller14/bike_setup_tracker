import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../widgets/app_snackbar.dart';

class ShareService {
  static Future<void> shareFile({
    required BuildContext context,
    required String filePath,
    String? fileName,
    String? text,
    String? errorMessage,
  }) async {
    fileName ??= p.basename(filePath);
    // Apple share sheets turn the text into a second item, saved as an extra .txt file.
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) text = null;
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
