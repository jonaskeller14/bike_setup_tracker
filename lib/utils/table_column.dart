enum TableColumnSection {
  generalContext("General Context"),
  weatherContext("Weather Context"),
  componentAdjustments("Component Adjustments"),
  personAttributes("Person Attributes"),
  ratingMetrics("Rating Metrics"),
  ratingScore("Rating");

  final String label;
  const TableColumnSection(this.label);
}

enum SetupColumn {
  name(TableColumnSection.generalContext, "Name", defaultActive: true),
  notes(TableColumnSection.generalContext, "Notes"),
  tags(TableColumnSection.generalContext, "Tags"),
  date(TableColumnSection.generalContext, "Date", defaultActive: true),
  time(TableColumnSection.generalContext, "Time"),
  place(TableColumnSection.generalContext, "Place"),
  altitude(TableColumnSection.generalContext, "Altitude"),
  bike(TableColumnSection.generalContext, "Bike"),
  bookmarked(TableColumnSection.generalContext, "Bookmarked"),
  activities(TableColumnSection.generalContext, "Activities"),

  weatherCode(TableColumnSection.weatherContext, "Weather Code"),
  temperature(TableColumnSection.weatherContext, "Temperature"),
  precipitation(TableColumnSection.weatherContext, "Precipitation"),
  humidity(TableColumnSection.weatherContext, "Humidity"),
  windSpeed(TableColumnSection.weatherContext, "Windspeed"),
  soilMoisture(TableColumnSection.weatherContext, "Soil Moisture"),
  condition(TableColumnSection.weatherContext, "Condition");

  final TableColumnSection section;
  final String label;
  final bool defaultActive;

  const SetupColumn(this.section, this.label, {this.defaultActive = false});
}

/// [active] is mutable. Equality/Hash ignores it
sealed class TableColumn {
  bool active;

  TableColumn({required this.active});

  TableColumnSection get section;
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

class RatingMetricColumn extends TableColumn {
  final String metricId;

  RatingMetricColumn(this.metricId, {required super.active});

  @override
  TableColumnSection get section => TableColumnSection.ratingMetrics;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RatingMetricColumn && other.metricId == metricId;

  @override
  int get hashCode => Object.hash(section, metricId);
}

class RatingScoreColumn extends TableColumn {
  RatingScoreColumn({required super.active});

  @override
  TableColumnSection get section => TableColumnSection.ratingScore;

  @override
  bool operator ==(Object other) => other is RatingScoreColumn;

  @override
  int get hashCode => section.hashCode;
}
