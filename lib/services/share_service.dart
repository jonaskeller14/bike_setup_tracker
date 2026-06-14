import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareFile({
    required BuildContext context,
    required String filePath,
    required String text,
    String? errorMessage,
  }) async {
    final fileName = p.basename(filePath);
    final box = context.findRenderObject() as RenderBox?;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [XFile(filePath)],
          fileNameOverrides: [fileName],
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
          downloadFallbackEnabled: true,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: onErrorContainerColor,
          content: Text('${errorMessage ?? 'Error sharing file'}: $e', style: TextStyle(color: onErrorContainerColor)),
          backgroundColor: errorContainerColor,
        ),
      );
    }
  }

  static Future<void> shareText({
    required BuildContext context,
    required String text,
    String? errorMessage,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
          downloadFallbackEnabled: true,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          persist: false,
          showCloseIcon: true,
          closeIconColor: onErrorContainerColor,
          content: Text('${errorMessage ?? 'Error sharing text'}: $e', style: TextStyle(color: onErrorContainerColor)),
          backgroundColor: errorContainerColor,
        ),
      );
    }
  }
}
