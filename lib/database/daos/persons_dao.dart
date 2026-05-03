import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/adjustments.dart';
import '../tables/persons.dart';
import 'soft_delete_dao_mixin.dart';

part 'persons_dao.g.dart';

@DriftAccessor(tables: [Persons, Adjustments])
class PersonsDao extends DatabaseAccessor<AppDatabase> with _$PersonsDaoMixin, SoftDeletableDaoMixin<Persons, PersonDb, PersonsCompanion> {
  PersonsDao(super.db);

  @override TableInfo<Persons, PersonDb> get softDeletableTable => persons;
  @override Expression<bool> get isDeletedColumn => persons.isDeleted;
  @override Expression<String> get idColumn => persons.id;
  @override PersonsCompanion createSoftDeleteCompanion() => PersonsCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc()));

  Stream<List<PersonDb>> watchAllPersons() => watchAllActive();
  Stream<List<PersonDb>> watchDeletedPersons() => watchAllDeleted();

  Stream<List<PersonWithData>> watchAllPersonsWithData() {
    final query = (select(persons)
          ..where((t) => isDeletedColumn.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: persons.orderIndex)]))
        .join([
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
  Future<bool> updatePerson(PersonsCompanion entry) => update(persons).replace(entry);
  Future<int> deletePerson(String id) => softDelete(id);

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

  Future<List<PersonWithData>> getAllPersonsWithDataBypass() async {
    final query = select(persons).join([
      leftOuterJoin(adjustments, adjustments.personId.equalsExp(persons.id)),
    ]);

    final rows = await query.get();
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
  }

  Future<void> reorder(List<String> ids) async {
    await transaction(() async {
      for (int i = 0; i < ids.length; i++) {
        await (update(persons)..where((t) => t.id.equals(ids[i])))
            .write(PersonsCompanion(orderIndex: Value(i)));
      }
    });
  }
}

class PersonWithData {
  final PersonDb person;
  final List<AdjustmentDb> adjustments;
  PersonWithData({required this.person, required this.adjustments});
}
