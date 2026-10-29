/// A value stored in a soft-deleted setup, as the raw column text.
class DeletedRecordValue {
  final String recordId;
  final String? name;
  final DateTime dateTimeLocal;
  final String rawValue;

  const DeletedRecordValue({
    required this.recordId,
    required this.name,
    required this.dateTimeLocal,
    required this.rawValue,
  });
}
