enum AppLanguage {
  en('🇬🇧', 'English'),
  de('🇩🇪', 'Deutsch');

  const AppLanguage(this.flag, this.nativeName);

  final String flag;
  final String nativeName;

  static AppLanguage? fromCode(String? code) => values.asNameMap()[code];
}
