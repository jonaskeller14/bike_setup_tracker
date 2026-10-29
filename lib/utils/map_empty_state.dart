enum MapPinState {
  loading,
  error,
  none,
  filtered,
  success,
}

bool hasAnyPositionedMapData({
  required bool hasSetups,
  required bool hasFeedbacks,
  required bool hasStravaActivities,
  required bool feedbackEnabled,
  required bool stravaActive,
}) => hasSetups || (feedbackEnabled && hasFeedbacks) || (stravaActive && hasStravaActivities);

MapPinState mapPinState(int visiblePinCount, bool hasAnyPositionedData) {
  if (visiblePinCount > 0) return MapPinState.success;
  return hasAnyPositionedData ? MapPinState.filtered : MapPinState.none;
}
