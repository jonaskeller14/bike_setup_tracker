// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

abstract final class WeatherIcons {
  static const _f = 'WeatherIcons';

  static const IconData day_sunny            = IconData(0xf00d, fontFamily: _f);
  static const IconData day_sunny_overcast   = IconData(0xf00c, fontFamily: _f);
  static const IconData day_cloudy           = IconData(0xf002, fontFamily: _f);
  static const IconData day_fog              = IconData(0xf003, fontFamily: _f);
  static const IconData day_sprinkle         = IconData(0xf00b, fontFamily: _f);
  static const IconData day_rain_mix         = IconData(0xf006, fontFamily: _f);
  static const IconData day_rain             = IconData(0xf008, fontFamily: _f);
  static const IconData day_sleet            = IconData(0xf0b2, fontFamily: _f);
  static const IconData day_snow             = IconData(0xf00a, fontFamily: _f);
  static const IconData day_snow_wind        = IconData(0xf065, fontFamily: _f);
  static const IconData day_showers          = IconData(0xf009, fontFamily: _f);
  static const IconData day_storm_showers    = IconData(0xf00e, fontFamily: _f);
  static const IconData day_thunderstorm     = IconData(0xf010, fontFamily: _f);
  static const IconData night_clear          = IconData(0xf02e, fontFamily: _f);
  static const IconData night_alt_partly_cloudy  = IconData(0xf081, fontFamily: _f);
  static const IconData night_alt_cloudy     = IconData(0xf086, fontFamily: _f);
  static const IconData night_fog            = IconData(0xf04a, fontFamily: _f);
  static const IconData night_sprinkle       = IconData(0xf039, fontFamily: _f);
  static const IconData night_alt_rain_mix   = IconData(0xf026, fontFamily: _f);
  static const IconData night_alt_rain       = IconData(0xf028, fontFamily: _f);
  static const IconData night_alt_sleet      = IconData(0xf0b4, fontFamily: _f);
  static const IconData night_alt_snow       = IconData(0xf02a, fontFamily: _f);
  static const IconData night_alt_snow_wind  = IconData(0xf067, fontFamily: _f);
  static const IconData night_alt_showers    = IconData(0xf029, fontFamily: _f);
  static const IconData night_alt_storm_showers = IconData(0xf02c, fontFamily: _f);
  static const IconData night_alt_thunderstorm  = IconData(0xf02d, fontFamily: _f);
  static const IconData cloudy               = IconData(0xf013, fontFamily: _f);
  static const IconData na                   = IconData(0xf07b, fontFamily: _f);
}
