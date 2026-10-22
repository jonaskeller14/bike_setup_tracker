enum MapPinState {
  loading,
  error,
  none,
  filtered,
  success,
}

bool hasAnyPositionedMapData({
  required bool hasSetups,
  required bool hasStravaActivities,
  required bool stravaActive,
}) => hasSetups || (stravaActive && hasStravaActivities);

MapPinState mapPinState(int visiblePinCount, bool hasAnyPositionedData) {
  if (visiblePinCount > 0) return MapPinState.success;
  return hasAnyPositionedData ? MapPinState.filtered : MapPinState.none;
}
