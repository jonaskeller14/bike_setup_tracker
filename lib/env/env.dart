import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'MAPBOX_TOKEN', obfuscate: true)
  static final String mapboxToken = _Env.mapboxToken;
}
