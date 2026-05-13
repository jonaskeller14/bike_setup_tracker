/**
 * Tests for orphan_cleanup.js
 *
 * Strategy: capture the handler passed to onDocumentWritten, then call it
 * directly with synthetic Firestore event objects. All external I/O is
 * mocked so the tests run locally without Firebase or the internet.
 */

// ── Stable collection-level mock refs (created once, configured per-test) ─────
const mockUsersWhere = jest.fn();
const mockAthleteOauthGet = jest.fn();
const mockAthleteOauthDelete = jest.fn();
const mockRecursiveDelete = jest.fn();

// ── firebase-admin ─────────────────────────────────────────────────────────────
jest.mock('firebase-admin', () => ({
  firestore: {
    FieldValue: {
      serverTimestamp: jest.fn(() => 'MOCK_TIMESTAMP'),
      arrayRemove: jest.fn((v) => ({ _type: 'arrayRemove', value: v })),
    },
    Timestamp: { now: jest.fn(), fromDate: jest.fn() },
  },
}));

// ── firebase module ────────────────────────────────────────────────────────────
jest.mock('../firebase', () => {
  const admin = require('firebase-admin');

  // Return the stable mock refs so tests can assert on them directly.
  const db = {
    collection: jest.fn((name) => {
      switch (name) {
        case 'users':
          return { where: mockUsersWhere };
        case 'athletes':
          return { doc: jest.fn(() => ({ /* athleteRef placeholder */ })) };
        case 'athlete_oauth':
          return {
            doc: jest.fn(() => ({
              get: mockAthleteOauthGet,
              delete: mockAthleteOauthDelete,
            })),
          };
        default:
          return {};
      }
    }),
    recursiveDelete: mockRecursiveDelete,
  };

  return {
    db,
    admin,
    logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
  };
});

// ── firebase-functions: capture the registered handler ────────────────────────
let capturedHandler;
jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentWritten: jest.fn((_config, handler) => {
    capturedHandler = handler;
    return handler;
  }),
}));

// Load the module under test — this triggers onDocumentWritten registration.
require('../orphan_cleanup');

// ── Helpers ────────────────────────────────────────────────────────────────────

/** Stub the users-collection `where` chain to return empty (athlete is orphaned). */
function stubAthleteIsOrphaned() {
  mockUsersWhere.mockReturnValue({
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnValue({
      get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
    }),
  });
}

/** Stub the users-collection `where` chain to return a matching user (still linked). */
function stubAthleteIsStillLinked() {
  mockUsersWhere.mockReturnValue({
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnValue({
      get: jest.fn().mockResolvedValue({ empty: false, docs: [{ id: 'other_uid' }] }),
    }),
  });
}

function stubOauthExists(accessToken = 'tok_abc') {
  mockAthleteOauthGet.mockResolvedValue({
    exists: true,
    data: () => ({ access_token: accessToken }),
  });
  mockAthleteOauthDelete.mockResolvedValue(undefined);
}

function stubOauthMissing() {
  mockAthleteOauthGet.mockResolvedValue({ exists: false });
  mockAthleteOauthDelete.mockResolvedValue(undefined);
}

function makeEvent({ beforeAthletes = [], afterAthletes = [] } = {}) {
  return {
    params: { userId: 'uid_test' },
    data: {
      before: { data: () => ({ linked_athletes: beforeAthletes }) },
      after: afterAthletes !== null
        ? { data: () => ({ linked_athletes: afterAthletes }) }
        : null,
    },
  };
}

// ── Tests ──────────────────────────────────────────────────────────────────────

