/// What the map has to say about its pins, beyond drawing them.
enum MapPinState {
  loading,
  error,
  none,
  filtered,
}

/// Why the map shows no pins.
enum MapEmptyReason {
  /// No enabled source holds a positioned item at all.
  none,

  /// Positioned items exist, but the current filters hide all of them.
  filtered,
}

/// Whether any *enabled* map source holds a positioned item, ignoring filters.
///
/// A disabled source counts as absent: its items can never produce a pin, so
/// they must not turn a "nothing yet" state into a "filtered" one.
bool hasAnyPositionedMapData({
  required bool hasSetups,
  required bool hasRatingEntries,
  required bool hasStravaActivities,
  required bool ratingEnabled,
  required bool stravaActive,
}) => hasSetups || (ratingEnabled && hasRatingEntries) || (stravaActive && hasStravaActivities);

/// Returns `null` while pins are visible, otherwise the reason the map is empty.
MapEmptyReason? mapEmptyReason(int visiblePinCount, bool hasAnyPositionedData) {
  if (visiblePinCount > 0) return null;
  return hasAnyPositionedData ? MapEmptyReason.filtered : MapEmptyReason.none;
}
