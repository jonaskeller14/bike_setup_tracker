import '../../models/adjustment/adjustment.dart';
import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/feedback/test_session.dart';
import '../../models/person.dart';
import '../../models/setup.dart';
import '../../models/syncable.dart';
import '../../models/task/task_entry.dart';
import '../../models/task/task_rule.dart';

enum SyncCollection {
  persons('persons'),
  bikes('bikes'),
  components('components'),
  setups('setups', needsAdjustmentTypes: true),
  taskRules('task_rules'),
  taskEntries('task_entries'),
  feedbacks('feedbacks'),
  testSessions('test_sessions', needsAdjustmentTypes: true);

  const SyncCollection(this.collectionName, {this.needsAdjustmentTypes = false});

  final String collectionName; // Name of the Firestore collection = name of root SQLite table
  final bool needsAdjustmentTypes;

  static SyncCollection? fromCollectionName(String name) {
    for (final collection in values) {
      if (collection.collectionName == name) return collection;
    }
    return null;
  }

  Syncable fromJson(Map<String, dynamic> json, Map<String, AdjustmentType> adjustmentTypes) => switch (this) {
    persons => Person.fromJson(json),
    bikes => Bike.fromJson(json),
    components => Component.fromJson(json: json),
    setups => Setup.fromJson(json: json, adjustmentTypes: adjustmentTypes),
    taskRules => TaskRule.fromJson(json),
    taskEntries => TaskEntry.fromJson(json),
    feedbacks => RideFeedback.fromJson(json),
    testSessions => TestSession.fromJson(json: json, adjustmentTypes: adjustmentTypes),
  };
}
