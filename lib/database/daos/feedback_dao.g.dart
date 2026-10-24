// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_dao.dart';

// ignore_for_file: type=lint
mixin _$FeedbackDaoMixin on DatabaseAccessor<AppDatabase> {
  $BikesTable get bikes => attachedDatabase.bikes;
  $PersonsTable get persons => attachedDatabase.persons;
  $SetupsTable get setups => attachedDatabase.setups;
  $FeedbacksTable get feedbacks => attachedDatabase.feedbacks;
  $FeedbackObservationsTable get feedbackObservations =>
      attachedDatabase.feedbackObservations;
  $FeedbackComparisonsTable get feedbackComparisons =>
      attachedDatabase.feedbackComparisons;
  $TestSessionsTable get testSessions => attachedDatabase.testSessions;
  FeedbackDaoManager get managers => FeedbackDaoManager(this);
}

class FeedbackDaoManager {
  final _$FeedbackDaoMixin _db;
  FeedbackDaoManager(this._db);
  $$BikesTableTableManager get bikes =>
      $$BikesTableTableManager(_db.attachedDatabase, _db.bikes);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$SetupsTableTableManager get setups =>
      $$SetupsTableTableManager(_db.attachedDatabase, _db.setups);
  $$FeedbacksTableTableManager get feedbacks =>
      $$FeedbacksTableTableManager(_db.attachedDatabase, _db.feedbacks);
  $$FeedbackObservationsTableTableManager get feedbackObservations =>
      $$FeedbackObservationsTableTableManager(
        _db.attachedDatabase,
        _db.feedbackObservations,
      );
  $$FeedbackComparisonsTableTableManager get feedbackComparisons =>
      $$FeedbackComparisonsTableTableManager(
        _db.attachedDatabase,
        _db.feedbackComparisons,
      );
  $$TestSessionsTableTableManager get testSessions =>
      $$TestSessionsTableTableManager(_db.attachedDatabase, _db.testSessions);
}
