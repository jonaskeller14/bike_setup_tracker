// TableColumn.active is mutable by design and excluded from equality.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import '../services/bike_adjustment_column_service.dart';

enum TableColumnSection {
  generalContext,
  weatherContext,
  componentAdjustments,
  personAttributes,
  feedback,
}

enum SetupColumn {
  name(TableColumnSection.generalContext, defaultActive: true),
  notes(TableColumnSection.generalContext),
  tags(TableColumnSection.generalContext),
  date(TableColumnSection.generalContext, defaultActive: true),
  time(TableColumnSection.generalContext),
  place(TableColumnSection.generalContext),
  altitude(TableColumnSection.generalContext),
  bike(TableColumnSection.generalContext),
  bookmarked(TableColumnSection.generalContext),
  activities(TableColumnSection.generalContext),

  weatherCode(TableColumnSection.weatherContext),
  temperature(TableColumnSection.weatherContext),
  precipitation(TableColumnSection.weatherContext),
  humidity(TableColumnSection.weatherContext),
  windSpeed(TableColumnSection.weatherContext),
  soilMoisture(TableColumnSection.weatherContext),
  condition(TableColumnSection.weatherContext),

  testSession(TableColumnSection.feedback);

  final TableColumnSection section;
  final bool defaultActive;

  const SetupColumn(this.section, {this.defaultActive = false});
}

/// What the column sheet switches on and off.
/// [active] is mutable. Equality/Hash ignores it
sealed class SelectableColumn {
  bool active;

  SelectableColumn({required this.active});

  TableColumnSection get section;
}

/// A column of the setup tables of the details pages.
sealed class TableColumn extends SelectableColumn {
  TableColumn({required super.active});
}

enum RunFeedbackField { issues, evaluation, notes }

/// A column of the run table of a test session: what the feedbacks on a run say.
class RunFeedbackColumn extends SelectableColumn {
  final RunFeedbackField field;

  RunFeedbackColumn(this.field, {required super.active});

  @override
  TableColumnSection get section => TableColumnSection.feedback;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RunFeedbackColumn && other.field == field;

  @override
  int get hashCode => Object.hash(section, field);
}

class SetupTableColumn extends TableColumn {
  final SetupColumn column;

  SetupTableColumn(this.column, {required super.active});

  @override
  TableColumnSection get section => column.section;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SetupTableColumn && other.column == column;

  @override
  int get hashCode => Object.hash(section, column);
}

class ComponentAdjustmentColumn extends TableColumn {
  final String adjustmentId;

  ComponentAdjustmentColumn(this.adjustmentId, {required super.active});

  @override
  TableColumnSection get section => TableColumnSection.componentAdjustments;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ComponentAdjustmentColumn && other.adjustmentId == adjustmentId;

  @override
  int get hashCode => Object.hash(section, adjustmentId);
}

/// A bike-level column merging the adjustments of the components in one slot lane.
class BikeAdjustmentColumn extends TableColumn {
  final BikeAdjustmentColumnKey key;

  BikeAdjustmentColumn(this.key, {required super.active});

  @override
  TableColumnSection get section => TableColumnSection.componentAdjustments;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BikeAdjustmentColumn && other.key == key;

  @override
  int get hashCode => Object.hash(section, key);
}

class PersonAttributeColumn extends TableColumn {
  final String adjustmentId;

  PersonAttributeColumn(this.adjustmentId, {required super.active});

  @override
  TableColumnSection get section => TableColumnSection.personAttributes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PersonAttributeColumn && other.adjustmentId == adjustmentId;

  @override
  int get hashCode => Object.hash(section, adjustmentId);
}

/// The setup's rank on its bike, from feedback comparisons. Sortable only: a
/// rank is not a measurement, so charts leave it out.
class SetupRankColumn extends TableColumn {
  SetupRankColumn({required super.active});

  @override
  TableColumnSection get section => TableColumnSection.feedback;

  @override
  bool operator ==(Object other) => other is SetupRankColumn;

  @override
  int get hashCode => section.hashCode;
}
