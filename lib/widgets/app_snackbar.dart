import 'package:flutter/material.dart';

import '../theme.dart';

class AppSnackBar extends SnackBar {
  static const _defaultDuration = Duration(seconds: 5);

  AppSnackBar.success(
    BuildContext context,
    String message, {
    AppSnackBarAction? action,
    super.duration = _defaultDuration,
    super.key,
  }) : super(
         persist: false,
         showCloseIcon: true,
         closeIconColor: Theme.of(context).extension<SnackBarColors>()!.onSuccess,
         backgroundColor: Theme.of(context).extension<SnackBarColors>()!.success,
         content: _AppSnackBarContent(
           message: message,
           icon: Icons.check_circle_outline,
           foregroundColor: Theme.of(context).extension<SnackBarColors>()!.onSuccess,
         ),
         action: _buildAction(
           action,
           Theme.of(context).extension<SnackBarColors>()!.onSuccess,
         ),
       );

  AppSnackBar.info(
    BuildContext context,
    String message, {
    AppSnackBarAction? action,
    super.duration = _defaultDuration,
    super.key,
  }) : super(
         persist: false,
         showCloseIcon: true,
         closeIconColor: Theme.of(context).colorScheme.onSurface,
         backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
         content: _AppSnackBarContent(
           message: message,
           icon: Icons.info_outline,
           foregroundColor: Theme.of(context).colorScheme.onSurface,
         ),
         action: _buildAction(action, Theme.of(context).colorScheme.onSurface),
       );

  AppSnackBar.error(
    BuildContext context,
    String message, {
    AppSnackBarAction? action,
    super.duration = _defaultDuration,
    super.key,
  }) : super(
         persist: false,
         showCloseIcon: true,
         closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
         backgroundColor: Theme.of(context).colorScheme.errorContainer,
         content: _AppSnackBarContent(
           message: message,
           icon: Icons.error_outline,
           foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
         ),
         action: _buildAction(
           action,
           Theme.of(context).colorScheme.onErrorContainer,
         ),
       );

  static SnackBarAction? _buildAction(AppSnackBarAction? action, Color textColor) {
    if (action == null) return null;
    return SnackBarAction(
      label: action.label,
      textColor: textColor,
      onPressed: action.onPressed,
    );
  }
}

class AppSnackBarAction {
  const AppSnackBarAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

class _AppSnackBarContent extends StatelessWidget {
  const _AppSnackBarContent({
    required this.message,
    required this.icon,
    required this.foregroundColor,
  });

  final String message;
  final IconData icon;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        Icon(icon, color: foregroundColor),
        Expanded(
          child: Text(message, style: TextStyle(color: foregroundColor)),
        ),
      ],
    );
  }
}
