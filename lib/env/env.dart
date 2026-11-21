import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'MAPBOX_TOKEN', obfuscate: true)
  static final String mapboxToken = _Env.mapboxToken;

  @EnviedField(varName: 'APP_CHECK_DEBUG_TOKEN_ANDROID', obfuscate: true)
  static final String _appCheckDebugTokenAndroid = _Env._appCheckDebugTokenAndroid;

  @EnviedField(varName: 'APP_CHECK_DEBUG_TOKEN_IOS', obfuscate: true)
  static final String _appCheckDebugTokenIos = _Env._appCheckDebugTokenIos;

  // null lets the App Check SDK generate and log its own debug token.
  static String? get appCheckDebugTokenAndroid =>
      _appCheckDebugTokenAndroid.isEmpty ? null : _appCheckDebugTokenAndroid;

  static String? get appCheckDebugTokenIos =>
      _appCheckDebugTokenIos.isEmpty ? null : _appCheckDebugTokenIos;
}
