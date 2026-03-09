import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/persons.dart';
import '../tables/adjustments.dart';

part 'persons_dao.g.dart';

@DriftAccessor(tables: [Persons, Adjustments])
class PersonsDao extends DatabaseAccessor<AppDatabase> with _$PersonsDaoMixin {
  PersonsDao(super.db);

  Stream<List<PersonDb>> watchAllPersons() => (select(persons)..where((t) => t.isDeleted.equals(false))).watch();

  Stream<List<PersonWithData>> watchAllPersonsWithData() {
    final query = (select(persons)..where((t) => t.isDeleted.equals(false))).join([
      leftOuterJoin(adjustments, adjustments.personId.equalsExp(persons.id)),
    ]);

    return query.watch().map((rows) {
      final Map<String, PersonWithData> grouped = {};
      for (final row in rows) {
        final person = row.readTable(persons);
        final adjustment = row.readTableOrNull(adjustments);

        final entry = grouped.putIfAbsent(
          person.id,
          () => PersonWithData(person: person, adjustments: []),
        );
        if (adjustment != null && !entry.adjustments.any((a) => a.id == adjustment.id)) {
          entry.adjustments.add(adjustment);
        }
      }
      for (final entry in grouped.values) {
        entry.adjustments.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      }
      return grouped.values.toList();
    });
  }

  Future<PersonDb?> getPerson(String id) {
    return (select(persons)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<AdjustmentDb>> watchAdjustmentsForPerson(String personId) {
    return (select(adjustments)
          ..where((t) => t.personId.equals(personId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .watch();
  }

  Future<int> insertPerson(PersonsCompanion entry) => into(persons).insert(entry);
  Future updatePerson(PersonsCompanion entry) => update(persons).replace(entry);
  Future deletePerson(String id) => (update(persons)..where((t) => t.id.equals(id))).write(PersonsCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc())));

  Future<void> insertPersonWithData({
    required PersonsCompanion person,
    required List<AdjustmentsCompanion> adjustmentsList,
  }) async {
    await transaction(() async {
      await into(persons).insert(person);
      for (final adj in adjustmentsList) {
        await into(adjustments).insert(adj);
      }
    });
  }

  Future<void> updatePersonWithData({
    required PersonsCompanion person,
    required List<AdjustmentsCompanion> adjustmentsList,
  }) async {
    await transaction(() async {
      await update(persons).replace(person);
      await (delete(adjustments)..where((t) => t.personId.equals(person.id.value))).go();
      for (final adj in adjustmentsList) {
        await into(adjustments).insert(adj);
      }
    });
  }
}

class PersonWithData {
  final PersonDb person;
  final List<AdjustmentDb> adjustments;
  PersonWithData({required this.person, required this.adjustments});
}
