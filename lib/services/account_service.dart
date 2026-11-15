import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'error_reporter.dart';

/// A service with Firestore listeners on the signed-in user's documents.
/// [AccountService] unbinds it before the uid changes, so no listener is cut
/// off with `permission-denied` halfway through a switch, and binds it to the
/// new uid afterwards.
abstract interface class UserBoundService {
  Future<void> unbindUser();

  Future<void> bindUser(String uid);
}

/// Why this device was signed out without the user asking.
enum AccountNotice { sessionRevoked, sessionRevokedDataKept, accountDeleted }

typedef DeviceDescription = ({String platform, String? name});

typedef AccountSessionResult = ({String uid, String? token});

typedef AccountDeletionResult = ({bool subscriptionRenews, String? platform});

/// One signed-in device of the account (`users/{uid}/sessions/{deviceId}`).
@immutable
class AccountDevice {
  final String deviceId;
  final String platform;
  final String deviceName;
  final DateTime? lastSeenAt;

  const AccountDevice({
    required this.deviceId,
    required this.platform,
    required this.deviceName,
    required this.lastSeenAt,
  });

  factory AccountDevice.fromFirestore(String id, Map<String, dynamic> data) => AccountDevice(
    deviceId: id,
    platform: data['platform'] as String? ?? '',
    deviceName: data['deviceName'] as String? ?? '',
    lastSeenAt: (data['lastSeenAt'] as Timestamp?)?.toDate(),
  );
}

/// The account Cloud Functions (`functions/src/accounts/triggers.js` in the
/// backend repo) and the account's session docs.
class AccountApi {
  const AccountApi();

  HttpsCallable _callable(String name) => FirebaseFunctions.instanceFor(region: 'europe-west3').httpsCallable(name);

  /// Null while the caller isn't linked to Strava. Otherwise the account uid
  /// and a custom token to sign in with, or `token: null` when the caller
  /// already holds this device's session.
  Future<AccountSessionResult?> startSession({
    required String deviceId,
    required String platform,
    String? deviceName,
  }) async {
    final result = await _callable('startAccountSession').call<Map<String, dynamic>>({
      'deviceId': deviceId,
      'platform': platform,
      'deviceName': ?deviceName,
    });
    final account = result.data['account'];
    if (account is! Map) return null;
    return (uid: account['uid'] as String, token: account['token'] as String?);
  }

  /// Signs [deviceId] out of the account, or this device when it's null.
  Future<void> revokeSession([String? deviceId]) =>
      _callable('revokeAccountSession').call<void>({'deviceId': ?deviceId});

  Future<AccountDeletionResult> deleteAccount() async {
    final result = await _callable(
      'deleteAccount',
    ).call<Map<String, dynamic>>();
    return (
      subscriptionRenews: result.data['subscriptionRenews'] == true,
      platform: result.data['platform'] as String?,
    );
  }

  Stream<List<AccountDevice>> watchDevices(String uid) => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('sessions')
      .orderBy('lastSeenAt', descending: true)
      .snapshots()
      .map((snapshot) => [for (final doc in snapshot.docs) AccountDevice.fromFirestore(doc.id, doc.data())]);
}

/// Owns the Firebase uid. A device starts on its own anonymous uid and moves
/// into its person's account (one uid per person) when it connects Strava:
/// `startAccountSession` returns a custom token for the account uid that
/// carries this device's `deviceId` claim. The claim names the device's
/// server-side session, so each device signs in and out on its own.
class AccountService extends ChangeNotifier {
  static const String _deviceIdKey = 'account.deviceId';
  static const String _accountUidKey = 'account.uid';

  final FirebaseAuth? _authOverride;
  final AccountApi _api;
  final Future<DeviceDescription> Function() _describeDevice;
  final Future<void> Function({required bool removeData}) _clearLocalData;

  AccountService({
    FirebaseAuth? auth,
    this._api = const AccountApi(),
    Future<DeviceDescription> Function()? describeDevice,
    required this._clearLocalData,
  }) : _authOverride = auth,
       _describeDevice = describeDevice ?? describeThisDevice;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  final List<UserBoundService> _bound = [];
  SharedPreferences? _prefs;
  String? _deviceId;
  String? _accountUid;
  bool _enabled = false;
  bool _cloudSync = false;
  bool _isDisposed = false;
  Future<String?>? _signIn;
  Future<void>? _sessionRun;
  Future<void>? _signOutRun;
  // Binds and uid switches run one after another (see [bind]).
  Future<void> _serial = Future.value();
  String? _verifiedUid;
  // A start that didn't produce an account rebinds the services, whose user
  // listener asks again: one attempt per uid and athlete per app run.
  final Set<String> _joinAttempts = {};
  bool _switching = false;
  StreamSubscription<User?>? _authSub;
  AccountNotice? _notice;
  final Map<StreamController<List<AccountDevice>>, Future<void> Function()> _deviceWatches = {};