describe('cleanupOrphanedAthletes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    global.fetch = jest.fn().mockResolvedValue({ ok: true });
  });

  // ── No change: nothing to do ─────────────────────────────────────────────────

  it('does nothing when linked_athletes is unchanged', async () => {
    const event = makeEvent({
      beforeAthletes: ['athlete_1'],
      afterAthletes: ['athlete_1'],
    });
    await capturedHandler(event);

    expect(mockUsersWhere).not.toHaveBeenCalled();
    expect(mockRecursiveDelete).not.toHaveBeenCalled();
    expect(global.fetch).not.toHaveBeenCalled();
  });

  it('does nothing when no athletes were ever linked', async () => {
    await capturedHandler(makeEvent());
    expect(mockRecursiveDelete).not.toHaveBeenCalled();
  });

  it('does nothing when an athlete is added (not removed)', async () => {
    const event = makeEvent({ beforeAthletes: [], afterAthletes: ['athlete_new'] });
    await capturedHandler(event);
    expect(mockRecursiveDelete).not.toHaveBeenCalled();
  });

  // ── Purge when truly orphaned ────────────────────────────────────────────────

  it('purges athlete when removed and no other user links it', async () => {
    stubAthleteIsOrphaned();
    stubOauthExists('access_token_xyz');

    await capturedHandler(makeEvent({
      beforeAthletes: ['athlete_orphan'],
      afterAthletes: [],
    }));

    // Queries users for remaining links
    expect(mockUsersWhere).toHaveBeenCalledWith(
      'linked_athletes', 'array-contains', 'athlete_orphan'
    );

    // Calls Strava deauthorize with the access token
    expect(global.fetch).toHaveBeenCalledWith(
      'https://www.strava.com/oauth/deauthorize',
      expect.objectContaining({ method: 'POST' })
    );
    const body = JSON.parse(global.fetch.mock.calls[0][1].body);
    expect(body.access_token).toBe('access_token_xyz');

    // Deletes the OAuth doc and the athlete subtree
    expect(mockAthleteOauthDelete).toHaveBeenCalled();
    expect(mockRecursiveDelete).toHaveBeenCalled();
  });

  it('purges athlete data even when OAuth doc is missing (no Strava deauth call)', async () => {
    stubAthleteIsOrphaned();
    stubOauthMissing();

    await capturedHandler(makeEvent({
      beforeAthletes: ['athlete_no_oauth'],
      afterAthletes: [],
    }));

    // No Strava call — nothing to revoke
    expect(global.fetch).not.toHaveBeenCalled();
    // Athlete data is still deleted
    expect(mockRecursiveDelete).toHaveBeenCalled();
  });

  // ── Skip when another user still links ──────────────────────────────────────

  it('does NOT purge when another device still links the same athlete', async () => {
    stubAthleteIsStillLinked();

    await capturedHandler(makeEvent({
      beforeAthletes: ['athlete_shared'],
      afterAthletes: [],
    }));

    // Checked for other links
    expect(mockUsersWhere).toHaveBeenCalledWith(
      'linked_athletes', 'array-contains', 'athlete_shared'
    );

    // No purge
    expect(global.fetch).not.toHaveBeenCalled();
    expect(mockRecursiveDelete).not.toHaveBeenCalled();
  });

  // ── Multiple athletes removed at once ────────────────────────────────────────

  it('processes each removed athlete independently — orphan purged, linked skipped', async () => {
    let callCount = 0;
    mockUsersWhere.mockImplementation(() => ({
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnValue({
        get: jest.fn().mockImplementation(() => {
          callCount++;
          // First call (athlete_a): orphaned
          if (callCount === 1) return Promise.resolve({ empty: true, docs: [] });
          // Second call (athlete_b): still linked
          return Promise.resolve({ empty: false, docs: [{ id: 'uid_other' }] });
        }),
      }),
    }));
    stubOauthExists();

    await capturedHandler(makeEvent({
      beforeAthletes: ['athlete_a', 'athlete_b'],
      afterAthletes: [],
    }));

    // Only one purge — for athlete_a
    expect(mockRecursiveDelete).toHaveBeenCalledTimes(1);
  });

  // ── User doc deleted (after = null) ──────────────────────────────────────────

  it('treats user doc deletion as removing all previously linked athletes', async () => {
    stubAthleteIsOrphaned();
    stubOauthExists();

    const event = {
      params: { userId: 'uid_deleted' },
      data: {
        before: { data: () => ({ linked_athletes: ['athlete_x'] }) },
        after: null, // doc was deleted
      },
    };
    await capturedHandler(event);

    expect(mockRecursiveDelete).toHaveBeenCalled();
  });

  // ── Strava deauth failure is non-fatal ───────────────────────────────────────

  it('still deletes athlete data even if Strava deauth call throws', async () => {
    stubAthleteIsOrphaned();
    stubOauthExists('tok_fail');
    global.fetch = jest.fn().mockRejectedValue(new Error('network timeout'));

    await expect(
      capturedHandler(makeEvent({
        beforeAthletes: ['athlete_deauth_fail'],
        afterAthletes: [],
      }))
    ).resolves.not.toThrow();

    // Athlete data still deleted despite fetch failure
    expect(mockRecursiveDelete).toHaveBeenCalled();
  });
});
