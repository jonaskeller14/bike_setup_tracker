import 'dart:async';

import 'package:bike_setup_tracker/services/account_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeIdTokenResult extends Fake implements IdTokenResult {
  @override
  final Map<String, dynamic>? claims;

  _FakeIdTokenResult(this.claims);
}

class _FakeUser extends Fake implements User {
  @override
  final String uid;
  final String? deviceIdClaim;

  _FakeUser(this.uid, {this.deviceIdClaim});

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async =>
      _FakeIdTokenResult({'deviceId': ?deviceIdClaim});
}

class _FakeCredential extends Fake implements UserCredential {
  @override
  final User? user;

  _FakeCredential(this.user);
}

/// Firebase Auth with one current user. A custom token is `uid:deviceId`.
class _FakeAuth extends Fake implements FirebaseAuth {
  final List<String> log;
  final _changes = StreamController<User?>.broadcast();
  User? _current;
  int _anonymousCount = 0;

  _FakeAuth(this.log, [this._current]);

  @override
  User? get currentUser => _current;

  @override
  Stream<User?> authStateChanges() async* {
    yield _current;
    yield* _changes.stream;
  }

  void _set(User? user) {
    _current = user;
    _changes.add(user);
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    _set(_FakeUser('anon-${++_anonymousCount}'));
    log.add('anonymous:${_current!.uid}');
    return _FakeCredential(_current);
  }

  @override
  Future<UserCredential> signInWithCustomToken(String token) async {
    final [uid, deviceId] = token.split(':');
    _set(_FakeUser(uid, deviceIdClaim: deviceId));
    log.add('signIn:$uid');
    return _FakeCredential(_current);
  }

  @override
  Future<void> signOut() async {
    log.add('signOut');
    _set(null);
  }

  /// Firebase signing out by itself, as after the user was deleted.
  void dropUser() => _set(null);
}

class _FakeApi implements AccountApi {
  final List<String> log;
  final starts = <String>[];
  final revokes = <String?>[];
  AccountSessionResult? Function(String deviceId) onStart = (_) => null;
  Future<AccountSessionResult?> Function(String deviceId)? onStartAsync;
  Exception? revokeError;

  _FakeApi(this.log);

  @override
  Future<AccountSessionResult?> startSession({
    required String deviceId,
    required String platform,
    String? deviceName,
  }) async {
    starts.add(deviceId);
    log.add('start');
    return onStartAsync?.call(deviceId) ?? onStart(deviceId);
  }

  /// The server calls and the end of the devices listener, in order.
  final calls = <String>[];

  @override
  Future<void> revokeSession([String? deviceId]) async {
    revokes.add(deviceId);
    calls.add('revoke');
    if (revokeError case final error?) throw error;
  }

  @override
  Future<AccountDeletionResult> deleteAccount() async {
    calls.add('delete');
    return (subscriptionRenews: false, platform: null);
  }

  @override
  Stream<List<AccountDevice>> watchDevices(String uid) {
    late final StreamController<List<AccountDevice>> controller;
    controller = StreamController(
      onListen: () => controller.add(const [
        AccountDevice(deviceId: 'd1', platform: 'android', deviceName: 'Pixel 8', lastSeenAt: null),
      ]),
      onCancel: () {
        calls.add('devices:cancel');
        return controller.close();
      },
    );
    return controller.stream;
  }
}

/// Stands in for the Strava and subscription services.
class _FakeBoundService implements UserBoundService {
  final List<String> log;
  final String? name;
  void Function(String uid)? onBind;

  _FakeBoundService(this.log, {this.name});

  String get _prefix => name == null ? '' : '$name:';

  @override
  Future<void> unbindUser() async => log.add('${_prefix}unbind');

  @override
  Future<void> bindUser(String uid) async {
    log.add('${_prefix}bind:$uid');
    onBind?.call(uid);
  }
}

FirebaseFunctionsException _revoked() => FirebaseFunctionsException(
  message: 'This device was signed out of the account.',
  code: 'unauthenticated',
  details: const {'reason': 'session-revoked'},
);

