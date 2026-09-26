/// The timeline row kinds that take part in bulk selection. Strava activities
/// and installations are left out: they are not standalone records the user
/// deletes from the timeline.
enum TimelineSelectionKind { setup, taskEntry, ratingEntry }

/// One selected timeline row. A record, so a selection set gets value equality
/// across the three id namespaces for free.
typedef TimelineSelectionId = ({TimelineSelectionKind kind, String id});

TimelineSelectionId setupSelectionId(String id) => (kind: TimelineSelectionKind.setup, id: id);

TimelineSelectionId taskEntrySelectionId(String id) => (kind: TimelineSelectionKind.taskEntry, id: id);

TimelineSelectionId ratingEntrySelectionId(String id) => (kind: TimelineSelectionKind.ratingEntry, id: id);

extension TimelineSelection on Set<TimelineSelectionId> {
  Set<String> idsOf(TimelineSelectionKind kind) => {
    for (final entry in this)
      if (entry.kind == kind) entry.id,
  };

  /// Whether the selection holds nothing but setups — the precondition for the
  /// setup-only bulk actions (tags, bookmark).
  bool get isSetupsOnly => isNotEmpty && every((entry) => entry.kind == TimelineSelectionKind.setup);
}
