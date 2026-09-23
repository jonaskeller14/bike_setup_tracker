import 'package:flutter/material.dart';

import '../../models/component/component.dart';

Future<bool> confirmComponentDescendantImpact(
  BuildContext context, {
  required Component component,
  required List<Component> descendants,
  required String action,
}) async {
  if (descendants.isEmpty) return true;
  final names = descendants.map((child) => child.name).toList()..sort();
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$action ${component.name}?'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${names.length} mounted ${names.length == 1 ? 'component' : 'components'} '
              'will be affected. They remain linked and return automatically when '
              '${component.name} is restored.',
            ),
            const SizedBox(height: 12),
            for (final name in names)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $name', overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  ) ??
  false;
}
