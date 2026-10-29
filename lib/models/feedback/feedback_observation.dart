import 'package:flutter/foundation.dart';

import 'feedback_key.dart';

/// One answer of a feedback, stored raw (never normalized).
@immutable
class FeedbackObservation {
  final FeedbackKey key;
  final double? value;
  final String? textValue;

  const FeedbackObservation({
    required this.key,
    this.value,
    this.textValue,
  });

  /// A flagged problem or "Nothing stood out".
  const FeedbackObservation.flag(this.key) : value = 1, textValue = null;

  Map<String, dynamic> toJson() => {
    'key': key.raw,
    'value': value,
    'textValue': textValue,
  };

  factory FeedbackObservation.fromJson(Map<String, dynamic> json) {
    return FeedbackObservation(
      key: FeedbackKey.parse(json['key'] as String),
      value: (json['value'] as num?)?.toDouble(),
      textValue: json['textValue'] as String?,
    );
  }

  FeedbackObservation copyWith({
    Object? key = const _Sentinel(),
    Object? value = const _Sentinel(),
    Object? textValue = const _Sentinel(),
  }) {
    return FeedbackObservation(
      key: key is _Sentinel ? this.key : (key as FeedbackKey),
      value: value is _Sentinel ? this.value : (value as double?),
      textValue: textValue is _Sentinel ? this.textValue : (textValue as String?),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeedbackObservation && key == other.key && value == other.value && textValue == other.textValue;
  }

  @override
  int get hashCode => Object.hash(key, value, textValue);

  @override
  String toString() => 'FeedbackObservation($key, $value, $textValue)';
}

class _Sentinel {
  const _Sentinel();
}
