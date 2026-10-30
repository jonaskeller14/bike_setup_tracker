import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de'), Locale('en')];

  /// Name of the app, shown in the task switcher.
  ///
  /// In en, this message translates to:
  /// **'Bike Setup Tracker'**
  String get appTitle;

  /// Button that dismisses a dialog or sheet without making changes.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button that stores the changes made in a form, dialog or sheet.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button that deletes an item.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Button that acknowledges a message.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Title of the home screen long-press shortcut that opens the new setup form.
  ///
  /// In en, this message translates to:
  /// **'Add New Setup'**
  String get quickActionAddSetup;

  /// Name of the component category "Frame" in the component type pickers and filters.
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get componentTypeCategoryFrame;

  /// Name of the component category "Suspension" in the component type pickers and filters.
  ///
  /// In en, this message translates to:
  /// **'Suspension'**
  String get componentTypeCategorySuspension;

  /// Name of the component category "Cockpit" in the component type pickers and filters.
  ///
  /// In en, this message translates to:
  /// **'Cockpit'**
  String get componentTypeCategoryCockpit;

  /// Name of the component category "Drivetrain" in the component type pickers and filters.
  ///
  /// In en, this message translates to:
  /// **'Drivetrain'**
  String get componentTypeCategoryDrivetrain;

  /// Name of the component category "Brakes" in the component type pickers and filters.
  ///
  /// In en, this message translates to:
  /// **'Brakes'**
  String get componentTypeCategoryBrakes;

  /// Name of the component category "Wheels" in the component type pickers and filters.
  ///
  /// In en, this message translates to:
  /// **'Wheels'**
  String get componentTypeCategoryWheels;

  /// Name of the component category "Seating" in the component type pickers and filters.
  ///
  /// In en, this message translates to:
  /// **'Seating'**
  String get componentTypeCategorySeating;

  /// Name of the component category "Electronics" in the component type pickers and filters.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get componentTypeCategoryElectronics;

  /// Name of the component category "Others" in the component type pickers and filters.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get componentTypeCategoryOthers;

  /// Name of the component type "Frame".
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get componentTypeFrame;

  /// Name of the component type "Fork".
  ///
  /// In en, this message translates to:
  /// **'Fork'**
  String get componentTypeFork;

  /// Name of the component type "Shock".
  ///
  /// In en, this message translates to:
  /// **'Shock'**
  String get componentTypeShock;

  /// Name of the component type "Handlebar".
  ///
  /// In en, this message translates to:
  /// **'Handlebar'**
  String get componentTypeCockpit;

  /// Name of the component type "Stem".
  ///
  /// In en, this message translates to:
  /// **'Stem'**
  String get componentTypeStem;

  /// Name of the component type "Grip".
  ///
  /// In en, this message translates to:
  /// **'Grip'**
  String get componentTypeGrip;

  /// Name of the component type "Headset".
  ///
  /// In en, this message translates to:
  /// **'Headset'**
  String get componentTypeHeadset;

  /// Name of the component type "Shifter".
  ///
  /// In en, this message translates to:
  /// **'Shifter'**
  String get componentTypeShifter;

  /// Name of the component type "Bottom Bracket".
  ///
  /// In en, this message translates to:
  /// **'Bottom Bracket'**
  String get componentTypeBottomBracket;

  /// Name of the component type "Crank".
  ///
  /// In en, this message translates to:
  /// **'Crank'**
  String get componentTypeCrank;

  /// Name of the component type "Derailleur".
  ///
  /// In en, this message translates to:
  /// **'Derailleur'**
  String get componentTypeDerailleur;

  /// Name of the component type "Chainring".
  ///
  /// In en, this message translates to:
  /// **'Chainring'**
  String get componentTypeChainring;

  /// Name of the component type "Cassette".
  ///
  /// In en, this message translates to:
  /// **'Cassette'**
  String get componentTypeCasette;

  /// Name of the component type "Chain".
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get componentTypeChain;

  /// Name of the component type "Pedal".
  ///
  /// In en, this message translates to:
  /// **'Pedal'**
  String get componentTypePedal;

  /// Name of the component type "Shift Inner Cable".
  ///
  /// In en, this message translates to:
  /// **'Shift Inner Cable'**
  String get componentTypeShiftInnerCable;

  /// Name of the component type "Brake Calliper".
  ///
  /// In en, this message translates to:
  /// **'Brake Calliper'**
  String get componentTypeBrakeCalliper;

  /// Name of the component type "Brake Lever".
  ///
  /// In en, this message translates to:
  /// **'Brake Lever'**
  String get componentTypeBrakeLever;

  /// Name of the component type "Brake Pad".
  ///
  /// In en, this message translates to:
  /// **'Brake Pad'**
  String get componentTypeBrakePad;

  /// Name of the component type "Brake Disc".
  ///
  /// In en, this message translates to:
  /// **'Brake Disc'**
  String get componentTypeBrakeDisc;

  /// Name of the component type "Front Wheel".
  ///
  /// In en, this message translates to:
  /// **'Front Wheel'**
  String get componentTypeWheelFront;

  /// Name of the component type "Rear Wheel".
  ///
  /// In en, this message translates to:
  /// **'Rear Wheel'**
  String get componentTypeWheelRear;

  /// Name of the component type "Tire".
  ///
  /// In en, this message translates to:
  /// **'Tire'**
  String get componentTypeTire;

  /// Name of the component type "Saddle".
  ///
  /// In en, this message translates to:
  /// **'Saddle'**
  String get componentTypeSaddle;

  /// Name of the component type "Seatpost".
  ///
  /// In en, this message translates to:
  /// **'Seatpost'**
  String get componentTypeSeatpost;

  /// Name of the component type "Battery".
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get componentTypeBattery;

  /// Name of the component type "Motor".
  ///
  /// In en, this message translates to:
  /// **'Motor'**
  String get componentTypeMotor;

  /// Name of the component type "Bearing".
  ///
  /// In en, this message translates to:
  /// **'Bearing'**
  String get componentTypeBearing;

  /// Name of the component type "Equipment".
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get componentTypeEquipment;

  /// Name of the component type "Other".
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get componentTypeOther;

  /// Name of the measured quantity "Pressure" in the unit picker.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get unitQuantityPressure;

  /// Name of the measured quantity "Length" in the unit picker.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get unitQuantityLength;

  /// Name of the measured quantity "Mass" in the unit picker.
  ///
  /// In en, this message translates to:
  /// **'Mass'**
  String get unitQuantityMass;

  /// Name of the measured quantity "Temperature" in the unit picker.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get unitQuantityTemperature;

  /// Name of the measured quantity "Speed" in the unit picker.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get unitQuantitySpeed;

  /// Name of the measured quantity "Angle" in the unit picker.
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get unitQuantityAngle;

  /// Name of the measured quantity "Torque" in the unit picker.
  ///
  /// In en, this message translates to:
  /// **'Torque'**
  String get unitQuantityTorque;

  /// Name of the measured quantity "Volume" in the unit picker.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get unitQuantityVolume;

  /// Name of the measured quantity "Spring Rate" in the unit picker.
  ///
  /// In en, this message translates to:
  /// **'Spring Rate'**
  String get unitQuantitySpringRate;

  /// Task priority "Low".
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get taskPriorityLow;

  /// Task priority "Medium".
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get taskPriorityMedium;

  /// Task priority "High".
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get taskPriorityHigh;

  /// Task priority "Critical".
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get taskPriorityCritical;

  /// Name of the monthly Strava sync subscription plan.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get stravaPlanMonthlyLabel;

  /// Short pitch under the monthly Strava sync plan.
  ///
  /// In en, this message translates to:
  /// **'Try it month to month'**
  String get stravaPlanMonthlyTagline;

  /// Billing period shown after the price of the monthly Strava sync plan.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get stravaPlanMonthlyPeriod;

  /// Name of the yearly Strava sync subscription plan.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get stravaPlanYearlyLabel;

  /// Short pitch under the yearly Strava sync plan.
  ///
  /// In en, this message translates to:
  /// **'Best for the full season'**
  String get stravaPlanYearlyTagline;

  /// Billing period shown after the price of the yearly Strava sync plan.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get stravaPlanYearlyPeriod;

  /// Label of the Strava workout type "Activity".
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get stravaWorkoutTypeNone;

  /// Label of the Strava workout type "Race".
  ///
  /// In en, this message translates to:
  /// **'Race'**
  String get stravaWorkoutTypeRace;

  /// Label of the Strava workout type "Workout".
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get stravaWorkoutTypeWorkout;

  /// Name of the Strava sport type "Alpine Ski".
  ///
  /// In en, this message translates to:
  /// **'Alpine Ski'**
  String get sportTypeAlpineSki;

  /// Name of the Strava sport type "Backcountry Ski".
  ///
  /// In en, this message translates to:
  /// **'Backcountry Ski'**
  String get sportTypeBackcountrySki;

  /// Name of the Strava sport type "Badminton".
  ///
  /// In en, this message translates to:
  /// **'Badminton'**
  String get sportTypeBadminton;

  /// Name of the Strava sport type "Canoeing".
  ///
  /// In en, this message translates to:
  /// **'Canoeing'**
  String get sportTypeCanoeing;

  /// Name of the Strava sport type "Crossfit".
  ///
  /// In en, this message translates to:
  /// **'Crossfit'**
  String get sportTypeCrossfit;

  /// Name of the Strava sport type "E-Bike Ride".
  ///
  /// In en, this message translates to:
  /// **'E-Bike Ride'**
  String get sportTypeEBikeRide;

  /// Name of the Strava sport type "Elliptical".
  ///
  /// In en, this message translates to:
  /// **'Elliptical'**
  String get sportTypeElliptical;

  /// Name of the Strava sport type "E-Mountain Bike Ride".
  ///
  /// In en, this message translates to:
  /// **'E-Mountain Bike Ride'**
  String get sportTypeEMountainBikeRide;

  /// Name of the Strava sport type "Golf".
  ///
  /// In en, this message translates to:
  /// **'Golf'**
  String get sportTypeGolf;

  /// Name of the Strava sport type "Gravel Ride".
  ///
  /// In en, this message translates to:
  /// **'Gravel Ride'**
  String get sportTypeGravelRide;

  /// Name of the Strava sport type "Handcycle".
  ///
  /// In en, this message translates to:
  /// **'Handcycle'**
  String get sportTypeHandcycle;

  /// Name of the Strava sport type "HIIT".
  ///
  /// In en, this message translates to:
  /// **'HIIT'**
  String get sportTypeHighIntensityIntervalTraining;

  /// Name of the Strava sport type "Hike".
  ///
  /// In en, this message translates to:
  /// **'Hike'**
  String get sportTypeHike;

  /// Name of the Strava sport type "Ice Skate".
  ///
  /// In en, this message translates to:
  /// **'Ice Skate'**
  String get sportTypeIceSkate;

  /// Name of the Strava sport type "Inline Skate".
  ///
  /// In en, this message translates to:
  /// **'Inline Skate'**
  String get sportTypeInlineSkate;

  /// Name of the Strava sport type "Kayaking".
  ///
  /// In en, this message translates to:
  /// **'Kayaking'**
  String get sportTypeKayaking;

  /// Name of the Strava sport type "Kitesurf".
  ///
  /// In en, this message translates to:
  /// **'Kitesurf'**
  String get sportTypeKitesurf;

  /// Name of the Strava sport type "Mountain Bike Ride".
  ///
  /// In en, this message translates to:
  /// **'Mountain Bike Ride'**
  String get sportTypeMountainBikeRide;

  /// Name of the Strava sport type "Nordic Ski".
  ///
  /// In en, this message translates to:
  /// **'Nordic Ski'**
  String get sportTypeNordicSki;

  /// Name of the Strava sport type "Pickleball".
  ///
  /// In en, this message translates to:
  /// **'Pickleball'**
  String get sportTypePickleball;

  /// Name of the Strava sport type "Pilates".
  ///
  /// In en, this message translates to:
  /// **'Pilates'**
  String get sportTypePilates;

  /// Name of the Strava sport type "Racquetball".
  ///
  /// In en, this message translates to:
  /// **'Racquetball'**
  String get sportTypeRacquetball;

  /// Name of the Strava sport type "Ride".
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get sportTypeRide;

  /// Name of the Strava sport type "Rock Climbing".
  ///
  /// In en, this message translates to:
  /// **'Rock Climbing'**
  String get sportTypeRockClimbing;

  /// Name of the Strava sport type "Roller Ski".
  ///
  /// In en, this message translates to:
  /// **'Roller Ski'**
  String get sportTypeRollerSki;

  /// Name of the Strava sport type "Rowing".
  ///
  /// In en, this message translates to:
  /// **'Rowing'**
  String get sportTypeRowing;

  /// Name of the Strava sport type "Run".
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get sportTypeRun;

  /// Name of the Strava sport type "Sail".
  ///
  /// In en, this message translates to:
  /// **'Sail'**
  String get sportTypeSail;

  /// Name of the Strava sport type "Skateboard".
  ///
  /// In en, this message translates to:
  /// **'Skateboard'**
  String get sportTypeSkateboard;

  /// Name of the Strava sport type "Snowboard".
  ///
  /// In en, this message translates to:
  /// **'Snowboard'**
  String get sportTypeSnowboard;

  /// Name of the Strava sport type "Snowshoe".
  ///
  /// In en, this message translates to:
  /// **'Snowshoe'**
  String get sportTypeSnowshoe;

  /// Name of the Strava sport type "Soccer".
  ///
  /// In en, this message translates to:
  /// **'Soccer'**
  String get sportTypeSoccer;

  /// Name of the Strava sport type "Squash".
  ///
  /// In en, this message translates to:
  /// **'Squash'**
  String get sportTypeSquash;

  /// Name of the Strava sport type "Stair Stepper".
  ///
  /// In en, this message translates to:
  /// **'Stair Stepper'**
  String get sportTypeStairStepper;

  /// Name of the Strava sport type "Stand Up Paddling".
  ///
  /// In en, this message translates to:
  /// **'Stand Up Paddling'**
  String get sportTypeStandUpPaddling;

  /// Name of the Strava sport type "Surfing".
  ///
  /// In en, this message translates to:
  /// **'Surfing'**
  String get sportTypeSurfing;

  /// Name of the Strava sport type "Swim".
  ///
  /// In en, this message translates to:
  /// **'Swim'**
  String get sportTypeSwim;

  /// Name of the Strava sport type "Table Tennis".
  ///
  /// In en, this message translates to:
  /// **'Table Tennis'**
  String get sportTypeTableTennis;

  /// Name of the Strava sport type "Tennis".
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get sportTypeTennis;

  /// Name of the Strava sport type "Trail Run".
  ///
  /// In en, this message translates to:
  /// **'Trail Run'**
  String get sportTypeTrailRun;

  /// Name of the Strava sport type "Velomobile".
  ///
  /// In en, this message translates to:
  /// **'Velomobile'**
  String get sportTypeVelomobile;

  /// Name of the Strava sport type "Virtual Ride".
  ///
  /// In en, this message translates to:
  /// **'Virtual Ride'**
  String get sportTypeVirtualRide;

  /// Name of the Strava sport type "Virtual Row".
  ///
  /// In en, this message translates to:
  /// **'Virtual Row'**
  String get sportTypeVirtualRow;

  /// Name of the Strava sport type "Virtual Run".
  ///
  /// In en, this message translates to:
  /// **'Virtual Run'**
  String get sportTypeVirtualRun;

  /// Name of the Strava sport type "Walk".
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get sportTypeWalk;

  /// Name of the Strava sport type "Weight Training".
  ///
  /// In en, this message translates to:
  /// **'Weight Training'**
  String get sportTypeWeightTraining;

  /// Name of the Strava sport type "Wheelchair".
  ///
  /// In en, this message translates to:
  /// **'Wheelchair'**
  String get sportTypeWheelchair;

  /// Name of the Strava sport type "Windsurf".
  ///
  /// In en, this message translates to:
  /// **'Windsurf'**
  String get sportTypeWindsurf;

  /// Name of the Strava sport type "Workout".
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get sportTypeWorkout;

  /// Name of the Strava sport type "Yoga".
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get sportTypeYoga;

  /// Name of the Strava sport type "Other".
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sportTypeOther;

  /// Ground condition "Dry" of a setup.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get weatherConditionDry;

  /// Ground condition "Moist" of a setup.
  ///
  /// In en, this message translates to:
  /// **'Moist'**
  String get weatherConditionMoist;

  /// Ground condition "Wet" of a setup.
  ///
  /// In en, this message translates to:
  /// **'Wet'**
  String get weatherConditionWet;

  /// Ground condition "Muddy" of a setup.
  ///
  /// In en, this message translates to:
  /// **'Muddy'**
  String get weatherConditionMuddy;

  /// How a step adjustment is drawn: "Plus/Minus Buttons".
  ///
  /// In en, this message translates to:
  /// **'Plus/Minus Buttons'**
  String get stepVisualizationMinusButtonValuePlusButton;

  /// How a step adjustment is drawn: "Buttons with Clockwise Dial".
  ///
  /// In en, this message translates to:
  /// **'Buttons with Clockwise Dial'**
  String get stepVisualizationMinusButtonValuePlusButtonClockwiseDial;

  /// How a step adjustment is drawn: "Buttons with Counterclockwise Dial".
  ///
  /// In en, this message translates to:
  /// **'Buttons with Counterclockwise Dial'**
  String get stepVisualizationMinusButtonValuePlusButtonCounterclockwiseDial;

  /// How a step adjustment is drawn: "Slider".
  ///
  /// In en, this message translates to:
  /// **'Slider'**
  String get stepVisualizationSlider;

  /// How a step adjustment is drawn: "Slider with Clockwise Dial".
  ///
  /// In en, this message translates to:
  /// **'Slider with Clockwise Dial'**
  String get stepVisualizationSliderWithClockwiseDial;

  /// How a step adjustment is drawn: "Slider with Counterclockwise Dial".
  ///
  /// In en, this message translates to:
  /// **'Slider with Counterclockwise Dial'**
  String get stepVisualizationSliderWithCounterclockwiseDial;

  /// Label of the tip option "Buy me a coffee".
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get tipProductSmall;

  /// Label of the tip option "Buy me a snack".
  ///
  /// In en, this message translates to:
  /// **'Buy me a snack'**
  String get tipProductMedium;

  /// Label of the tip option "Buy me a meal".
  ///
  /// In en, this message translates to:
  /// **'Buy me a meal'**
  String get tipProductLarge;

  /// Warning that a component's installation target is gone: "Bike not found".
  ///
  /// In en, this message translates to:
  /// **'Bike not found'**
  String get installationIssueMissingBike;

  /// Warning that a component's installation target is gone: "Parent component not found".
  ///
  /// In en, this message translates to:
  /// **'Parent component not found'**
  String get installationIssueMissingParent;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
