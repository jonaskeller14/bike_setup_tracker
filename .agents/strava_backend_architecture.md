# Strava Backend Architecture & Strategy

This document summarizes the high-performance, cost-efficient Strava integration architecture implemented for the Bike Setup Tracker.

## 1. Webhook Strategy (High Performance)
To prevent Strava from timing out or retrying webhooks, the `stravaWebhook` endpoint acts as a "front door."

- **Handshake**: Responds to GET requests for subscription verification.
- **Async Processing**: For POST events, it does NOT process the activity immediately. Instead, it enqueues a Cloud Task and returns `200 OK` within 100ms.
- **Native Idempotency**: Each task is enqueued with a unique `taskName` format: `${athleteId}_${activityId}_${aspectType}_${eventTime}`. 
    - Google Cloud Tasks automatically rejects duplicate `taskName`s within an hour, preventing double-processing if Strava retries the same event.
- **Regionality**: All functions and queues are pinned to `europe-west3` to minimize latency and ensure consistency.

## 2. Background Worker Strategy
Two specialized workers handle the heavy lifting:

- **`webhookWorker` (Real-time)**: Triggered by webhooks.
    - Resolves the Strava `athlete_id` to one or more internal app `userId`s.
    - Fetches the activity details once, then saves to all linked users.
    - Handles metadata updates and deletions (using the "Tombstone" pattern).
- **`scheduledSyncWorker` (Full/Scheduled)**: Triggered by manual syncs or the hourly scheduler.
    - Performs paginated history fetching (100 activities per page).
    - Saves data in "Batches" (500 per document) to optimize Firestore write costs.

## 3. Scheduled Weekly Sync
An hourly scheduler (`enqueueWeeklySyncs`) ensures that even if webhooks fail, every user is synced at least once a week.

- **Query Optimization**: Uses a composite index to find users where:
  - `sync_day == today`
  - `strava_connected == true`
  - `strava_sync_last_full < 20 hours ago`
- **Throttling**: Processes users in small batches (limit 4 per hour) to stay well within the Strava Rate Limits and Firebase Free Tier (Blaze Plan).

## 4. Security & Costs
- **App Check**: Enabled for all Sensitive Callable functions to prevent unauthorized API calls from outside the app.
- **TTL (Time-To-Live)**: The `expiresAt` field is configured on `users`, `athletes`, and `activity_batches`. When a user deauthorizes Strava, their data is automatically purged from the database after 30 days to keep storage costs at zero.
- **Indices**: Managed via `firestore.indexes.json` to ensure complex queries (like the weekly enqueuer) are performant.

## 5. Critical Configuration (Know Before You Edit)
- **Deployment**: Always use `firebase deploy --only functions` or `firestore:indexes`.
- **Task Queue Names**: For 2nd Gen, always use the **Fully Qualified Resource Name** in `taskQueue()` calls to ensure target resolution in `europe-west3`:
    - `projects/bike-setup-tracker-strava/locations/europe-west3/functions/<workerName>`
