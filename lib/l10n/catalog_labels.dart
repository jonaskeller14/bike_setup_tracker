import 'package:intl/intl.dart';

import '../models/component/preset_spec_keys.dart';
import 'app_localizations.dart';

/// Display names of the catalog's registered properties, choices and levels.
/// The YAML and the parser keep working with the English ids and labels.

extension SpecKeyName<T extends Object> on SpecKey<T> {
  /// Sentence form: lowercase in English, nouns capitalised in German.
  String inSentence(AppLocalizations l10n) => switch (id) {
    'travel_mm' => l10n.catalogTermTravel,
    'wheel_size' => l10n.catalogTermWheelSize,
    'stanchion' => l10n.catalogTermStanchion,
    'spring' => l10n.catalogTermSpring,
    'eye_to_eye_mm' => l10n.catalogTermEyeToEye,
    'stroke_mm' => l10n.catalogTermStroke,
    'mount' => l10n.catalogTermMount,
    _ => label.toLowerCase(),
  };

  /// For a heading or the start of a note line.
  String name(AppLocalizations l10n) => _capitalised(inSentence(l10n), l10n);
}

extension OptionAxisKeyName on OptionAxisKey {
  String inSentence(AppLocalizations l10n) => switch (id) {
    'damper' => l10n.catalogTermDamper,
    'travel_mm' => l10n.catalogTermTravel,
    'wheel_size' => l10n.catalogTermWheelSize,
    'size' => l10n.catalogTermSize,
    _ => label.toLowerCase(),
  };

  String name(AppLocalizations l10n) => _capitalised(inSentence(l10n), l10n);
}

/// A level of a brand's tree (`trim`, `model`) in the sentence form, for the
/// picker title. Levels are authored in the YAML, so an unknown one keeps its id.
String catalogLevelInSentence(String level, AppLocalizations l10n) => switch (level) {
  'generation' => l10n.catalogTermGeneration,
  'model' => l10n.catalogTermModel,
  'trim' => l10n.catalogTermTrim,
  'version' => l10n.catalogTermVersion,
  'mount' => l10n.catalogTermMount,
  _ => level.replaceAll('_', ' '),
};

String _capitalised(String text, AppLocalizations l10n) => toBeginningOfSentenceCase(text, l10n.localeName) ?? text;
