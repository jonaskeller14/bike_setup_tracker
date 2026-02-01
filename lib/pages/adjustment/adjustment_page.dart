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
