/// App-wide identity, contact, store and legal links.
///
/// Previously these were static fields on `AboutPage`. They were lifted out
/// when About was merged into Settings so they no longer depend on a page
/// widget and can be referenced from anywhere (paywall, error page, …).
class AppInfo {
  AppInfo._();

  static const String appVersion = '1.3.6';
  static const String buildNumber = '28';
  static const String releaseDate = 'June 2026';

  static const String supportEmail = 'jonaskeller14.app+support@gmail.com';
  static const String featuresEmail = 'jonaskeller14.app+features@gmail.com';
  static const String bugsEmail = 'jonaskeller14.app+bugs@gmail.com';

  static const String privacyPolicyUrl = 'https://jonaskeller14.com/bike_setup_tracker/privacy_policy.html';
  static const String eulaUrl = 'https://jonaskeller14.com/bike_setup_tracker/eula.html';
  static const String tosUrl = 'https://jonaskeller14.com/bike_setup_tracker/terms_of_service.html';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.jonaskeller14.bike_setup_tracker';
  static const String appStoreUrl = 'https://apps.apple.com/app/id6759974325?action=write-review';
  static const String stravaClubForumUrl = 'https://www.strava.com/clubs/bike_setup_tracker';
}
