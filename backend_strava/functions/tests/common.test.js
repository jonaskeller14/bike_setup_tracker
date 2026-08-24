const {
  isBikeActivity,
  hasActiveStravaEntitlement,
  googlePlayBillingPhase,
  appStoreBillingPhase,
} = require('../common');

// Mock Firebase Admin so the tests run locally and instantly
// without needing a real database or internet connection.
jest.mock('firebase-admin', () => ({
  firestore: {
    FieldValue: {
      serverTimestamp: jest.fn(() => 'MOCK_TIMESTAMP'),
      arrayUnion: jest.fn(val => val)
    },
    Timestamp: {
      now: jest.fn(() => 'MOCK_NOW'),
      fromDate: jest.fn(() => 'MOCK_DATE')
    }
  }
}));

jest.mock('../firebase', () => {
  // We mock the db behavior used inside saveActivityToBatch
  const mockUpdate = jest.fn();
  const mockSet = jest.fn();
  
  const mockDoc = {
    ref: { update: mockUpdate, set: mockSet },
    data: () => ({ activityIds: [] }),
    id: "batch_001"
  };

  const mockQuery = {
    empty: false,
    docs: [mockDoc]
  };

  // Mock a chainable Firestore collection reference
  const mockDb = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnValue({
      get: jest.fn().mockResolvedValue(mockQuery)
    })
  };

  return {
    db: mockDb,
    admin: require('firebase-admin')
  };
});

describe('Strava entitlement evaluation', () => {
  const now = Date.parse('2026-08-21T12:00:00Z');

  it('rejects missing and malformed entitlements', () => {
    expect(hasActiveStravaEntitlement(null, now)).toBe(false);
    expect(hasActiveStravaEntitlement({ expiresAt: 'invalid' }, now)).toBe(false);
  });

  it('accepts paid and trial entitlements before expiry', () => {
    const expiresAt = new Date(now + 60_000).toISOString();
    expect(hasActiveStravaEntitlement({ expiresAt, autoRenewing: true }, now)).toBe(true);
    expect(hasActiveStravaEntitlement({ expiresAt, autoRenewing: false }, now)).toBe(true);
  });

  it('keeps canceled access only until expiry', () => {
    const expiresAt = new Date(now - 1).toISOString();
    expect(hasActiveStravaEntitlement({ expiresAt, autoRenewing: false }, now)).toBe(false);
  });

  it('allows a short renewal webhook buffer only when auto-renewing', () => {
    const recentlyExpired = new Date(now - 60_000).toISOString();
    const longExpired = new Date(now - 5 * 60 * 60 * 1000).toISOString();
    expect(hasActiveStravaEntitlement({ expiresAt: recentlyExpired, autoRenewing: true }, now)).toBe(true);
    expect(hasActiveStravaEntitlement({ expiresAt: longExpired, autoRenewing: true }, now)).toBe(false);
  });

  it('supports Firestore Timestamp-like values', () => {
    const expiresAt = { toMillis: () => now + 60_000 };
    expect(hasActiveStravaEntitlement({ expiresAt, autoRenewing: false }, now)).toBe(true);
  });
});

describe('store billing phase derivation', () => {
  it('derives Google Play free-trial phases', () => {
    expect(googlePlayBillingPhase({ offerPhase: { freeTrial: {} } })).toBe('trial');
    expect(googlePlayBillingPhase({ offerPhase: 'FREE_TRIAL' })).toBe('trial');
    expect(googlePlayBillingPhase({ offerDetails: { offerTags: ['strava-trial-7d'] } })).toBe('standard');
  });

  it('derives App Store introductory phases', () => {
    expect(appStoreBillingPhase({ offerType: 1 })).toBe('trial');
    expect(appStoreBillingPhase({ offerDiscountType: 'FREE_TRIAL' })).toBe('trial');
    expect(appStoreBillingPhase({ offerType: 2 })).toBe('standard');
  });
});

// Require our common module AFTER mocking firebase
const { db } = require('../firebase');
const { saveActivityToBatch } = require('../common');

describe('Strava Sync Logic', () => {
  let mockUpdate;

  beforeEach(() => {
    // Clear mock history before each test
    jest.clearAllMocks();
    
    // Get the mockUpdate function we created above
    // to check what was written to the DB
    mockUpdate = jest.fn();
    
    // Reset our mock query setup to return a batch
    db.collection().limit().get.mockResolvedValue({
      empty: false,
      docs: [{
        ref: { update: mockUpdate },
        data: () => ({ activityIds: [123] }),
        id: "batch_001"
      }]
    });
  });

  it('correctly identifies bike activities', () => {
    expect(isBikeActivity({ type: 'Ride' })).toBe(true);
    expect(isBikeActivity({ type: 'MountainBikeRide' })).toBe(true);
    expect(isBikeActivity({ type: 'EBikeRide' })).toBe(true);
    expect(isBikeActivity({ type: 'Run' })).toBe(false);
  });

  it('generates a Tombstone block when an activity is deleted', async () => {
    const deletedActivity = { id: 123, isDeleted: true };
    await saveActivityToBatch(deletedActivity, "user_unit_test");

    // Check if db.update was called on the batch document
    expect(mockUpdate).toHaveBeenCalled();
    
    // Inspect the exact object that was sent to Firestore
    const updatePayload = mockUpdate.mock.calls[0][0];

    // The activity field should contain the tombstone pattern
    expect(updatePayload['activities.123']).toEqual({
      id: 123,
      isDeleted: true,
      lastModified: 'MOCK_TIMESTAMP'
    });
  });

  it('generates a Tombstone block when a bike activity is changed to a Run', async () => {
    // A user recorded a run, but Strava synced it before. Now it's a "Run" type
    const changedActivity = { id: 123, type: 'Run' }; 
    await saveActivityToBatch(changedActivity, "user_unit_test");

    expect(mockUpdate).toHaveBeenCalled();
    const updatePayload = mockUpdate.mock.calls[0][0];

    // Even though the webhook said "Update", it's a Run, so we tombstone it
    expect(updatePayload['activities.123']).toEqual({
      id: 123,
      isDeleted: true,
      lastModified: 'MOCK_TIMESTAMP'
    });
  });

  it('generates a valid data block for a normal bike activity update', async () => {
    const normalActivity = {
      id: 456,
      type: 'Ride',
      name: 'Morning Commute',
      start_date: '2023-01-01T10:00:00Z',
      distance: 15000
    };
    
    // Modify mock to simulate looking up activity 456
    db.collection().limit().get.mockResolvedValue({
      empty: false,
      docs: [{
        ref: { update: mockUpdate },
        data: () => ({ activityIds: [456] }),
        id: "batch_002"
      }]
    });

    await saveActivityToBatch(normalActivity, "user_unit_test");

    expect(mockUpdate).toHaveBeenCalled();
    const updatePayload = mockUpdate.mock.calls[0][0];

    // It should NOT be a tombstone
    expect(updatePayload['activities.456'].isDeleted).toBeUndefined();
    expect(updatePayload['activities.456'].name).toBe('Morning Commute');
  });
});
