enum AppLanguage {
  de('🇩🇪', 'Deutsch'),
  en('🇬🇧', 'English'),
  es('🇪🇸', 'Español'),
  fr('🇫🇷', 'Français'),
  it('🇮🇹', 'Italiano'),
  pt('🇧🇷', 'Português (Brasil)');

  const AppLanguage(this.flag, this.nativeName);

  final String flag;
  final String nativeName;

  static AppLanguage? fromCode(String? code) => values.asNameMap()[code];
}
