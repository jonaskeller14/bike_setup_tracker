import 'package:flutter/material.dart';

import '../../models/setup.dart';
import 'sheet_header.dart';

Future<Setup?> showPickSetupSheet(
  BuildContext context, {
  required String title,
  required List<Setup> options,
  String? Function(Setup setup)? subtitleFor,
}) {
  return showModalBottomSheet<Setup>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: title),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final setup in options)
                  ListTile(
                    leading: const Icon(Setup.iconData),
                    title: Text(setup.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: switch (subtitleFor?.call(setup)) {
                      final subtitle? => Text(subtitle),
                      null => null,
                    },
                    onTap: () => Navigator.pop(context, setup),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
