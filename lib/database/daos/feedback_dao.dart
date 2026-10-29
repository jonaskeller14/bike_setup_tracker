import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/feedback_comparisons.dart';
import '../tables/feedback_observations.dart';
import '../tables/feedbacks.dart';
import '../tables/test_sessions.dart';
import 'soft_delete_dao_mixin.dart';

part 'feedback_dao.g.dart';

@DriftAccessor(tables: [Feedbacks, FeedbackObservations, FeedbackComparisons, TestSessions])
class FeedbackDao extends DatabaseAccessor<AppDatabase>
    with _$FeedbackDaoMixin, SoftDeletableDaoMixin<Feedbacks, FeedbackDb, FeedbacksCompanion> {
  FeedbackDao(super.db);

  @override
  TableInfo<Feedbacks, FeedbackDb> get softDeletableTable => feedbacks;
  @override
  Expression<bool> get isDeletedColumn => feedbacks.isDeleted;
  @override
  Expression<String> get idColumn => feedbacks.id;
  @override
  FeedbacksCompanion createSoftDeleteCompanion() =>
      FeedbacksCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc()));

  // --- Feedbacks ---

  Stream<List<FeedbackWithChildren>> watchAllFeedbacksWithChildren() =>
      _withChildren(select(feedbacks)..where((t) => t.isDeleted.equals(false))).watch().map(_group);

  Stream<List<FeedbackWithChildren>> watchDeletedFeedbacksWithChildren() =>
      _withChildren(select(feedbacks)..where((t) => t.isDeleted.equals(true))).watch().map(_group);

  Future<List<FeedbackWithChildren>> getAllFeedbacksWithChildrenBypass() async =>
      _group(await _withChildren(select(feedbacks)).get());

  Future<FeedbackDb?> getFeedback(String id) {
    return (select(feedbacks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _withChildren(SimpleSelectStatement<$FeedbacksTable, FeedbackDb> query) {
    return query.join([
      leftOuterJoin(feedbackObservations, feedbackObservations.feedbackId.equalsExp(feedbacks.id)),
      leftOuterJoin(feedbackComparisons, feedbackComparisons.feedbackId.equalsExp(feedbacks.id)),
    ]);
  }

  /// Both child tables are joined, so each child repeats once per row of the
  /// other; the sets drop the repeats.
  List<FeedbackWithChildren> _group(List<TypedResult> rows) {
    final Map<String, FeedbackWithChildren> grouped = {};
    for (final row in rows) {
      final feedback = row.readTable(feedbacks);
      final observation = row.readTableOrNull(feedbackObservations);
      final comparison = row.readTableOrNull(feedbackComparisons);

      final entry = grouped.putIfAbsent(
        feedback.id,
        () => FeedbackWithChildren(feedback: feedback, observations: {}, comparisons: {}),
      );
      if (observation != null) entry.observations.add(observation);
      if (comparison != null) entry.comparisons.add(comparison);
    }
    return grouped.values.toList();
  }

  Future<void> insertFeedbackWithChildren({
    required FeedbacksCompanion feedback,
    required List<FeedbackObservationsCompanion> observations,
    required List<FeedbackComparisonsCompanion> comparisons,
  }) async {
    await transaction(() async {
      await into(feedbacks).insert(feedback);
      await _insertChildren(observations, comparisons);
    });
  }

  /// Inserts or replaces the feedback; its children are replaced as a whole.
  Future<void> upsertFeedbackWithChildren({
    required FeedbacksCompanion feedback,
    required List<FeedbackObservationsCompanion> observations,
    required List<FeedbackComparisonsCompanion> comparisons,
  }) async {
    await transaction(() async {
      await into(feedbacks).insertOnConflictUpdate(feedback);
      await (delete(feedbackObservations)..where((t) => t.feedbackId.equals(feedback.id.value))).go();
      await (delete(feedbackComparisons)..where((t) => t.feedbackId.equals(feedback.id.value))).go();
      await _insertChildren(observations, comparisons);
    });
  }

  Future<void> _insertChildren(
    List<FeedbackObservationsCompanion> observations,
    List<FeedbackComparisonsCompanion> comparisons,
  ) async {
    for (final observation in observations) {
      await into(feedbackObservations).insertOnConflictUpdate(observation);
    }
    for (final comparison in comparisons) {
      await into(feedbackComparisons).insertOnConflictUpdate(comparison);
    }
  }

  Future<int> deleteFeedback(String id) => softDelete(id);

  Future<int> restoreFeedback(String id) {
    return (update(feedbacks)..where((t) => t.id.equals(id))).write(
      FeedbacksCompanion(isDeleted: const Value(false), lastModified: Value(DateTime.now().toUtc())),
    );
  }

  // --- Test sessions ---

  Stream<List<TestSessionDb>> watchAllTestSessions() =>
      (select(testSessions)..where((t) => t.isDeleted.equals(false))).watch();

  Stream<List<TestSessionDb>> watchDeletedTestSessions() =>
      (select(testSessions)..where((t) => t.isDeleted.equals(true))).watch();

  Future<List<TestSessionDb>> getAllTestSessionsBypass() => select(testSessions).get();

  Future<int> insertTestSession(TestSessionsCompanion entry) => into(testSessions).insert(entry);

  Future<int> upsertTestSession(TestSessionsCompanion entry) => into(testSessions).insertOnConflictUpdate(entry);

  Future<int> deleteTestSession(String id) {
    return (update(testSessions)..where((t) => t.id.equals(id))).write(
      TestSessionsCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc())),
    );
  }

  Future<int> restoreTestSession(String id) {
    return (update(testSessions)..where((t) => t.id.equals(id))).write(
      TestSessionsCompanion(isDeleted: const Value(false), lastModified: Value(DateTime.now().toUtc())),
    );
  }
}

class FeedbackWithChildren {
  final FeedbackDb feedback;
  final Set<FeedbackObservationDb> observations;
  final Set<FeedbackComparisonDb> comparisons;
  FeedbackWithChildren({required this.feedback, required this.observations, required this.comparisons});
}
