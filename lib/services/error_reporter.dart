import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

typedef BootErrorReporter = void Function(Object error, StackTrace stack, {required String reason});

void recordNonFatal(Object error, StackTrace stack, {required String reason}) {
  if (Firebase.apps.isEmpty) return;
  unawaited(FirebaseCrashlytics.instance.recordError(error, stack, reason: reason, fatal: false));
}

void logBreadcrumb(String message) {
  if (Firebase.apps.isEmpty) return;
  unawaited(FirebaseCrashlytics.instance.log(message));
}
