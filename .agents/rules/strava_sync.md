# Strava Sync Protocol

Whenever you make structural or logical modifications to how Strava activities are synced, paginated, handled via webhooks, or deleted, you MUST review and update the relevant explanation and mermaid graphs in the documentation file: `docs/strava_sync_logic.md`.

This ensures that the mental model of the sync pipeline (especially the `docChanges` vs `docs` optimization and tombstone pattern) remains accurate and in-sync with the codebase.

Code paths to watch:
- `backend_strava/` (especially Webhook and Batching logic)
- `lib/services/strava_service.dart` (Firestore streaming logic)
- `lib/repositories/app_repository.dart` (SQLite upsert/deletion handling)
- `lib/database/daos/strava_dao.dart` 
