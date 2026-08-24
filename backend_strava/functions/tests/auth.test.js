const mockGetUser = jest.fn();
const mockRunTransaction = jest.fn();
const mockDoc = jest.fn();

jest.mock('firebase-functions/v2/https', () => ({
  onCall: jest.fn((_options, handler) => handler),
  onRequest: jest.fn((_options, handler) => handler),
  HttpsError: class HttpsError extends Error {},
}));

jest.mock('../firebase', () => ({
  db: {
    collection: jest.fn(() => ({ doc: mockDoc })),
    runTransaction: mockRunTransaction,
  },
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
  admin: { auth: () => ({ getUser: mockGetUser }) },
}));

jest.mock('../sync', () => ({
  syncFullHistory: jest.fn(),
  syncRecent: jest.fn(),
}));

jest.mock('../common', () => ({
  requireActiveStravaEntitlement: jest.fn(),
  userHasActiveStravaEntitlement: jest.fn(),
}));

const { resolveOAuthUserId } = require('../auth');

const now = Date.parse('2026-08-24T12:00:00Z');

function configureState(snapshot) {
  const stateRef = { id: 'state' };
  mockDoc.mockReturnValue(stateRef);
  mockRunTransaction.mockImplementation(async (callback) => callback({
    get: jest.fn().mockResolvedValue(snapshot),
    delete: jest.fn(),
  }));
}

describe('resolveOAuthUserId', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('uses and consumes a valid server-created state', async () => {
    configureState({
      exists: true,
      data: () => ({
        userId: 'new-user',
        expiresAt: { toMillis: () => now + 60_000 },
      }),
    });

    await expect(resolveOAuthUserId('secure-state', now)).resolves.toEqual({
      userId: 'new-user',
      isLegacy: false,
    });
    expect(mockGetUser).not.toHaveBeenCalled();
  });

  it('does not retain a user ID from an aborted transaction attempt', async () => {
    const stateRef = { id: 'state' };
    mockDoc.mockReturnValue(stateRef);
    mockRunTransaction.mockImplementation(async (callback) => {
      await callback({
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            userId: 'new-user',
            expiresAt: { toMillis: () => now + 60_000 },
          }),
        }),
        delete: jest.fn(),
      });
      return callback({
        get: jest.fn().mockResolvedValue({
          exists: false,
          data: () => undefined,
        }),
        delete: jest.fn(),
      });
    });

    await expect(resolveOAuthUserId('secure-state', now)).resolves.toBeNull();
    expect(mockGetUser).not.toHaveBeenCalled();
  });

  it('temporarily accepts a valid legacy Firebase UID when no state record exists', async () => {
    configureState({ exists: false, data: () => undefined });
    const legacyUid = 'a'.repeat(28);
    mockGetUser.mockResolvedValue({ uid: legacyUid });

    await expect(resolveOAuthUserId(legacyUid, now)).resolves.toEqual({
      userId: legacyUid,
      isLegacy: true,
    });
    expect(mockGetUser).toHaveBeenCalledWith(legacyUid);
  });

  it('rejects legacy states after the migration deadline', async () => {
    configureState({ exists: false, data: () => undefined });
    const legacyUid = 'a'.repeat(28);

    await expect(resolveOAuthUserId(legacyUid, Date.parse('2026-11-01T00:00:00Z')))
      .resolves.toBeNull();
    expect(mockGetUser).not.toHaveBeenCalled();
  });

  it('does not fall back when a server-created state is expired', async () => {
    configureState({
      exists: true,
      data: () => ({
        userId: 'new-user',
        expiresAt: { toMillis: () => now - 1 },
      }),
    });

    await expect(resolveOAuthUserId('a'.repeat(28), now)).resolves.toBeNull();
    expect(mockGetUser).not.toHaveBeenCalled();
  });
});
