enum MapPinState {
  loading,
  error,
  none,
  filtered,
  success,
}

bool hasAnyPositionedMapData({
  required bool hasSetups,
  required bool hasRatingEntries,
  required bool hasStravaActivities,
  required bool ratingEnabled,
  required bool stravaActive,
}) => hasSetups || (ratingEnabled && hasRatingEntries) || (stravaActive && hasStravaActivities);

MapPinState mapPinState(int visiblePinCount, bool hasAnyPositionedData) {
  if (visiblePinCount > 0) return MapPinState.success;
  return hasAnyPositionedData ? MapPinState.filtered : MapPinState.none;
}
