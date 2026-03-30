# Firestore Snapshot: `docs` vs `docChanges`

Before we look at the cases, let's understand why `docChanges` is a massive optimization over `docs`.

## `snapshot.docs`
`snapshot.docs` is a complete list of **every single document** in the collection (or query results) that currently exists in your local cache or on the server.
If you have 10,000 activities split into 20 batches of 500, `snapshot.docs` will contain all 20 batches. 
If Strava updates **one** activity in **one** batch, the listener fires, and if you loop over `snapshot.docs`, you are re-processing **all 20 batches (10,000 activities)** from scratch.

## `snapshot.docChanges`
`snapshot.docChanges` is a list of the **deltas (diffs)**. It only contains the specific documents that were `added`, `modified`, or `removed` since the last time the listener fired.
If Strava updates **one** activity in **one** batch, `snapshot.docChanges` will contain exactly **1 item**: the `modified` batch.
By looping over `docChanges`, you only process **500 activities** instead of 10,000, achieving a 95% reduction in CPU and SQLite overhead in this scenario.

---

# Sync Flow Diagrams

Below are the graphical representations of how the app handles different sync events using our optimized Tombstone + `docChanges` architecture.

## Case 1: Webhook (Add / Update / Delete)

When a single activity happens on Strava, Strava calls the webhook. The webhook modifies exactly **one** batch document in Firestore.

```mermaid
sequenceDiagram
    participant Strava
    participant Webhook (Backend)
    participant Firestore
    participant App (docChanges)
    participant SQLite (Local DB)

    Strava->>Webhook: Webhook Event (Delete Activity #123)
    Webhook->>Firestore: Update Batch (set isDeleted: true for #123)
    Firestore-->>App (docChanges): Type: MODIFIED (1 Batch)
    
    App (docChanges)->>App (docChanges): Parse 500 Activities in Batch
    App (docChanges)->>App (docChanges): Oh, #123 is a Tombstone! (add to toDelete)
    App (docChanges)->>SQLite (Local DB): Transaction: Delete #123, Upsert 499 others
    SQLite (Local DB)-->>App (docChanges): Done
```

## Case 2: Manual Sync (Fetch Recent)

The user pulls to refresh, or the app automatically requests a background refresh of the latest 50 activities.

```mermaid
sequenceDiagram
    participant App
    participant Backend (syncActivities)
    participant Strava API
    participant Firestore
    participant App (docChanges)
    participant SQLite (Local DB)

    App->>Backend (syncActivities): Trigger Manual Sync
    Backend (syncActivities)->>Strava API: Fetch last 50 activities
    Strava API-->>Backend (syncActivities): Return 50 activities
    Backend (syncActivities)->>Firestore: Update the latest Batch doc
    Firestore-->>App (docChanges): Type: MODIFIED (1 Batch)
    
    App (docChanges)->>App (docChanges): Parse Batch (max 500 items)
    App (docChanges)->>SQLite (Local DB): Transaction: Upsert fresh data
    SQLite (Local DB)-->>App (docChanges): Done
```

## Case 3: Weekly Full Sync (The Hard Reset)

The backend decides to do a massive full history sync. It wipes all existing batches and repopulates everything.
Because the app handles `Type: REMOVED` events gracefully, your local SQLite cache is perfectly mirrored without manual migrations.

```mermaid
sequenceDiagram
    participant Backend (syncFullHistory)
    participant Strava API
    participant Firestore
    participant App (docChanges)
    participant SQLite (Local DB)

    Note over Backend (syncFullHistory), Firestore: PHASE 1: WIPE OLD CACHE
    Backend (syncFullHistory)->>Firestore: Delete all 20 legacy Batches
    Firestore-->>App (docChanges): Type: REMOVED (20 Batches)
    App (docChanges)->>App (docChanges): Extract 10,000 IDs from deleted data
    App (docChanges)->>SQLite (Local DB): Transaction: Delete 10,000 IDs
    
    Note over Backend (syncFullHistory), Firestore: PHASE 2: REPOPULATE
    Backend (syncFullHistory)->>Strava API: Paginate all history...
    Strava API-->>Backend (syncFullHistory): Return 10,000 activities
    Backend (syncFullHistory)->>Firestore: Write 20 new Batches
    Firestore-->>App (docChanges): Type: ADDED (20 Batches)
    
    App (docChanges)->>SQLite (Local DB): Transaction: Upsert 10,000 fresh items
    Note over SQLite (Local DB): The App DB is now perfectly clean and synchronized!
```
