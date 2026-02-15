import 'package:flutter/material.dart';

enum AdjustmentPageMode {
  add,
  edit,
  duplicate,
  template,
}

String? validateAdjustmentName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Name is required';
  return null;
}

Widget previewLabel(BuildContext context) {
  return Positioned(
    top: -1, 
    left: -1, 
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(6),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Text(
        'Preview only — changes won’t be saved',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    ),
  );
}