void main() {
  late List<String> log;
  late List<bool> clears;
  late _FakeApi api;
  late _FakeAuth auth;
  late _FakeBoundService bound;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    log = [];
    clears = [];
    api = _FakeApi(log);
    bound = _FakeBoundService(log);
  });

  AccountService create({User? user}) {
    auth = _FakeAuth(log, user);
    return AccountService(
      auth: auth,
      api: api,
      describeDevice: () async => (platform: 'android', name: 'Pixel 8'),
      clearLocalData: ({required removeData}) async => clears.add(removeData),
    )..attach(bound);
  }

  /// A device whose token already carries the claim of its account session.
  Future<AccountService> onAccount(String uid, {bool cloudSync = false}) async {
    final deviceId = await create().ensureDeviceId();
    SharedPreferences.setMockInitialValues({'account.deviceId': deviceId, 'account.uid': uid});
    final service = create(user: _FakeUser(uid, deviceIdClaim: deviceId));
    await service.initialize(enableAccounts: true, enableCloudSync: cloudSync);
    log.clear();
    api.starts.clear();
    return service;
  }

  group('startSession', () {
    test('does nothing while accounts are off', () async {
      final service = create(user: _FakeUser('c1'));
      await service.initialize(enableAccounts: false, enableCloudSync: false);

      await service.startSession(athleteId: 'a1');

      expect(api.starts, isEmpty);
      expect(log, isEmpty);
    });

    test('a device not linked to Strava stays on its anonymous uid', () async {
      final service = create(user: _FakeUser('c1'));
      await service.initialize(enableAccounts: true, enableCloudSync: false);

      await service.startSession(athleteId: 'a1');

      expect(api.starts, hasLength(1));
      expect(service.uid, 'c1');
      expect(service.isOnAccount, isFalse);
      expect(log, ['unbind', 'start', 'bind:c1']);
    });

    test('the first device signs in again to its own uid, now with the claim', () async {
      final service = create(user: _FakeUser('c1'));
      await service.initialize(enableAccounts: true, enableCloudSync: false);
      api.onStart = (deviceId) => (uid: 'c1', token: 'c1:$deviceId');

      await service.startSession(athleteId: 'a1');

      expect(service.uid, 'c1');
      expect(service.isOnAccount, isTrue);
      expect(log, ['unbind', 'start', 'signIn:c1', 'bind:c1']);
    });

    test('a second device switches to the account uid and the services rebind after the switch', () async {
      final service = create(user: _FakeUser('c2'));
      await service.initialize(enableAccounts: true, enableCloudSync: false);
      api.onStart = (deviceId) => (uid: 'o1', token: 'o1:$deviceId');

      await service.startSession(athleteId: 'a1');

      expect(service.uid, 'o1');
      expect(service.isOnAccount, isTrue);
      expect(log, ['unbind', 'start', 'signIn:o1', 'bind:o1']);
    });

    test('a service bound while the uid switches binds the new uid, never the old one', () async {
      final service = create(user: _FakeUser('c2'));
      await service.initialize(enableAccounts: true, enableCloudSync: false);
      final call = Completer<AccountSessionResult?>();
      api.onStartAsync = (_) => call.future;
      final joining = _FakeBoundService(log, name: 'late');

      final switching = service.startSession(athleteId: 'a1');
      await pumpEventQueue();
      final binding = service.bind(joining);
      await pumpEventQueue();
      call.complete((uid: 'o1', token: 'o1:${service.deviceId}'));
      await Future.wait([switching, binding]);

      expect(log, ['unbind', 'start', 'signIn:o1', 'bind:o1', 'late:bind:o1']);
    });

    test('a start without an account is not repeated by the rebind it causes', () async {
      final service = create(user: _FakeUser('c1'));
      await service.initialize(enableAccounts: true, enableCloudSync: false);
      // Like StravaService, whose user listener asks again after a rebind.
      bound.onBind = (_) => unawaited(service.startSession(athleteId: 'a1'));

      await service.startSession(athleteId: 'a1');
      await pumpEventQueue();

      expect(api.starts, hasLength(1));
    });

    test('repeated app starts reuse the device id and its session', () async {
      final first = create();
      final deviceId = await first.ensureDeviceId();

      final service = await onAccount('o1');
      await service.recheckSession();
      await service.startSession(athleteId: 'a1');

      expect(service.deviceId, deviceId);
      expect(api.starts, [deviceId]);
      expect(log, ['start'], reason: 'no sign-in and no rebind on an account session');
    });

    test('the claim in the token wins over lost preferences', () async {
      final service = create(user: _FakeUser('o1', deviceIdClaim: 'old-device'));

      await service.initialize(enableAccounts: true, enableCloudSync: false);

      expect(service.isOnAccount, isTrue);
      expect(service.deviceId, 'old-device');
      expect(api.starts, ['old-device']);
    });
  });

  group('revoked or deleted account', () {
    test('a revoked session without cloud sync signs the device out and keeps its data', () async {
      final service = await onAccount('o1');
      api.onStart = (_) => throw _revoked();

      await service.recheckSession();
      await pumpEventQueue();

      expect(service.isOnAccount, isFalse);
      expect(service.uid, 'anon-1');
      expect(clears, [false]);
      expect(service.takeNotice(), AccountNotice.sessionRevokedDataKept);
      expect(service.takeNotice(), isNull);
      expect(log, ['start', 'unbind', 'signOut', 'anonymous:anon-1', 'bind:anon-1']);
    });

    test('a revoked session with cloud sync removes the data, which the cloud still has', () async {
      final service = await onAccount('o1', cloudSync: true);
      api.onStart = (_) => throw _revoked();

      await service.recheckSession();
      await pumpEventQueue();

      expect(service.isOnAccount, isFalse);
      expect(clears, [true]);
      expect(service.takeNotice(), AccountNotice.sessionRevoked);
    });

    test('a revoked-session error from another callable is handled the same way', () async {
      final service = await onAccount('o1', cloudSync: true);

      expect(service.handleSessionRevoked(_revoked()), isTrue);
      expect(service.handleSessionRevoked(FirebaseFunctionsException(message: '', code: 'unauthenticated')), isFalse);
      await pumpEventQueue();

      expect(service.isOnAccount, isFalse);
      expect(clears, [true]);
    });

    test('an account deleted on another device signs this one out and keeps its data', () async {
      final service = await onAccount('o1', cloudSync: true);

      auth.dropUser();
      await pumpEventQueue();

      expect(service.isOnAccount, isFalse);
      expect(service.uid, 'anon-1');
      expect(clears, [false]);
      expect(service.takeNotice(), AccountNotice.accountDeleted);
    });
  });

  group('signOut', () {
    for (final removeData in [true, false]) {
      test('revokes this session and ${removeData ? 'removes' : 'keeps'} the data', () async {
        final service = await onAccount('o1');

        await service.signOut(removeData: removeData);

        expect(api.revokes, [null]);
        expect(clears, [removeData]);
        expect(service.uid, 'anon-1');
        expect(service.isOnAccount, isFalse);
        expect(service.takeNotice(), isNull);
        expect(log, ['unbind', 'signOut', 'anonymous:anon-1', 'bind:anon-1']);
      });
    }

    test('stays signed in when the session could not be revoked', () async {
      final service = await onAccount('o1');
      api.revokeError = FirebaseFunctionsException(message: 'offline', code: 'unavailable');

      await expectLater(service.signOut(removeData: true), throwsA(isA<FirebaseFunctionsException>()));

      expect(service.uid, 'o1');
      expect(service.isOnAccount, isTrue);
      expect(clears, isEmpty);
    });

    test('an already revoked session still signs out locally', () async {
      final service = await onAccount('o1');
      api.revokeError = _revoked();

      await service.signOut(removeData: false);

      expect(service.isOnAccount, isFalse);
      expect(clears, [false]);
    });
  });

  group('watchDevices', () {
    Future<(List<List<AccountDevice>>, Future<void>)> listen(AccountService service) async {
      final received = <List<AccountDevice>>[];
      final done = service.watchDevices().listen(received.add).asFuture<void>();
      await pumpEventQueue();
      expect(received, hasLength(1));
      return (received, done);
    }

    test('ends before signing out revokes this session', () async {
      final service = await onAccount('o1');
      final (received, done) = await listen(service);

      await service.signOut(removeData: true);

      await done;
      expect(api.calls, ['devices:cancel', 'revoke']);
      expect(received, hasLength(1));
    });

    test('ends before the account is deleted', () async {
      final service = await onAccount('o1');
      final (_, done) = await listen(service);

      await service.deleteAccount(removeData: false);

      await done;
      expect(api.calls, ['devices:cancel', 'delete']);
    });

    test('ends before a revoked session signs the device out', () async {
      final service = await onAccount('o1');
      final (_, done) = await listen(service);

      expect(service.handleSessionRevoked(_revoked()), isTrue);

      await done;
      expect(api.calls, ['devices:cancel']);
      expect(log.indexOf('signOut'), greaterThan(-1));
    });

    test('keeps listening while another device is signed out', () async {
      final service = await onAccount('o1');
      var ended = false;
      service.watchDevices().listen((_) {}, onDone: () => ended = true);
      await pumpEventQueue();

      await service.revokeDevice('d2');
      await pumpEventQueue();

      expect(ended, isFalse);
      expect(api.calls, ['revoke']);
    });
  });
}
