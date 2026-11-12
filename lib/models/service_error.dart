/// A failure a service reports without text: the UI turns [kind] into a
/// sentence in the app language (`enum_labels.dart`). [detail] is the technical
/// reason (an exception text) and is shown as is.
class ServiceError<K extends Enum> {
  final K kind;
  final String? detail;

  const ServiceError(this.kind, [this.detail]);

  @override
  String toString() => detail == null ? kind.name : '${kind.name}: $detail';
}

enum DataErrorKind {
  getLocalBackups,
  readLocalBackup,
  importFile,
  noFileSelected,
  bundleWithoutData,
  driveNoInternet,
  driveApi,
  driveUnexpected,
  readDriveBackup,
}

typedef DataError = ServiceError<DataErrorKind>;

sealed class DataResult<T> {
  const DataResult();
}

final class DataSuccess<T> extends DataResult<T> {
  final T value;

  const DataSuccess(this.value);
}

final class DataFailure<T> extends DataResult<T> {
  final DataError error;

  const DataFailure(this.error);
}

enum GoogleDriveErrorKind {
  setupFailed,
  unknown,
  signInCanceled,
  signInInterrupted,
  signInFailed,
  platformUnsupported,
  reauthRequired,
  reauthFailed,
  api,
  noInternet,
  syncFailed,
  authExpired,
  backupFailed,
}

typedef GoogleDriveError = ServiceError<GoogleDriveErrorKind>;

enum StravaErrorKind {
  /// [ServiceError.detail] is the text the server wrote to the user document.
  serverMessage,
  syncFailed,
  connectionVerifyFailed,
  backgroundSyncFailed,
  serverUnreachable,
  noBrowser,
  loginFailed,
  subscriptionRequired,
  signInFailed,
  signInFailedGeneric,
  disconnectFailed,
  fullSyncFailed,
  noInternet,
  authentication,
  rateLimited,
  ownedByOtherAccount,
  limitReached,
}

typedef StravaFailure = ServiceError<StravaErrorKind>;

enum SubscriptionErrorKind {
  noPreviousPurchase,
  streamFailed,
  initFailed,
  entitlementStreamFailed,
  plansLoadFailed,
  plansUnavailable,
  storeUnavailable,
  planNotLoaded,
  purchaseFailed,
  restoreFailed,
  missingTransactionId,
  subscriptionInactive,
  verifyFailed,
  noInternet,
  authentication,
}

typedef SubscriptionFailure = ServiceError<SubscriptionErrorKind>;

enum TipErrorKind {
  streamFailed,
  storeUnavailable,
  initFailed,
  loadFailed,
  tipsUnavailable,
  tipNotLoaded,
  purchaseFailed,
}

typedef TipFailure = ServiceError<TipErrorKind>;
