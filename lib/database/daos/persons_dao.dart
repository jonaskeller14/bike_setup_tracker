import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/persons.dart';
import '../tables/adjustments.dart';

part 'persons_dao.g.dart';

@DriftAccessor(tables: [Persons, Adjustments])
class PersonsDao extends DatabaseAccessor<AppDatabase> with _$PersonsDaoMixin {
  PersonsDao(super.db);

  Stream<List<PersonDb>> watchAllPersons() {
    return (select(persons)..where((t) => t.isDeleted.equals(false))).watch();
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
  Future deletePerson(String id) => (update(persons)..where((t) => t.id.equals(id))).write(const PersonsCompanion(isDeleted: Value(true)));
}
