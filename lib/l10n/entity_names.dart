import '../models/feedback/test_session.dart';
import '../models/setup.dart';
import 'app_localizations.dart';

/// Names to show for records whose name is optional. The placeholder is never
/// stored, so it follows the app language.

extension SetupName on Setup {
  String label(AppLocalizations l10n) => name ?? l10n.setupUnnamed;
}

extension TestSessionName on TestSession {
  String label(AppLocalizations l10n) => name ?? l10n.testSessionUnnamed;
}
