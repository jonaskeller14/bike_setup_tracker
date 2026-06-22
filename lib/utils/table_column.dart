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

class TableColumn {
  final TableColumnSection section;
  final String label;
  bool active;

  TableColumn({
    required this.section,
    required this.label,
    required this.active,
  });

  @override // Ignore active property
  bool operator ==(Object other) {
    return identical(this, other) || 
        other is TableColumn &&
        other.section == section &&
        other.label == label;
  }

  @override // Ignore active property
  int get hashCode => Object.hash(section, label);
}