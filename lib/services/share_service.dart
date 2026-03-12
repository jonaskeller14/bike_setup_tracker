import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareFile({
    required BuildContext context,
    required String filePath,
    required String subject,
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
          subject: subject,
          text: text,
          files: [XFile(filePath)],
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
          content: Text('${errorMessage ?? 'Error sharing file'}: $e'),
          backgroundColor: errorContainerColor,
        ),
      );
    }
  }

  static Future<void> shareText({
    required BuildContext context,
    required String text,
    String subject = 'Bike Setup Export',
    String? errorMessage,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;
    final onErrorContainerColor = Theme.of(context).colorScheme.onErrorContainer;

    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: subject,
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
          content: Text('${errorMessage ?? 'Error sharing text'}: $e'),
          backgroundColor: errorContainerColor,
        ),
      );
    }
  }
}
