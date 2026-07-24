---
description: Scaffold a new Drift table end-to-end (table → migration → build_runner → DAO → model → mapper)
argument-hint: "<TableName> and a short description of its columns/relationships"
allowed-tools: Read, Edit, Write, Grep, Glob, Bash(flutter pub run build_runner build:*), Bash(flutter analyze:*), Bash(flutter test:*)
---

Add a new Drift table and wire it through every layer, following this repo's existing
patterns exactly. `$ARGUMENTS` = the table name and a short description of its columns and
relationships.

Before writing anything, open the nearest existing table/DAO/model of the same shape and
mirror it. Good references: a simple leaf table (`lib/database/tables/persons.dart`), its
DAO (`lib/database/daos/persons_dao.dart`), and how `AppRepository` maps DB entities to
models via `.toModel()`.

## 1. Confirm the shape (ask, don't guess)
- Restate the intended table: name, columns (+ types/nullability), primary key, foreign
  keys (`references(..., onDelete:)`), and any `customConstraints`.
- Confirm whether it is soft-deletable (almost all are). If yes it needs the standard
  `isDeleted` / `lastModified` columns and the `SoftDeletableDaoMixin` on its DAO.
- If anything is ambiguous, STOP and ask before creating files.

## 2. Table definition
- Create `lib/database/tables/<snake_case>.dart` with `@DataClassName('<Name>Db')` on a
  `class <Names> extends Table`. Match the column idioms in existing tables
  (`textEnum<...>()`, `.nullable()`, `references(...)`, `Set<Column> get primaryKey`).
- Register the table class in the `tables:` list of `@DriftDatabase` in
  `lib/database/app_database.dart`.

## 3. Migration (schema bump)
- In `lib/database/app_database.dart`, increment `schemaVersion` by 1.
- Add a matching `if (from < <newVersion>) { ... }` block at the end of `onUpgrade`,
  using `m.createTable(...)` (or `m.addColumn` for a column-only change). Follow the
  surrounding blocks: a short comment explaining *why*, and note what happens to existing
  rows. Never edit an existing `if (from < N)` block — only append the new one.

## 4. Generate
- Run `flutter pub run build_runner build --delete-conflicting-outputs` and confirm the
  `.g.dart` output compiles.

## 5. DAO
- Create `lib/database/daos/<snake_case>_dao.dart` mirroring `persons_dao.dart`:
  `@DriftAccessor(tables: [...])`, `part '<snake_case>_dao.g.dart';`, and
  `class <Names>Dao extends DatabaseAccessor<AppDatabase> with _$<Names>DaoMixin,
  SoftDeletableDaoMixin<<Names>, <Name>Db, <Names>Companion>`. Implement the four
  overrides (`softDeletableTable`, `isDeletedColumn`, `idColumn`,
  `createSoftDeleteCompanion`) and the `watch...` streams the same way.
- Register the DAO in the `daos:` list of `@DriftDatabase`, then re-run build_runner.

## 6. Domain model + mapper
- Create the domain model under `lib/models/` (matching the folder convention of its
  siblings). Add a `toModel()` mapper that converts the `<Name>Db` entity to the model,
  the way existing entities do.
- If the model is round-tripped to JSON (export/import), add `@JsonSerializable` and
  re-run build_runner.

## 7. Wire into AppRepository (only if it holds filtered state)
- If this entity participates in the selected-bike filtered state, add the in-memory
  map/list, the loader that maps DB rows via `.toModel()`, and `notifyListeners()`,
  following the existing entities in `lib/repositories/app_repository.dart`. Skip this
  step for standalone/lookup tables.

## 8. Verify
- Run `flutter analyze` on the touched files and `flutter test` (at minimum the database /
  migration tests). If a migration test exists for the schema, extend it to cover the new
  version. Report what passed.

## Constraints
- Mirror existing tables/DAOs/models — do not introduce a new style.
- Every schema change is append-only in `onUpgrade`; never renumber or edit past
  migration blocks, and always bump `schemaVersion` to match.
- Run `build_runner` after table changes AND after DAO changes before relying on generated
  symbols.
- Do not hand-edit any `*.g.dart` file.
