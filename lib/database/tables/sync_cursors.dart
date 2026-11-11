import 'package:drift/drift.dart';

/// How far each collection has been pulled: the last document read, in the
/// pull order (`serverUpdatedAt`, then document id).
@DataClassName('SyncCursorDb')
class SyncCursors extends Table {
  TextColumn get collection => text()();

  // Microseconds: Firestore server timestamps have them, drift's dateTime()
  // keeps whole seconds.
  IntColumn get serverUpdatedAtMicros => integer()();

  // All writes of one batch share a server timestamp, so a page that ends
  // inside such a group resumes after this id.
  TextColumn get docId => text()();

  @override
  Set<Column> get primaryKey => {collection};
}