  String? get uid => _auth.currentUser?.uid;
  String? get deviceId => _deviceId;
  bool get isOnAccount => _accountUid != null && _accountUid == uid;

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_authSub?.cancel());
    super.dispose();
  }

  void attach(UserBoundService service) {
    if (!_bound.contains(service)) _bound.add(service);
  }

  /// Attaches [service] and binds it to the signed-in uid. Runs after a uid
  /// switch in progress, so the service never binds the uid it replaced.
  Future<void> bind(UserBoundService service) => _serialized(() async {
    attach(service);
    final uid = await ensureSignedIn();
    if (uid != null) await service.bindUser(uid);
  });

  Future<T> _serialized<T>(Future<T> Function() action) {
    final run = _serial.then((_) => action());
    _serial = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  /// Returns the notice of the last unrequested sign-out once.
  AccountNotice? takeNotice() {
    final notice = _notice;
    _notice = null;
    return notice;
  }

  /// Idempotent, so it is safe to call from a proxy provider's update.
  Future<void> initialize({required bool enableAccounts, required bool enableCloudSync}) async {
    _cloudSync = enableCloudSync;
    if (_enabled || !enableAccounts) return;
    _enabled = true;
    await _loadPrefs();
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
    final user = await _currentUser();
    if (user != null && await _readAccountClaim(user)) await startSession();
  }

  /// The signed-in uid, signing in anonymously on the first call. Single
  /// flight: concurrent anonymous sign-ins on a fresh install would create two
  /// users, and the services would listen with a uid the Firestore SDK no
  /// longer uses.
  Future<String?> ensureSignedIn() => _signIn ??= _resolveUid();

  Future<String?> _resolveUid() async {
    try {
      final user = await _currentUser() ?? (await _auth.signInAnonymously()).user;
      return user?.uid;
    } catch (_) {
      _signIn = null;
      rethrow;
    }
  }

  // The first event waits until the persisted user is restored at app start.
  Future<User?> _currentUser() => _auth.authStateChanges().first;

  Future<String> ensureDeviceId() async {
    await _loadPrefs();
    return _deviceId!;
  }

  Future<void> _loadPrefs() async {
    if (_prefs != null) return;
    final prefs = await SharedPreferences.getInstance();
    _accountUid = prefs.getString(_accountUidKey);
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, _deviceId!);
    }
    _prefs = prefs;
  }

  Future<void> _setAccountUid(String? accountUid) async {
    _accountUid = accountUid;
    if (accountUid == null) {
      await _prefs?.remove(_accountUidKey);
    } else {
      await _prefs?.setString(_accountUidKey, accountUid);
    }
  }

  /// The token's `deviceId` claim decides whether this device is on an
  /// account: an iOS reinstall keeps the Firebase user but not the preferences.
  Future<bool> _readAccountClaim(User user) async {
    try {
      final claim = (await user.getIdTokenResult()).claims?['deviceId'];
      if (claim is String) {
        if (claim != _deviceId) {
          _deviceId = claim;
          await _prefs?.setString(_deviceIdKey, claim);
        }
        if (_accountUid != user.uid) await _setAccountUid(user.uid);
        return true;
      }
      if (_accountUid != null) await _setAccountUid(null);
      return false;
    } catch (_) {
      // Offline with an expired ID token: keep what is known.
      return isOnAccount;
    }
  }

  /// Runs on app start for an account device, and whenever the user doc
  /// shows a linked Strava athlete ([athleteId]): the device may then move
  /// into its person's account. A revoked session signs the device out.
  Future<void> startSession({String? athleteId}) {
    if (!_enabled) return Future.value();
    return _sessionRun ??= _startSession(athleteId).whenComplete(() => _sessionRun = null);
  }

  /// Checks again whether this device's session still exists, for example
  /// after a listener on the account was denied.
  Future<void> recheckSession() {
    _verifiedUid = null;
    return startSession();
  }

  Future<void> _startSession(String? athleteId) async {
    try {
      final uid = await ensureSignedIn();
      final user = _auth.currentUser;
      if (uid == null || user == null || _verifiedUid == uid) return;
      final device = await _describeDevice();
      final deviceId = await ensureDeviceId();

      if (await _readAccountClaim(user)) {
        await _api.startSession(deviceId: _deviceId!, platform: device.platform, deviceName: device.name);
        _verifiedUid = uid;
        return;
      }

      if (!_joinAttempts.add('$uid/$athleteId')) return;
      // The call can turn this uid into an account or move the device into
      // another one; listeners on this uid's docs would be denied meanwhile.
      await _switchUser(() async {
        final account = await _api.startSession(deviceId: deviceId, platform: device.platform, deviceName: device.name);
        final token = account?.token;
        if (account == null || token == null) return;
        await _auth.signInWithCustomToken(token);
        await _setAccountUid(account.uid);
        _verifiedUid = account.uid;
        logBreadcrumb(account.uid == uid ? 'Account: created' : 'Account: device moved in');
      });
    } catch (e, s) {
      if (handleSessionRevoked(e)) return;
      if (!_isNetworkError(e)) recordNonFatal(e, s, reason: 'account.startSession');
    }
  }

  /// True for the error a callable returns when this device's session was
  /// revoked; the device is then signed out. Its data is removed only when
  /// cloud sync keeps a copy; without sync it is the only one.
  bool handleSessionRevoked(Object error) {
    if (!isSessionRevokedError(error)) return false;
    unawaited(
      _signOutLocally(
        removeData: _cloudSync,
        notice: _cloudSync ? AccountNotice.sessionRevoked : AccountNotice.sessionRevokedDataKept,
      ),
    );
    return true;
  }

  static bool isSessionRevokedError(Object error) {
    if (error is! FirebaseFunctionsException || error.code != 'unauthenticated') return false;
    final details = error.details;
    return details is Map && details['reason'] == 'session-revoked';
  }

  static bool _isNetworkError(Object error) =>
      error is FirebaseFunctionsException &&
          (error.code == 'unavailable' || error.code == 'deadline-exceeded' || error.code == 'unknown') ||
      error is FirebaseAuthException && error.code == 'network-request-failed';

  /// Signs this device out of the account; the other devices stay signed in.
  /// The session goes first, so a failed call leaves the device signed in
  /// instead of listed under "Your devices" without being on it.
  Future<void> signOut({required bool removeData}) async {
    await _stopWatchingDevices();
    try {
      await _api.revokeSession();
    } catch (e) {
      if (!isSessionRevokedError(e)) rethrow;
    }
    await _signOutLocally(removeData: removeData);
  }

  /// Signs another device of the account out.
  Future<void> revokeDevice(String deviceId) async {
    try {
      await _api.revokeSession(deviceId);
    } catch (e) {
      if (!handleSessionRevoked(e)) rethrow;
    }
  }

  Future<AccountDeletionResult> deleteAccount({required bool removeData}) async {
    await _stopWatchingDevices();
    final result = await _api.deleteAccount();
    await _signOutLocally(removeData: removeData);
    return result;
  }

  /// The account's devices. The stream ends, keeping its last list, before
  /// this device's session is revoked or deleted and before the uid changes:
  /// the rules deny the listener from then on, which would log a
  /// `permission-denied` and flash the error state.
  Stream<List<AccountDevice>> watchDevices() {
    final uid = this.uid;
    if (uid == null) return const Stream.empty();
    final controller = StreamController<List<AccountDevice>>();
    StreamSubscription<List<AccountDevice>>? source;
    Future<void> stop() async {
      _deviceWatches.remove(controller);
      await source?.cancel();
      source = null;
      if (!controller.isClosed) unawaited(controller.close());
    }

    controller
      ..onListen = () {
        _deviceWatches[controller] = stop;
        source = _api.watchDevices(uid).listen(controller.add, onError: controller.addError, onDone: stop);
      }
      ..onCancel = stop;
    return controller.stream;
  }

  Future<void> _stopWatchingDevices() async {
    for (final stop in _deviceWatches.values.toList()) {
      await stop();
    }
  }

  /// Back on a new anonymous uid. Local Strava data always goes: the Strava
  /// link stays with the account.
  Future<void> _signOutLocally({required bool removeData, AccountNotice? notice}) {
    return _signOutRun ??= () async {
      try {
        await _switchUser(() async {
          await _auth.signOut();
          await _setAccountUid(null);
          _verifiedUid = null;
          await _clearLocalData(removeData: removeData);
        });
        if (notice != null) _notice = notice;
        notifyListeners();
      } finally {
        _signOutRun = null;
      }
    }();
  }

  void _onAuthChanged(User? user) {
    if (_switching) return;
    // Firebase signs out by itself when the account's user was deleted or
    // disabled, for example by "Delete account" on another device. The cloud
    // copy is gone with it, so the local data is kept.
    if (user == null && _accountUid != null) {
      unawaited(_signOutLocally(removeData: false, notice: AccountNotice.accountDeleted));
    }
    notifyListeners();
  }

  Future<void> _switchUser(Future<void> Function() change) => _serialized(() async {
    _switching = true;
    try {
      await _stopWatchingDevices();
      for (final service in _bound) {
        await service.unbindUser();
      }
      try {
        await change();
      } finally {
        _signIn = null;
        final uid = await ensureSignedIn();
        if (uid != null) {
          for (final service in _bound) {
            await service.bindUser(uid);
          }
        }
      }
    } finally {
      _switching = false;
      notifyListeners();
    }
  });

  /// The `platform` value the backend accepts, or null on an unknown platform.
  static String? get platformName {
    if (kIsWeb) return 'web';
    const known = {'android', 'ios', 'macos', 'windows', 'linux'};
    return known.contains(Platform.operatingSystem) ? Platform.operatingSystem : null;
  }

  static Future<DeviceDescription> describeThisDevice() async {
    final platform = platformName ?? 'android';
    try {
      final info = DeviceInfoPlugin();
      final name = switch (platform) {
        'android' => (await info.androidInfo).model,
        'ios' => (await info.iosInfo).modelName,
        'macos' => (await info.macOsInfo).modelName,
        _ => null,
      };
      return (platform: platform, name: name);
    } catch (_) {
      return (platform: platform, name: null);
    }
  }
}
