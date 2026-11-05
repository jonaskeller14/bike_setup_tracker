import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
  ];

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

  /// Label of the "on" choice of a setting that can be switched on or off.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get valueOn;

  /// Label of the "off" choice of a setting that can be switched on or off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get valueOff;

  /// App bar title while list items are selected. {count} is the number of selected items.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectionCount(int count);

  /// Tooltip of the app bar button that deletes all selected items.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelectedTooltip;

  /// Tooltip of the floating button that scrolls a list back to its top.
  ///
  /// In en, this message translates to:
  /// **'Back to top'**
  String get backToTopTooltip;

  /// Snackbar shown when no email app can be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open email client.'**
  String get errorCouldNotOpenEmailClient;

  /// App bar title of the Bikes tab.
  ///
  /// In en, this message translates to:
  /// **'Bikes'**
  String get homeTitleBikes;

  /// App bar title of the Setups tab.
  ///
  /// In en, this message translates to:
  /// **'Setup History'**
  String get homeTitleSetupHistory;

  /// App bar title of the Riders tab.
  ///
  /// In en, this message translates to:
  /// **'Riders'**
  String get homeTitleRiders;

  /// App bar title of the Tasks tab.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get homeTitleTasks;

  /// Label of the Bikes destination in the bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'Bikes'**
  String get homeNavBikes;

  /// Label of the Setups destination in the bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'Setups'**
  String get homeNavSetups;

  /// Label of the Riders destination in the bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'Riders'**
  String get homeNavRiders;

  /// Label of the Tasks destination in the bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get homeNavTasks;

  /// Entry of the home overflow menu that imports data.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get homeMenuImport;

  /// Entry of the home overflow menu that exports data.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get homeMenuExport;

  /// Entry of the home overflow menu that shares data.
  ///
  /// In en, this message translates to:
  /// **'Share Data'**
  String get homeMenuShare;

  /// Entry of the home overflow menu that opens the trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get homeMenuTrash;

  /// Entry of the home overflow menu that opens the settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeMenuSettings;

  /// Tooltip of the app bar button that assigns a rider to the selected bikes.
  ///
  /// In en, this message translates to:
  /// **'Set rider'**
  String get homeTooltipSetRider;

  /// Tooltip of the app bar button that removes the bookmark from the selected setups.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get homeTooltipRemoveBookmark;

  /// Tooltip of the app bar button that bookmarks the selected setups.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get homeTooltipBookmark;

  /// Tooltip of the app bar button that sets tags on the selected items.
  ///
  /// In en, this message translates to:
  /// **'Set tags'**
  String get homeTooltipSetTags;

  /// Tooltip of the app bar button that sets the priority of the selected tasks.
  ///
  /// In en, this message translates to:
  /// **'Set priority'**
  String get homeTooltipSetPriority;

  /// Tooltip of the app bar button that opens the rider profile.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get homeTooltipRider;

  /// Tooltip of the floating button that adds a bike.
  ///
  /// In en, this message translates to:
  /// **'Add Bike'**
  String get homeTooltipAddBike;

  /// Tooltip of the floating button that adds a rider.
  ///
  /// In en, this message translates to:
  /// **'Add Rider'**
  String get homeTooltipAddRider;

  /// Tooltip of the floating button that adds a task.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get homeTooltipAddTask;

  /// Label and tooltip of the floating button that adds a setup.
  ///
  /// In en, this message translates to:
  /// **'Add Setup'**
  String get homeAddSetup;

  /// Tooltip of the floating button that starts a test session.
  ///
  /// In en, this message translates to:
  /// **'Start test session'**
  String get homeTooltipStartTestSession;

  /// Tooltip of the floating button that ends the running test session. {name} is the session name.
  ///
  /// In en, this message translates to:
  /// **'End test session \'{name}\''**
  String homeTooltipEndTestSession(String name);

  /// Message on the page shown when the app fails to load its data.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data. \nClose and restart the app.'**
  String get loadingErrorMessage;

  /// Title of the entry that opens an email to support on the load error page.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get loadingErrorContactSupport;

  /// Title of the entry that exports the latest backup on the load error page.
  ///
  /// In en, this message translates to:
  /// **'Download latest Backup'**
  String get loadingErrorDownloadBackup;

  /// Subtitle of the entry that exports the latest backup on the load error page.
  ///
  /// In en, this message translates to:
  /// **'Download app data as JSON file'**
  String get loadingErrorDownloadBackupSubtitle;

  /// Title of the entry that exports the latest backup with attachments on the load error page.
  ///
  /// In en, this message translates to:
  /// **'Download Backup with Attachments'**
  String get loadingErrorDownloadBundle;

  /// Subtitle of the entry that exports the latest backup with attachments on the load error page.
  ///
  /// In en, this message translates to:
  /// **'Latest backup and attachment files as ZIP bundle'**
  String get loadingErrorDownloadBundleSubtitle;

  /// App bar button that skips the onboarding.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// App bar button of the rider slide that moves on without entering a name.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingNotNow;

  /// Button that moves to the next onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Button that saves the rider name, or finishes onboarding for subscribers.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// Button on the last onboarding slide that finishes onboarding without subscribing.
  ///
  /// In en, this message translates to:
  /// **'Continue free'**
  String get onboardingContinueFree;

  /// Screen reader label of the onboarding progress dots. {current} is the 1-based slide, {total} the slide count.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepOfTotal(int current, int total);

  /// Uppercase badge above the title of the teaching onboarding slides. {step} is the number.
  ///
  /// In en, this message translates to:
  /// **'STEP {step}'**
  String onboardingStepBadge(int step);

  /// Title of the first onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Ready to Dial It In?'**
  String get onboardingSlide1Title;

  /// Body of the first onboarding slide. <i>…</i> marks the italic app name.
  ///
  /// In en, this message translates to:
  /// **'Stop guessing your settings. Start tracking!\nFind your perfect setup with <i>Bike Setup Tracker.</i>'**
  String get onboardingSlide1Body;

  /// Title of the second onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Build Your Bike'**
  String get onboardingSlide2Title;

  /// Body of the second onboarding slide. <b>…</b> marks bold words.
  ///
  /// In en, this message translates to:
  /// **'Add your <b>bikes</b> and their <b>components</b> that you want to track. Create a perfect digital twin of your real-world garage.'**
  String get onboardingSlide2Body;

  /// Title of the third onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Virtual Dials for Physical Knobs'**
  String get onboardingSlide3Title;

  /// Body of the third onboarding slide. <b>…</b> marks bold words.
  ///
  /// In en, this message translates to:
  /// **'Every component is built from a few simple <b>Adjustments</b>. This modular design lets you track anything. <b>Adjustments</b> define the rules—like limits and units—not the actual values.'**
  String get onboardingSlide3Body;

  /// Title of the fourth onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Your Setup Diary'**
  String get onboardingSlide4Title;

  /// Body of the fourth onboarding slide. <b>…</b> marks bold words.
  ///
  /// In en, this message translates to:
  /// **'A <b>Setup</b> is a current snapshot of all components of one bike. It captures the specific <b>values</b> of your adjustments and automatically adds context (e.g. location, weather, trail conditions).'**
  String get onboardingSlide4Body;

  /// Title of the onboarding slide that asks for the rider name.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onboardingRiderTitle;

  /// Subtitle of the onboarding slide that asks for the rider name.
  ///
  /// In en, this message translates to:
  /// **'You can change it any time.'**
  String get onboardingRiderBody;

  /// Confirmation after the rider name was saved. {name} is the rider name.
  ///
  /// In en, this message translates to:
  /// **'Nice to meet you, {name}!'**
  String onboardingRiderGreeting(String name);

  /// Title of the last onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Free by default'**
  String get onboardingFreeTitle;

  /// Subtitle of the last onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'One optional add-on. Everything else is included, permanently.'**
  String get onboardingFreeBody;

  /// Uppercase heading of the list of free features.
  ///
  /// In en, this message translates to:
  /// **'FREE FOREVER'**
  String get onboardingFreeSection;

  /// Uppercase heading of the list of Strava Sync features.
  ///
  /// In en, this message translates to:
  /// **'OPTIONAL: STRAVA SYNC'**
  String get onboardingStravaSection;

  /// First free feature on the last onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'As many bikes, components and setups as you want'**
  String get onboardingFreeFeature1;

  /// Second free feature on the last onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Custom adjustments, with weather and location on every setup'**
  String get onboardingFreeFeature2;

  /// Third free feature on the last onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Tasks, calendar and installation history'**
  String get onboardingFreeFeature3;

  /// Fourth free feature on the last onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel, CSV or JSON — your data stays yours'**
  String get onboardingFreeFeature4;

  /// First Strava Sync feature on the last onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Setups matched to the rides you actually rode — available in map and calendar'**
  String get onboardingStravaFeature1;

  /// Second Strava Sync feature on the last onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Ridden distance and time stats per bike and component'**
  String get onboardingStravaFeature2;

  /// Third Strava Sync feature on the last onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Maintenance reminders based on your riding activity'**
  String get onboardingStravaFeature3;

  /// Button on the last onboarding slide for subscribers who are connected to Strava.
  ///
  /// In en, this message translates to:
  /// **'Open Strava Sync'**
  String get onboardingStravaOpen;

  /// Button on the last onboarding slide for subscribers who are not connected to Strava yet.
  ///
  /// In en, this message translates to:
  /// **'Connect Strava'**
  String get onboardingStravaConnect;

  /// Button on the last onboarding slide while the store offers are not known yet.
  ///
  /// In en, this message translates to:
  /// **'Explore Strava Sync'**
  String get onboardingStravaExplore;

  /// Button on the last onboarding slide that opens the Strava Sync paywall when a free trial is available.
  ///
  /// In en, this message translates to:
  /// **'Start 7-day free trial'**
  String get onboardingStravaTrial;

  /// Button on the last onboarding slide that opens the Strava Sync paywall when there is no free trial.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get onboardingStravaSubscribe;

  /// Name of the example component on the onboarding slides.
  ///
  /// In en, this message translates to:
  /// **'Suspension Fork'**
  String get onboardingExampleFork;

  /// Name of the example pressure adjustment on the onboarding slides.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get onboardingExamplePressure;

  /// Name of the example rebound adjustment on the onboarding slides.
  ///
  /// In en, this message translates to:
  /// **'Rebound'**
  String get onboardingExampleRebound;

  /// Name of the example lockout adjustment on the onboarding slides.
  ///
  /// In en, this message translates to:
  /// **'Lockout'**
  String get onboardingExampleLockout;

  /// Type caption of the example pressure adjustment on the onboarding slides.
  ///
  /// In en, this message translates to:
  /// **'Numerical Adjustment'**
  String get onboardingExampleNumericalType;

  /// Detail line of the example pressure adjustment.
  ///
  /// In en, this message translates to:
  /// **'in PSI'**
  String get onboardingExampleNumericalDetail;

  /// Type caption of the example rebound adjustment on the onboarding slides.
  ///
  /// In en, this message translates to:
  /// **'Step Adjustment'**
  String get onboardingExampleStepType;

  /// Detail line of the example rebound adjustment.
  ///
  /// In en, this message translates to:
  /// **'0 to 12 Clicks'**
  String get onboardingExampleStepDetail;

  /// Type caption of the example lockout adjustment on the onboarding slides.
  ///
  /// In en, this message translates to:
  /// **'On/Off Adjustment'**
  String get onboardingExampleBooleanType;

  /// Detail line of the example lockout adjustment.
  ///
  /// In en, this message translates to:
  /// **'Open or Firm'**
  String get onboardingExampleBooleanDetail;

  /// Name of the setup being recorded on the fourth onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'My new Setup'**
  String get onboardingExampleNewSetup;

  /// Name of the first older example setup on the fourth onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Enduro Day'**
  String get onboardingExampleSetupEnduro;

  /// Name of the second older example setup on the fourth onboarding slide.
  ///
  /// In en, this message translates to:
  /// **'Bikepark Day'**
  String get onboardingExampleSetupBikepark;

  /// App bar title of the settings page.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Title of the settings entry that opens the store's subscription page.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get settingsManageSubscription;

  /// Subtitle of the settings entry that opens the store's subscription page.
  ///
  /// In en, this message translates to:
  /// **'Cancel or change your plan in the store'**
  String get settingsManageSubscriptionSubtitle;

  /// Title of the settings entry that disconnects Strava.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Strava'**
  String get settingsDisconnectStrava;

  /// Subtitle of the settings entry that disconnects Strava.
  ///
  /// In en, this message translates to:
  /// **'Revoke access and delete synced activities'**
  String get settingsDisconnectStravaSubtitle;

  /// Title of the settings entry and sheet for Strava push notifications.
  ///
  /// In en, this message translates to:
  /// **'Strava Notifications'**
  String get settingsStravaNotifications;

  /// Explanation in the Strava notifications sheet.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications when Strava activities are imported.'**
  String get settingsStravaNotificationsInfo;

  /// Title of the settings entry that opens the preferences page.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// Subtitle of the settings entry that opens the preferences page.
  ///
  /// In en, this message translates to:
  /// **'Appearance, formats and units'**
  String get settingsPreferencesSubtitle;

  /// Title of the settings entry that opens the features page.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get settingsFeatures;

  /// Subtitle of the settings entry that opens the features page.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable optional functionality'**
  String get settingsFeaturesSubtitle;

  /// Title of the settings entry that opens the attachments page.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get settingsAttachments;

  /// Subtitle of the settings entry that opens the attachments page.
  ///
  /// In en, this message translates to:
  /// **'Images and files from setups, bikes, components and tasks'**
  String get settingsAttachmentsSubtitle;

  /// Title of the settings entry that opens the about page.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Subtitle of the settings entry that opens the about page.
  ///
  /// In en, this message translates to:
  /// **'Version, privacy policy and agreements'**
  String get settingsAboutSubtitle;

  /// Title of the settings entry that opens the help page.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// Subtitle of the settings entry that opens the help page.
  ///
  /// In en, this message translates to:
  /// **'FAQ, onboarding and contact'**
  String get settingsHelpSubtitle;

  /// Title of the settings entry that opens the reset page.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsReset;

  /// Subtitle of the settings entry that opens the reset page.
  ///
  /// In en, this message translates to:
  /// **'Reset settings, delete backups or clear data'**
  String get settingsResetSubtitle;

  /// App bar title of the preferences page.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesTitle;

  /// Section heading of the appearance preferences.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get preferencesSectionAppearance;

  /// Title of the preference and sheet that picks light, dark or system theme.
  ///
  /// In en, this message translates to:
  /// **'App Theme Mode'**
  String get preferencesThemeMode;

  /// Theme choice that follows the device setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get preferencesThemeSystem;

  /// Theme choice for the light theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get preferencesThemeLight;

  /// Theme choice for the dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get preferencesThemeDark;

  /// Title of the preference and sheet that picks the app language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get preferencesLanguage;

  /// Language choice that follows the device language.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get preferencesLanguageSystem;

  /// Section heading of the filter preferences.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get preferencesSectionFilters;

  /// Title of the preference and sheet that keeps filters across app starts.
  ///
  /// In en, this message translates to:
  /// **'Remember Filters'**
  String get preferencesRememberFilters;

  /// Explanation in the Remember Filters sheet.
  ///
  /// In en, this message translates to:
  /// **'Keep the selected bike and filters when reopening the app. Date ranges are not kept.'**
  String get preferencesRememberFiltersInfo;

  /// Section heading of the format preferences.
  ///
  /// In en, this message translates to:
  /// **'Default Formats'**
  String get preferencesSectionFormats;

  /// Title of the preference and sheet that picks the date format.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get preferencesDateFormat;

  /// Title of the preference and sheet that picks the time format.
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get preferencesTimeFormat;

  /// Section heading of the unit preferences.
  ///
  /// In en, this message translates to:
  /// **'Default Units'**
  String get preferencesSectionUnits;

  /// Title of the preference and sheet that picks the distance unit.
  ///
  /// In en, this message translates to:
  /// **'Distance Unit'**
  String get preferencesDistanceUnit;

  /// Title of the preference and sheet that picks the altitude unit.
  ///
  /// In en, this message translates to:
  /// **'Altitude Unit'**
  String get preferencesAltitudeUnit;

  /// Title of the preference and sheet that picks the temperature unit.
  ///
  /// In en, this message translates to:
  /// **'Temperature Unit'**
  String get preferencesTemperatureUnit;

  /// Title of the preference and sheet that picks the wind speed unit.
  ///
  /// In en, this message translates to:
  /// **'Wind Speed Unit'**
  String get preferencesWindSpeedUnit;

  /// Title of the preference and sheet that picks the precipitation unit.
  ///
  /// In en, this message translates to:
  /// **'Precipitation Unit'**
  String get preferencesPrecipitationUnit;

  /// Temperature unit choice.
  ///
  /// In en, this message translates to:
  /// **'Celsius (°C)'**
  String get preferencesUnitCelsius;

  /// Temperature unit choice.
  ///
  /// In en, this message translates to:
  /// **'Fahrenheit (°F)'**
  String get preferencesUnitFahrenheit;

  /// Temperature unit choice.
  ///
  /// In en, this message translates to:
  /// **'Kelvin (K)'**
  String get preferencesUnitKelvin;

  /// Wind speed unit choice.
  ///
  /// In en, this message translates to:
  /// **'Kilometers per hour (km/h)'**
  String get preferencesUnitKmh;

  /// Wind speed unit choice.
  ///
  /// In en, this message translates to:
  /// **'Miles per hour (mph)'**
  String get preferencesUnitMph;

  /// Wind speed unit choice.
  ///
  /// In en, this message translates to:
  /// **'Meters per second (m/s)'**
  String get preferencesUnitMs;

  /// Wind speed unit choice.
  ///
  /// In en, this message translates to:
  /// **'Knots (kt)'**
  String get preferencesUnitKnots;

  /// Distance unit choice.
  ///
  /// In en, this message translates to:
  /// **'Kilometers (km)'**
  String get preferencesUnitKilometers;

  /// Distance unit choice.
  ///
  /// In en, this message translates to:
  /// **'Miles (mi)'**
  String get preferencesUnitMiles;

  /// Altitude unit choice.
  ///
  /// In en, this message translates to:
  /// **'Meters (m)'**
  String get preferencesUnitMeters;

  /// Altitude unit choice.
  ///
  /// In en, this message translates to:
  /// **'Feet (ft)'**
  String get preferencesUnitFeet;

  /// Precipitation unit choice.
  ///
  /// In en, this message translates to:
  /// **'Millimeters (mm)'**
  String get preferencesUnitMillimeters;

  /// Precipitation unit choice.
  ///
  /// In en, this message translates to:
  /// **'Inches (in)'**
  String get preferencesUnitInches;

  /// App bar title of the features page.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get featuresTitle;

  /// Introduction at the top of the features page.
  ///
  /// In en, this message translates to:
  /// **'Enable these to add specific functionality to your workflow. Keep them disabled to maintain a simpler interface.'**
  String get featuresIntro;

  /// Section heading of the component features.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get featuresSectionComponents;

  /// Section heading of the adjustment features.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get featuresSectionAdjustments;

  /// Section heading of the setup features.
  ///
  /// In en, this message translates to:
  /// **'Setups'**
  String get featuresSectionSetups;

  /// Section heading of the setup history features.
  ///
  /// In en, this message translates to:
  /// **'Setup History'**
  String get featuresSectionSetupHistory;

  /// Section heading of the task features.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get featuresSectionTasks;

  /// Section heading of the remaining features.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get featuresSectionOther;

  /// Title of the installation timeline feature.
  ///
  /// In en, this message translates to:
  /// **'Installation Timeline'**
  String get featuresInstallationTimeline;

  /// Title of the subcomponents feature.
  ///
  /// In en, this message translates to:
  /// **'Subcomponents'**
  String get featuresSubcomponents;

  /// Title of the component presets feature (developer builds).
  ///
  /// In en, this message translates to:
  /// **'Component Presets'**
  String get featuresComponentPresets;

  /// Subtitle of a disabled feature that depends on component presets.
  ///
  /// In en, this message translates to:
  /// **'Requires Component Presets'**
  String get featuresRequiresComponentPresets;

  /// Subtitle of a disabled feature that depends on tasks.
  ///
  /// In en, this message translates to:
  /// **'Requires Tasks'**
  String get featuresRequiresTasks;

  /// Subtitle of a disabled feature that depends on the task interval feature.
  ///
  /// In en, this message translates to:
  /// **'Requires Task Interval'**
  String get featuresRequiresTaskInterval;

  /// Title of the task presets feature (developer builds).
  ///
  /// In en, this message translates to:
  /// **'Task Presets'**
  String get featuresTaskPresets;

  /// Intro of the component presets settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Set up a fork or shock in seconds: pick the model from the built-in catalog instead of entering every adjustment by hand.'**
  String get presetsComponentIntro;

  /// First step of the component presets settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Add a fork or shock and search for its model and year, e.g. \"Fox 36\".'**
  String get presetsComponentStepSearch;

  /// Second step of the component presets settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Name, notes and adjustments are filled in: rebound and compression with their click ranges, air pressure and SAG.'**
  String get presetsComponentStepFilled;

  /// Third step of the component presets settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Already have the component? Link the model on its edit page and choose whether its adjustments merge with yours or replace them.'**
  String get presetsComponentStepLink;

  /// Footnote of the component presets settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Covers forks and shocks from FOX, RockShox, Öhlins and other brands. Everything stays editable. Turning this off hides the catalog; your components keep their adjustments.'**
  String get presetsComponentCaption;

  /// Intro of the task presets settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Get recommended maintenance tasks for your components, like a chain wear check or a fork service.'**
  String get presetsTaskIntro;

  /// First step of the task presets settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Whenever you add, duplicate or replace a component, its recommended tasks are offered. Pick the ones you want.'**
  String get presetsTaskStepOffered;

  /// Second step of the task presets settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Adding a task for a component? Tap a suggestion to fill in its name, notes and interval.'**
  String get presetsTaskStepSuggestion;

  /// Third step of the task presets settings sheet.
  ///
  /// In en, this message translates to:
  /// **'With Strava connected, intervals follow your rides, like distance or riding time. Without it, they are time-based. Catalog forks and shocks use the manufacturer’s service intervals.'**
  String get presetsTaskStepStrava;

  /// Footnote of the task presets settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Covers chains, cassettes, forks, shocks, brakes, tires, headsets, bottom brackets, seatposts, frames and shift cables. Added tasks are normal tasks you can edit or delete.'**
  String get presetsTaskCaption;

  /// Title of the setup guides feature (developer builds).
  ///
  /// In en, this message translates to:
  /// **'Setup Guides'**
  String get featuresSetupGuides;

  /// Explanation of the setup guides feature.
  ///
  /// In en, this message translates to:
  /// **'Suggests recommended values for the first setup of a component, like air pressure or rebound clicks, based on your riding weight and the component model. These are starting points, so check the manufacturer manual. Requires Component Presets.'**
  String get featuresSetupGuidesInfo;

  /// Title of the group of categorical adjustment features.
  ///
  /// In en, this message translates to:
  /// **'Categorical Adjustment'**
  String get featuresCategoricalAdjustment;

  /// Explanation of the categorical adjustment feature group.
  ///
  /// In en, this message translates to:
  /// **'Extra options for Categorical Adjustments. Each can be toggled on its own.'**
  String get featuresCategoricalAdjustmentInfo;

  /// Title of the multi-select option.
  ///
  /// In en, this message translates to:
  /// **'Multi-select'**
  String get featuresMultiSelect;

  /// Description of the multi-select option.
  ///
  /// In en, this message translates to:
  /// **'Allow selecting multiple categories instead of only one.'**
  String get featuresMultiSelectSubtitle;

  /// Title of the counted-select option.
  ///
  /// In en, this message translates to:
  /// **'Count occurrences'**
  String get featuresCountOccurrences;

  /// Description of the counted-select option.
  ///
  /// In en, this message translates to:
  /// **'Record how many times each category is selected.'**
  String get featuresCountOccurrencesSubtitle;

  /// Title of the text adjustment feature.
  ///
  /// In en, this message translates to:
  /// **'Text Adjustment'**
  String get featuresTextAdjustment;

  /// Explanation of the text adjustment feature.
  ///
  /// In en, this message translates to:
  /// **'Adds a Text Adjustment type that provides a free-form text field.'**
  String get featuresTextAdjustmentInfo;

  /// Title of the setup tags feature.
  ///
  /// In en, this message translates to:
  /// **'Setup Tags'**
  String get featuresSetupTags;

  /// Title of the setup tags and bookmarks feature group (developer builds).
  ///
  /// In en, this message translates to:
  /// **'Setup Tags & Bookmarks'**
  String get featuresSetupTagsAndBookmarks;

  /// Explanation of the setup tags feature group.
  ///
  /// In en, this message translates to:
  /// **'Extra ways to organize and annotate Setups. Each can be toggled on its own.'**
  String get featuresSetupTagsInfo;

  /// Title of the option that adds tags to setups.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get featuresSetupTagsTags;

  /// Description of the option that adds tags to setups.
  ///
  /// In en, this message translates to:
  /// **'Adds the option to add tags to Setups.'**
  String get featuresSetupTagsTagsSubtitle;

  /// Title of the option that bookmarks setups (developer builds).
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get featuresSetupBookmarks;

  /// Description of the option that bookmarks setups.
  ///
  /// In en, this message translates to:
  /// **'Mark good setups with a bookmark so they stand out among all the setups you record. Bookmarks are stored with the setup and are included in backups and exports.'**
  String get featuresSetupBookmarksSubtitle;

  /// Title of the pressure check feature (developer builds).
  ///
  /// In en, this message translates to:
  /// **'Pressure Check'**
  String get featuresPressureCheck;

  /// Subtitle of the pressure check entry while it is on. {percent} is the threshold, {types} the summary of component types.
  ///
  /// In en, this message translates to:
  /// **'On · {percent} % · {types}'**
  String featuresPressureCheckOn(int percent, String types);

  /// Title of the feedback feature (developer builds).
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get featuresFeedback;

  /// Title of the rider feature.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get featuresRider;

  /// Explanation of the rider feature.
  ///
  /// In en, this message translates to:
  /// **'Adds a rider profile, opened with the rider button in the app bar. Link the rider to your bikes to record riding weight and other rider attributes with each setup. A new rider starts with a \"Riding weight\" attribute. Turning this off hides the rider but keeps its data.'**
  String get featuresRiderInfo;

  /// Title of the advanced rider layout feature (developer builds).
  ///
  /// In en, this message translates to:
  /// **'Advanced Rider Layout'**
  String get featuresRiderAdvanced;

  /// Explanation of the advanced rider layout feature.
  ///
  /// In en, this message translates to:
  /// **'Restores the multi-rider UI: a Riders tab with reorder and bike filter, Duplicate, the rider details page and the Strava athlete link.'**
  String get featuresRiderAdvancedInfo;

  /// Title of the test session goal feature (developer builds).
  ///
  /// In en, this message translates to:
  /// **'Test Session Goal'**
  String get featuresTestSessionGoal;

  /// Explanation of the test session goal feature.
  ///
  /// In en, this message translates to:
  /// **'Adds an optional goal to the test session form: what should get better. Each run then asks if it did.'**
  String get featuresTestSessionGoalInfo;

  /// Title of the group of timeline grouping features.
  ///
  /// In en, this message translates to:
  /// **'Timeline Grouping'**
  String get featuresTimelineGrouping;

  /// Explanation of the timeline grouping feature group.
  ///
  /// In en, this message translates to:
  /// **'Controls how the Setup History timeline condenses related entries. Each pass can be toggled on its own.'**
  String get featuresTimelineGroupingInfo;

  /// Title of the option that merges setups recorded close together.
  ///
  /// In en, this message translates to:
  /// **'Setup Grouping'**
  String get featuresSetupGrouping;

  /// Description of the setup grouping option.
  ///
  /// In en, this message translates to:
  /// **'Merge setups of the same bike recorded close together.'**
  String get featuresSetupGroupingSubtitle;

  /// Title of the option that merges a removal and its replacement.
  ///
  /// In en, this message translates to:
  /// **'Replacement Detection'**
  String get featuresReplacementDetection;

  /// Description of the replacement detection option.
  ///
  /// In en, this message translates to:
  /// **'Show a removal and the install replacing it as one entry.'**
  String get featuresReplacementDetectionSubtitle;

  /// Title of the option that links entries to Strava activities.
  ///
  /// In en, this message translates to:
  /// **'Strava Context'**
  String get featuresStravaContext;

  /// Description of the Strava context option.
  ///
  /// In en, this message translates to:
  /// **'Mark entries recorded during a ride as part of that activity.'**
  String get featuresStravaContextSubtitle;

  /// Description of the Strava context option while there is no Strava subscription.
  ///
  /// In en, this message translates to:
  /// **'Mark entries recorded during a ride as part of that activity. Needs a connected Strava subscription.'**
  String get featuresStravaContextNeedsSubscription;

  /// Title of the calendar feature.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get featuresCalendar;

  /// Explanation of the calendar feature.
  ///
  /// In en, this message translates to:
  /// **'Adds a calendar view, reachable from the Setup History page via the calendar button next to search and map buttons.'**
  String get featuresCalendarInfo;

  /// Title of the advanced filters feature.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get featuresAdvancedFilters;

  /// Explanation of the advanced filters feature.
  ///
  /// In en, this message translates to:
  /// **'Adds a date range and, with Strava connected, activity distance and elevation filters to the filter sheet of the Setup History, map and calendar.'**
  String get featuresAdvancedFiltersInfo;

  /// Title of the tasks feature.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get featuresTasks;

  /// Explanation of the tasks feature.
  ///
  /// In en, this message translates to:
  /// **'Plan and track anything from recurring maintenance like fork services and chain cleaning to setup experiments like suspension testing or trying different handlebar widths. Keep a complete log of your goals and achievements in one place.'**
  String get featuresTasksInfo;

  /// Title of the group of extra task features.
  ///
  /// In en, this message translates to:
  /// **'Task Tags, Priority, Interval & Delay'**
  String get featuresTaskExtras;

  /// Explanation of the extra task features group.
  ///
  /// In en, this message translates to:
  /// **'Extra fields and behaviors for Tasks. Each can be toggled on its own.'**
  String get featuresTaskExtrasInfo;

  /// Title of the option that adds tags to task rules.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get featuresTaskTags;

  /// Description of the option that adds tags to task rules.
  ///
  /// In en, this message translates to:
  /// **'Adds the option to add tags to Task Rules.'**
  String get featuresTaskTagsSubtitle;

  /// Title of the option that shows the priority of tasks.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get featuresTaskPriority;

  /// Description of the task priority option.
  ///
  /// In en, this message translates to:
  /// **'Shows the Priority field on tasks. Disable to simplify the task interface.'**
  String get featuresTaskPrioritySubtitle;

  /// Title of the option that adds intervals to tasks.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get featuresTaskInterval;

  /// Description of the task interval option.
  ///
  /// In en, this message translates to:
  /// **'Adds an optional trigger to tasks with a progress bar based on time or, with Strava connected, activity stats like distance, elevation and ride time.'**
  String get featuresTaskIntervalSubtitle;

  /// Title of the option that lets tasks be postponed.
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get featuresTaskDelay;

  /// Description of the task delay option.
  ///
  /// In en, this message translates to:
  /// **'Lets you postpone when a task becomes due, without changing its interval. A delay only applies once: completing the task clears it automatically.'**
  String get featuresTaskDelaySubtitle;

  /// Title of the task due prediction feature.
  ///
  /// In en, this message translates to:
  /// **'Task Due Prediction'**
  String get featuresTaskDuePrediction;

  /// Explanation of the task due prediction feature.
  ///
  /// In en, this message translates to:
  /// **'Estimates when a task will come due. For date and duration intervals, this is calculated directly from the last completion, no Strava needed. For other intervals (distance, elevation, ride time, ...), it extrapolates from how much the bike has been ridden recently and needs a connected Strava subscription. Only shows for tasks that are not due yet.'**
  String get featuresTaskDuePredictionInfo;

  /// Title of the garage task indicator feature.
  ///
  /// In en, this message translates to:
  /// **'Garage Task Indicator'**
  String get featuresGarageTaskIndicator;

  /// Explanation of the garage task indicator feature.
  ///
  /// In en, this message translates to:
  /// **'Shows a colored status dot on component icons in the Garage when they have open tasks.'**
  String get featuresGarageTaskIndicatorInfo;

  /// Title of the attachments feature.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get featuresAttachments;

  /// Explanation of the attachments feature, including the warning that they are not backed up.
  ///
  /// In en, this message translates to:
  /// **'Attach images and files to bikes, components, setups and tasks. WARNING: attachments are stored only on this device. They are NOT included in cloud/Drive backups and will be lost on reinstall or when restoring from a backup. Use \"Export Attachment Bundle\" to move them to a new device.'**
  String get featuresAttachmentsInfo;

  /// Title of the Google Drive sync feature.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync'**
  String get featuresGoogleDrive;

  /// Explanation of the Google Drive sync feature.
  ///
  /// In en, this message translates to:
  /// **'Sync your data across devices and keep secure backups in your Google Drive. Your data is stored privately in your own account; we never have access to it.'**
  String get featuresGoogleDriveInfo;

  /// Title of the MapBox tiles feature (developer builds).
  ///
  /// In en, this message translates to:
  /// **'MapBox Tiles'**
  String get featuresMapBoxTiles;

  /// App bar title of the about page.
  ///
  /// In en, this message translates to:
  /// **'About & Legal'**
  String get aboutTitle;

  /// Section heading of the version information on the about page.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get aboutSectionInformation;

  /// Label of the app version on the about page.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// Label of the release date on the about page.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get aboutReleaseDate;

  /// Label of the anonymous user ID on the about page.
  ///
  /// In en, this message translates to:
  /// **'User UID'**
  String get aboutUserUid;

  /// Shown instead of the user ID while there is none.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get aboutUserUidUnavailable;

  /// Tooltip of the button that copies the user ID.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get aboutCopy;

  /// Snackbar after the user ID was copied.
  ///
  /// In en, this message translates to:
  /// **'User UID copied'**
  String get aboutUserUidCopied;

  /// Section heading of the legal links on the about page.
  ///
  /// In en, this message translates to:
  /// **'Legal Agreements'**
  String get aboutSectionLegal;

  /// Title of the link to the privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutPrivacyPolicy;

  /// Title of the link to the license agreement.
  ///
  /// In en, this message translates to:
  /// **'End-User License Agreement (EULA)'**
  String get aboutEula;

  /// Title of the link to the terms of service.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get aboutTermsOfService;

  /// Title of the entry that opens the open-source license page.
  ///
  /// In en, this message translates to:
  /// **'Open-Source Licenses'**
  String get aboutLicenses;

  /// Copyright line on the open-source license page.
  ///
  /// In en, this message translates to:
  /// **'© 2025-2026 Jonas Keller. All rights reserved.'**
  String get aboutLegalese;

  /// Title of the entry that lists third-party trademarks.
  ///
  /// In en, this message translates to:
  /// **'Third-party trademarks'**
  String get aboutTrademarks;

  /// Trademark notice when Strava is enabled.
  ///
  /// In en, this message translates to:
  /// **'Strava is a trademark of Strava, Inc.\nGoogle Drive is a trademark of Google LLC.'**
  String get aboutTrademarksStravaAndDrive;

  /// Trademark notice when Strava is not enabled.
  ///
  /// In en, this message translates to:
  /// **'Google Drive is a trademark of Google LLC.'**
  String get aboutTrademarksDrive;

  /// App bar title of the attachments page.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachmentsTitle;

  /// Title of the error state when the attachments folder cannot be read.
  ///
  /// In en, this message translates to:
  /// **'Attachments unavailable'**
  String get attachmentsUnavailableTitle;

  /// Subtitle of the error state when the attachments folder cannot be read.
  ///
  /// In en, this message translates to:
  /// **'The attachments folder could not be opened.'**
  String get attachmentsUnavailableSubtitle;

  /// Title of the empty state of the attachments page.
  ///
  /// In en, this message translates to:
  /// **'No attachments yet'**
  String get attachmentsEmptyTitle;

  /// Subtitle of the empty state of the attachments page.
  ///
  /// In en, this message translates to:
  /// **'Images and files you add to a setup, bike, component or task appear here.'**
  String get attachmentsEmptySubtitle;

  /// Warning above the attachment grid. {count} is the number of unlinked attachments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment is no longer linked to a setup, bike, component or task. It is removed the next time the app starts.} other{{count} attachments are no longer linked to a setup, bike, component or task. They are removed the next time the app starts.}}'**
  String attachmentsUnlinkedHint(int count);

  /// App bar title of the help page.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpTitle;

  /// Section heading of the help entries.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpSectionHelp;

  /// Title of the entry that replays the onboarding.
  ///
  /// In en, this message translates to:
  /// **'Show Onboarding'**
  String get helpShowOnboarding;

  /// Subtitle of the entry that replays the onboarding.
  ///
  /// In en, this message translates to:
  /// **'Show onboarding slides to get started.'**
  String get helpShowOnboardingSubtitle;

  /// Title of the entry that opens the FAQ.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get helpFaq;

  /// Subtitle of the entry that opens the FAQ.
  ///
  /// In en, this message translates to:
  /// **'Show frequently asked questions.'**
  String get helpFaqSubtitle;

  /// Title of the link to the Strava club forum.
  ///
  /// In en, this message translates to:
  /// **'Strava Club Forum'**
  String get helpStravaForum;

  /// Subtitle of the link to the Strava club forum.
  ///
  /// In en, this message translates to:
  /// **'Get help and discuss the app with other users.'**
  String get helpStravaForumSubtitle;

  /// Section heading of the contact entries.
  ///
  /// In en, this message translates to:
  /// **'Contact & Feedback'**
  String get helpSectionContact;

  /// Title of the entry that opens the tip jar.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get helpCoffee;

  /// Subtitle of the entry that opens the tip jar.
  ///
  /// In en, this message translates to:
  /// **'Support development with a small tip.'**
  String get helpCoffeeSubtitle;

  /// Title of the entry that opens the store page to rate the app.
  ///
  /// In en, this message translates to:
  /// **'Rate this app'**
  String get helpRate;

  /// Subtitle of the rate entry on iOS.
  ///
  /// In en, this message translates to:
  /// **'Rate this app on Apple AppStore.'**
  String get helpRateAppStore;

  /// Subtitle of the rate entry on Android.
  ///
  /// In en, this message translates to:
  /// **'Rate this app on Google PlayStore.'**
  String get helpRatePlayStore;

  /// Title of the entry that emails support.
  ///
  /// In en, this message translates to:
  /// **'General Support'**
  String get helpGeneralSupport;

  /// Title of the entry that emails a feature suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggest Features'**
  String get helpSuggestFeatures;

  /// Title of the entry that emails a bug report.
  ///
  /// In en, this message translates to:
  /// **'Report Bugs'**
  String get helpReportBugs;

  /// App bar title of the reset page.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetTitle;

  /// Title of the entry that resets all settings.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettings;

  /// Subtitle of the reset settings entry while nothing was changed.
  ///
  /// In en, this message translates to:
  /// **'All settings are at their defaults'**
  String get resetSettingsDefaults;

  /// Subtitle of the reset settings entry while settings were changed.
  ///
  /// In en, this message translates to:
  /// **'Restore all preferences and features to their defaults'**
  String get resetSettingsRestore;

  /// Title of the entry that deletes the automatic backups.
  ///
  /// In en, this message translates to:
  /// **'Delete All Backups'**
  String get resetDeleteBackups;

  /// Subtitle of the entry that deletes the automatic backups.
  ///
  /// In en, this message translates to:
  /// **'Remove all automatic backups stored on this device'**
  String get resetDeleteBackupsSubtitle;

  /// Subtitle of the delete backups entry while there are no backups.
  ///
  /// In en, this message translates to:
  /// **'No backups on this device'**
  String get resetNoBackups;

  /// Title of the entry that deletes all data.
  ///
  /// In en, this message translates to:
  /// **'Clear Database'**
  String get resetClearDatabase;

  /// Subtitle of the entry that deletes all data.
  ///
  /// In en, this message translates to:
  /// **'Delete all bikes, components, setups and other data'**
  String get resetClearDatabaseSubtitle;

  /// Subtitle of the clear database entry while there is no data.
  ///
  /// In en, this message translates to:
  /// **'The database is empty'**
  String get resetDatabaseEmpty;

  /// App bar title of the FAQ page.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked Questions'**
  String get faqTitle;

  /// Heading of the general FAQ section.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get faqSectionGeneral;

  /// Heading of the FAQ section about bikes and components.
  ///
  /// In en, this message translates to:
  /// **'Bikes'**
  String get faqSectionBikes;

  /// Heading of the FAQ section about setups.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get faqSectionSetup;

  /// Heading of the FAQ section about the rider.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get faqSectionRider;

  /// Heading of the FAQ section about Strava Sync.
  ///
  /// In en, this message translates to:
  /// **'Strava Sync'**
  String get faqSectionStrava;

  /// Heading of the FAQ section about tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get faqSectionTasks;

  /// Question of the FAQ entry "GeneralAbout".
  ///
  /// In en, this message translates to:
  /// **'What is this app about?'**
  String get faqGeneralAboutQuestion;

  /// Answer of the FAQ entry "GeneralAbout".
  ///
  /// In en, this message translates to:
  /// **'This app helps you track, manage, and optimize your bike setup adjustments for better performance.'**
  String get faqGeneralAboutAnswer;

  /// Question of the FAQ entry "GeneralExport".
  ///
  /// In en, this message translates to:
  /// **'Can I export or share my data?'**
  String get faqGeneralExportQuestion;

  /// Answer of the FAQ entry "GeneralExport".
  ///
  /// In en, this message translates to:
  /// **'Yes. Use \"Export\" to save your entire database as a JSON file. You choose where to save it in your device’s file picker. This file is intended for backups and can be reimported later. \n\nUse \"Share\" to send a snapshot of your data directly to another app (like Mail, Cloud, or Messenger). You can choose between multiple formats: JSON (reimportable), Excel, CSV, or plain text.'**
  String get faqGeneralExportAnswer;

  /// Question of the FAQ entry "GeneralLocal".
  ///
  /// In en, this message translates to:
  /// **'Is my data stored locally?'**
  String get faqGeneralLocalQuestion;

  /// Answer of the FAQ entry "GeneralLocal".
  ///
  /// In en, this message translates to:
  /// **'Yes, all your data is stored locally on your device. We do not collect or store any of your personal information.'**
  String get faqGeneralLocalAnswer;

  /// Question of the FAQ entry "GeneralRecover".
  ///
  /// In en, this message translates to:
  /// **'I accidentally deleted something. Can I recover it?'**
  String get faqGeneralRecoverQuestion;

  /// Answer of the FAQ entry "GeneralRecover".
  ///
  /// In en, this message translates to:
  /// **'Yes. Open the menu in the top-right corner of the home page and select \"Trash.\" You can restore items deleted within the last 30 days. After 30 days, items are permanently deleted.'**
  String get faqGeneralRecoverAnswer;

  /// Question of the FAQ entry "GeneralMove".
  ///
  /// In en, this message translates to:
  /// **'How do I move my data to a new device?'**
  String get faqGeneralMoveQuestion;

  /// Answer of the FAQ entry "GeneralMove".
  ///
  /// In en, this message translates to:
  /// **'Data is typically restored by your operating system if you have cloud backups enabled. To move data manually: Export your data as a JSON file from the home page menu, transfer that file to your new device (via cloud or cable), and select \"Import\" from the menu on the new device.'**
  String get faqGeneralMoveAnswer;

  /// Question of the FAQ entry "BikesAdd".
  ///
  /// In en, this message translates to:
  /// **'How do I add a new bike?'**
  String get faqBikesAddQuestion;

  /// Answer of the FAQ entry "BikesAdd".
  ///
  /// In en, this message translates to:
  /// **'Tap the \"+\" button in the \"Bikes\" tab to create a new bike.'**
  String get faqBikesAddAnswer;

  /// Question of the FAQ entry "BikesComponents".
  ///
  /// In en, this message translates to:
  /// **'Where are my components?'**
  String get faqBikesComponentsQuestion;

  /// Answer of the FAQ entry "BikesComponents".
  ///
  /// In en, this message translates to:
  /// **'Components are listed directly under the bike they are installed on. Tap a component to see its details and make adjustments.'**
  String get faqBikesComponentsAnswer;

  /// Question of the FAQ entry "BikesEditDelete".
  ///
  /// In en, this message translates to:
  /// **'How do I edit or delete a component?'**
  String get faqBikesEditDeleteQuestion;

  /// Answer of the FAQ entry "BikesEditDelete".
  ///
  /// In en, this message translates to:
  /// **'Tap on a component to open its detailed view, then tap the three-dot menu in the top-right corner to edit, duplicate, or delete it.'**
  String get faqBikesEditDeleteAnswer;

  /// Question of the FAQ entry "BikesMoveComponent".
  ///
  /// In en, this message translates to:
  /// **'How do I move a component to a different bike?'**
  String get faqBikesMoveComponentQuestion;

  /// Answer of the FAQ entry "BikesMoveComponent".
  ///
  /// In en, this message translates to:
  /// **'Long-press a component and drag it onto the card of the bike you want to move it to.'**
  String get faqBikesMoveComponentAnswer;

  /// Question of the FAQ entry "BikesReorderComponents".
  ///
  /// In en, this message translates to:
  /// **'How do I reorder my components?'**
  String get faqBikesReorderComponentsQuestion;

  /// Answer of the FAQ entry "BikesReorderComponents".
  ///
  /// In en, this message translates to:
  /// **'Long-press and drag a component icon to change its position within a bike or list.'**
  String get faqBikesReorderComponentsAnswer;

  /// Question of the FAQ entry "BikesUninstalled".
  ///
  /// In en, this message translates to:
  /// **'What is the \"Uninstalled\" section?'**
  String get faqBikesUninstalledQuestion;

  /// Answer of the FAQ entry "BikesUninstalled".
  ///
  /// In en, this message translates to:
  /// **'This section at the bottom of the \"Bikes\" tab lists components that are currently not assigned to any bike. You can drag them from here onto a bike to install them.'**
  String get faqBikesUninstalledAnswer;

  /// Question of the FAQ entry "BikesUninstalledVsArchived".
  ///
  /// In en, this message translates to:
  /// **'What is the difference between \"Uninstalled\" and \"Archived\"?'**
  String get faqBikesUninstalledVsArchivedQuestion;

  /// Answer of the FAQ entry "BikesUninstalledVsArchived".
  ///
  /// In en, this message translates to:
  /// **'Both states mean a component is off the bike, but they serve different purposes.\n\n\"Uninstalled\" means the component is off the bike but still usable. It stays visible in the Uninstalled section and can be reinstalled at any time — for example, a spare wheelset you swap in for race day, or a saddle you temporarily moved to another bike.\n\n\"Archived\" means the component is retired and will never be used again. It is hidden from the main view to keep your garage clean, but all its history and statistics are preserved. Use this for worn-out brake pads or tires, broken or sold parts, or anything you no longer ride. You can still find archived components in the Archived section and restore them if needed.'**
  String get faqBikesUninstalledVsArchivedAnswer;

  /// Question of the FAQ entry "AdjustmentWhat".
  ///
  /// In en, this message translates to:
  /// **'What is an \"Adjustment\"?'**
  String get faqAdjustmentWhatQuestion;

  /// Answer of the FAQ entry "AdjustmentWhat".
  ///
  /// In en, this message translates to:
  /// **'An Adjustment defines a specific part of a component that can be modified (e.g., tire pressure or suspension rebound). It sets the rules — the type, the unit, and the allowed range — while the actual values are recorded within a \"Setup.\"'**
  String get faqAdjustmentWhatAnswer;

  /// Question of the FAQ entry "AdjustmentTypes".
  ///
  /// In en, this message translates to:
  /// **'Which adjustment types can I choose from?'**
  String get faqAdjustmentTypesQuestion;

  /// Answer of the FAQ entry "AdjustmentTypes".
  ///
  /// In en, this message translates to:
  /// **'Numerical for measured values with a unit (e.g. 22.5 psi), Step for click-based dials (e.g. rebound 8 of 15), Categorical for a fixed list of options, and On/Off for things like a lockout. Text, for free-form entries, appears once you enable it under Settings → Features → Text Adjustment.\n\nYou pick the type when adding the adjustment — it decides how you enter values in a Setup later. Above the types, the \"Add Adjustment\" sheet also suggests ready-made templates for the component you are on, which are the quickest way to get started.'**
  String get faqAdjustmentTypesAnswer;

  /// Question of the FAQ entry "AdjustmentOtherUnit".
  ///
  /// In en, this message translates to:
  /// **'Can I read or enter a value in a different unit?'**
  String get faqAdjustmentOtherUnitQuestion;

  /// Answer of the FAQ entry "AdjustmentOtherUnit".
  ///
  /// In en, this message translates to:
  /// **'Yes — tap the unit label next to the value (the small \"psi\", \"bar\", \"mm\" … text). Each tap cycles to the next compatible unit and converts the number for you. This works both when reading a setup and when typing a value into one. While a converted unit is active, a small line shows what the value is in the unit the adjustment is actually stored in.\n\nThis only changes what you see: the adjustment and the stored value stay untouched, and the display resets when you leave the page. To change the unit permanently, edit the adjustment.'**
  String get faqAdjustmentOtherUnitAnswer;

  /// Question of the FAQ entry "AdjustmentSag".
  ///
  /// In en, this message translates to:
  /// **'What is \"SAG\"?'**
  String get faqAdjustmentSagQuestion;

  /// Answer of the FAQ entry "AdjustmentSag".
  ///
  /// In en, this message translates to:
  /// **'SAG is not a type of its own — it is a special flavour of the Numerical adjustment, made for suspension sag. It is always stored as a percentage between 0 and 100 %.\n\nWhat it adds is the reference travel: fill in the \"Fork Travel\" or \"Shock Stroke\" of the component and the app can convert that percentage into an absolute length. Tap the unit label on the value to cycle % → mm → in. That way you can measure sag with a ruler on the stanchion or shock shaft and let the app do the math — in either direction.'**
  String get faqAdjustmentSagAnswer;

  /// Question of the FAQ entry "AdjustmentSagAdd".
  ///
  /// In en, this message translates to:
  /// **'How do I add a SAG adjustment?'**
  String get faqAdjustmentSagAddQuestion;

  /// Answer of the FAQ entry "AdjustmentSagAdd".
  ///
  /// In en, this message translates to:
  /// **'You will not find SAG in the list of adjustment types. Add it from the \"SAG\" template that the \"Add Adjustment\" sheet suggests for a fork or a shock, then enter the travel or stroke.\n\nIf you already track sag as a plain numerical adjustment in %, you do not have to start over: edit it, and as long as its name contains \"sag\" and its unit is %, a \"Convert to SAG adjustment\" banner appears. All recorded values and the full history stay attached, and it is reversible — on a SAG adjustment, use the three-dot menu → \"Convert to plain numerical\".'**
  String get faqAdjustmentSagAddAnswer;

  /// Question of the FAQ entry "AdjustmentChangeUnit".
  ///
  /// In en, this message translates to:
  /// **'What happens to my recorded values if I change an adjustment’s unit?'**
  String get faqAdjustmentChangeUnitQuestion;

  /// Answer of the FAQ entry "AdjustmentChangeUnit".
  ///
  /// In en, this message translates to:
  /// **'If no setup has a value recorded for the adjustment, nothing happens. Otherwise a sheet shows how many setups are affected, including deleted ones, with an example. If the old and the new unit measure the same thing (e.g. bar → psi), you choose:\n\n\"Convert values\" recalculates every previously recorded value into the new unit (10 bar becomes 145 psi). Use this when your old values were correct and you just want to read them differently.\n\n\"Keep numbers\" leaves the numbers untouched and only relabels them (10 bar becomes 10 psi). Use this when the values had been recorded in the wrong unit all along.\n\nIf the units are not compatible (e.g. psi → mm), no conversion is possible: you can keep the numbers, which are then read in the new unit, or clear the recorded values. Min and max are always kept exactly as you typed them.'**
  String get faqAdjustmentChangeUnitAnswer;

  /// Question of the FAQ entry "BikesReorderBikes".
  ///
  /// In en, this message translates to:
  /// **'How do I reorder my bikes?'**
  String get faqBikesReorderBikesQuestion;

  /// Answer of the FAQ entry "BikesReorderBikes".
  ///
  /// In en, this message translates to:
  /// **'Long-press and drag a bike card to move it up or down in the list.'**
  String get faqBikesReorderBikesAnswer;

  /// Question of the FAQ entry "SetupWhat".
  ///
  /// In en, this message translates to:
  /// **'What is a \"Setup\"?'**
  String get faqSetupWhatQuestion;

  /// Answer of the FAQ entry "SetupWhat".
  ///
  /// In en, this message translates to:
  /// **'A Setup is a snapshot of your entire bike configuration. It captures the specific values of all your adjustments alongside context like location, weather, and trail conditions.'**
  String get faqSetupWhatAnswer;

  /// Question of the FAQ entry "SetupRecord".
  ///
  /// In en, this message translates to:
  /// **'How do I record a new setup?'**
  String get faqSetupRecordQuestion;

  /// Answer of the FAQ entry "SetupRecord".
  ///
  /// In en, this message translates to:
  /// **'Go to the \"Setups\" tab and tap the \"+\" button to record a new setup for your bike.'**
  String get faqSetupRecordAnswer;

  /// Question of the FAQ entry "SetupHighlights".
  ///
  /// In en, this message translates to:
  /// **'What do the green and orange highlights on a value mean?'**
  String get faqSetupHighlightsQuestion;

  /// Answer of the FAQ entry "SetupHighlights".
  ///
  /// In en, this message translates to:
  /// **'They show how a value compares to the setup you last recorded.\n\nGreen means the value is recorded for the first time — there was no earlier value to compare it to.\n\nOrange means you changed the value: the previous one is shown underneath, crossed out, so you can see at a glance what you actually touched.'**
  String get faqSetupHighlightsAnswer;

  /// Question of the FAQ entry "SetupRestoreIcon".
  ///
  /// In en, this message translates to:
  /// **'What does the ↺ icon next to a value do?'**
  String get faqSetupRestoreIconQuestion;

  /// Answer of the FAQ entry "SetupRestoreIcon".
  ///
  /// In en, this message translates to:
  /// **'It restores the value the adjustment had when you opened the setup — usually the one carried over from your last setup. Use it to undo a change you are not happy with, without leaving the page.'**
  String get faqSetupRestoreIconAnswer;

  /// Question of the FAQ entry "SetupOtherUnit".
  ///
  /// In en, this message translates to:
  /// **'Can I enter a value in a different unit than the adjustment uses?'**
  String get faqSetupOtherUnitQuestion;

  /// Answer of the FAQ entry "SetupOtherUnit".
  ///
  /// In en, this message translates to:
  /// **'Yes. Tap the unit label next to the input field to cycle through the compatible units — type in whichever one you measured in, and the app converts and stores it in the adjustment’s own unit. A small line below the field shows the value as it will be stored. See the Adjustment questions above for the full details.'**
  String get faqSetupOtherUnitAnswer;

  /// Question of the FAQ entry "SetupLocationLater".
  ///
  /// In en, this message translates to:
  /// **'I recorded a setup without GPS. Can I add the location later?'**
  String get faqSetupLocationLaterQuestion;

  /// Answer of the FAQ entry "SetupLocationLater".
  ///
  /// In en, this message translates to:
  /// **'Yes. Edit the setup, tap the location chip (showing a pin or \"Location Context\"), and use the search bar in the sheet to find the address. Alternatively, you can manually enter the Latitude and Longitude.'**
  String get faqSetupLocationLaterAnswer;

  /// Question of the FAQ entry "SetupOffline".
  ///
  /// In en, this message translates to:
  /// **'I recorded a setup without Internet. How do I update address and weather?'**
  String get faqSetupOfflineQuestion;

  /// Answer of the FAQ entry "SetupOffline".
  ///
  /// In en, this message translates to:
  /// **'Edit the setup and open the location sheet (tap the location chip) to manually fetch the address from Latitude and Longitude. Then, open the weather sheet (tap the weather chip) and tap \"Update Weather by Location\".'**
  String get faqSetupOfflineAnswer;

  /// Question of the FAQ entry "SetupRawData".
  ///
  /// In en, this message translates to:
  /// **'Can I see a raw data overview of all my setups?'**
  String get faqSetupRawDataQuestion;

  /// Answer of the FAQ entry "SetupRawData".
  ///
  /// In en, this message translates to:
  /// **'Yes. Open the detailed view of a component (by tapping its icon in \"Bikes\" tab) and then tap on the large card representing the component. This opens a table view where you can compare setups, select which columns to show, and sort the data for deeper analysis.'**
  String get faqSetupRawDataAnswer;

  /// Question of the FAQ entry "SetupRestore".
  ///
  /// In en, this message translates to:
  /// **'What does the \"Restore\" option do?'**
  String get faqSetupRestoreQuestion;

  /// Answer of the FAQ entry "SetupRestore".
  ///
  /// In en, this message translates to:
  /// **'It duplicates the selected setup, copying all adjustment values, but sets the date and time to now. It also automatically updates the location and weather to your current position. \n\nThis is especially useful if you made changes that feel worse than before and want to easily go back to a previous, known good setup.'**
  String get faqSetupRestoreAnswer;

  /// Question of the FAQ entry "RiderWhy".
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get faqRiderWhyQuestion;

  /// Answer of the FAQ entry "RiderWhy".
  ///
  /// In en, this message translates to:
  /// **'Your rider profile adds personal context to your setups. Values like your riding weight directly influence how bike components behave, so recording them with each setup makes finding the optimal setup easier.'**
  String get faqRiderWhyAnswer;

  /// Question of the FAQ entry "RiderAdd".
  ///
  /// In en, this message translates to:
  /// **'How to add a Rider?'**
  String get faqRiderAddQuestion;

  /// Answer of the FAQ entry "RiderAdd".
  ///
  /// In en, this message translates to:
  /// **'Tap the rider icon in the top bar and enter your name. You can also create your rider from the rider tab while adding a setup.'**
  String get faqRiderAddAnswer;

  /// Question of the FAQ entry "RiderLink".
  ///
  /// In en, this message translates to:
  /// **'How to link a Rider to a Bike?'**
  String get faqRiderLinkQuestion;

  /// Answer of the FAQ entry "RiderLink".
  ///
  /// In en, this message translates to:
  /// **'Navigate to the \"Bikes\" tab and select the bike you want to link. Tap the three-dot menu, select \"Edit\", and choose the rider from the \"Rider\" dropdown menu. Alternatively, tap \"Link rider\" in the rider tab while adding a setup for that bike. A bike can also have no rider, e.g. a bike of a family member.'**
  String get faqRiderLinkAnswer;

  /// Question of the FAQ entry "RiderWeight".
  ///
  /// In en, this message translates to:
  /// **'How do I update my riding weight?'**
  String get faqRiderWeightQuestion;

  /// Answer of the FAQ entry "RiderWeight".
  ///
  /// In en, this message translates to:
  /// **'Rider values are recorded with each setup: add a setup and enter the current values in its rider tab. To add, rename or remove attributes, tap the rider icon in the top bar and then tap your rider.'**
  String get faqRiderWeightAnswer;

  /// Question of the FAQ entry "StravaWhat".
  ///
  /// In en, this message translates to:
  /// **'What is Strava Sync?'**
  String get faqStravaWhatQuestion;

  /// Answer of the FAQ entry "StravaWhat".
  ///
  /// In en, this message translates to:
  /// **'Strava Sync is a paid subscription that automatically imports your Strava activities into the app. New, updated, and deleted activities are synced in real time so you can see which setup you ran on every ride. You can also trigger a manual sync at any time — up to once per hour.'**
  String get faqStravaWhatAnswer;

  /// Question of the FAQ entry "StravaCancel".
  ///
  /// In en, this message translates to:
  /// **'How do I cancel my subscription?'**
  String get faqStravaCancelQuestion;

  /// Answer of the FAQ entry "StravaCancel".
  ///
  /// In en, this message translates to:
  /// **'You can cancel at any time directly through the App Store or Google Play — not through the app itself.\n\nOn iPhone: Settings → [your name] → Subscriptions → Bike Setup Tracker → Cancel.\n\nOn Android: Google Play → Profile icon → Payments & subscriptions → Subscriptions → Bike Setup Tracker → Cancel.\n\nYour access remains active until the end of the current billing period.'**
  String get faqStravaCancelAnswer;

  /// Question of the FAQ entry "StravaRefund".
  ///
  /// In en, this message translates to:
  /// **'How do I request a refund?'**
  String get faqStravaRefundQuestion;

  /// Answer of the FAQ entry "StravaRefund".
  ///
  /// In en, this message translates to:
  /// **'Refunds are handled by Apple or Google, not by us.\n\nOn iPhone: Visit reportaproblem.apple.com, find the charge, and request a refund.\n\nOn Android: Open Google Play → Profile icon → Payments & subscriptions → Subscriptions or Order history → tap the purchase → Request a refund.'**
  String get faqStravaRefundAnswer;

  /// Question of the FAQ entry "StravaRestore".
  ///
  /// In en, this message translates to:
  /// **'How do I restore a previous subscription?'**
  String get faqStravaRestoreQuestion;

  /// Answer of the FAQ entry "StravaRestore".
  ///
  /// In en, this message translates to:
  /// **'Open the Strava Sync sheet (tap the Strava icon in the top bar) and tap \"Restore previous purchase.\" The app will contact the store and restore your active subscription automatically.'**
  String get faqStravaRestoreAnswer;

  /// Question of the FAQ entry "StravaPaywall".
  ///
  /// In en, this message translates to:
  /// **'I resubscribed but the app still shows the paywall. What do I do?'**
  String get faqStravaPaywallQuestion;

  /// Answer of the FAQ entry "StravaPaywall".
  ///
  /// In en, this message translates to:
  /// **'Tap \"Restore previous purchase\" on the paywall screen. The app will check your current subscription status with the store and unlock access.'**
  String get faqStravaPaywallAnswer;

  /// Question of the FAQ entry "StravaExpire".
  ///
  /// In en, this message translates to:
  /// **'What happens to my data when my subscription expires?'**
  String get faqStravaExpireQuestion;

  /// Answer of the FAQ entry "StravaExpire".
  ///
  /// In en, this message translates to:
  /// **'Your synced activities are removed from the app to respect your privacy. Your bike and component configurations are unaffected. If you resubscribe and reconnect Strava, a fresh sync will restore your activity history.'**
  String get faqStravaExpireAnswer;

  /// Question of the FAQ entry "TasksWhat".
  ///
  /// In en, this message translates to:
  /// **'What is a Task?'**
  String get faqTasksWhatQuestion;

  /// Answer of the FAQ entry "TasksWhat".
  ///
  /// In en, this message translates to:
  /// **'A Task is a piece of maintenance or an action you want to track for your bike or a specific component.'**
  String get faqTasksWhatAnswer;

  /// Question of the FAQ entry "TasksRule".
  ///
  /// In en, this message translates to:
  /// **'What is a \"Task Rule\"?'**
  String get faqTasksRuleQuestion;

  /// Answer of the FAQ entry "TasksRule".
  ///
  /// In en, this message translates to:
  /// **'Think of a Task Rule as a \"Plan\" or \"Template.\" It defines what needs to happen (e.g., \"Bleed Brakes\"), its priority, and which bike or component it applies to. It sets the foundation for tracking when something should be done.'**
  String get faqTasksRuleAnswer;

  /// Question of the FAQ entry "TasksEntry".
  ///
  /// In en, this message translates to:
  /// **'What is a \"Task Entry\"?'**
  String get faqTasksEntryQuestion;

  /// Answer of the FAQ entry "TasksEntry".
  ///
  /// In en, this message translates to:
  /// **'A Task Entry is a \"Log\" or \"Record\" of work actually performed. When you complete a task defined by a Task Rule, you create a Task Entry to save exactly when it happened and any notes you want to keep.'**
  String get faqTasksEntryAnswer;

  /// Question of the FAQ entry "TasksTogether".
  ///
  /// In en, this message translates to:
  /// **'How do they work together?'**
  String get faqTasksTogetherQuestion;

  /// Answer of the FAQ entry "TasksTogether".
  ///
  /// In en, this message translates to:
  /// **'The Task Rule defines the goal, and Task Entries track your history. Every time you finish a task, a new Entry is added to that Rule. This allows the app to show you a complete timeline of when the task was performed in the past.'**
  String get faqTasksTogetherAnswer;

  /// Question of the FAQ entry "TasksDueOverdue".
  ///
  /// In en, this message translates to:
  /// **'What is the difference between \"Due\" and \"Overdue\"?'**
  String get faqTasksDueOverdueQuestion;

  /// Answer of the FAQ entry "TasksDueOverdue".
  ///
  /// In en, this message translates to:
  /// **'Both statuses mean the task needs your attention, but at different urgency levels.\n\n\"Due\" (shown in orange) means the task has reached 100% of its interval — it\'s time to do it.\n\n\"Overdue\" (shown in red) means the task has exceeded the interval by more than 10%. There is a small grace window before a task escalates from Due to Overdue, so a minor overshoot will not immediately turn red.'**
  String get faqTasksDueOverdueAnswer;

  /// Button that dismisses a hint card without acting on it.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get hintNoThanks;

  /// Tooltip of the info button on a hint card that opens an explanation.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get hintLearnMore;

  /// Button on a hint card that shows the next page.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get hintNext;

  /// Button on a hint card that dismisses the remaining pages.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get hintSkip;

  /// Button on the last page of a hint card that dismisses it.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get hintGotIt;

  /// Label above a hint card that teaches a gesture.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get hintLabelTip;

  /// Label above a hint card that suggests turning on a feature.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get hintLabelSuggestion;

  /// Label above a hint card that explains something.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get hintLabelInfo;

  /// Label above the hint card that announces new features.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get hintLabelWhatsNew;

  /// Snackbar after tasks were turned on from a hint.
  ///
  /// In en, this message translates to:
  /// **'Tasks enabled — find it in the home bottom navigation bar'**
  String get hintTasksEnabled;

  /// Snackbar after the calendar was turned on from a hint.
  ///
  /// In en, this message translates to:
  /// **'Calendar enabled — find it next to the search button on the Setups tab'**
  String get hintCalendarEnabled;

  /// Snackbar after subcomponents were turned on from a hint.
  ///
  /// In en, this message translates to:
  /// **'Subcomponents enabled — edit a part and pick its parent under \"Installed on\"'**
  String get hintSubcomponentsEnabled;

  /// Snackbar after attachments were turned on from a hint.
  ///
  /// In en, this message translates to:
  /// **'Attachments enabled — add photos and files to bikes, components, setups and tasks'**
  String get hintAttachmentsEnabled;

  /// Snackbar after tasks were turned on from the what's new hint.
  ///
  /// In en, this message translates to:
  /// **'Tasks enabled — recommended tasks are offered when you add a component'**
  String get hintTaskPresetsEnabled;

  /// Button of the what's new hint that turns on tasks.
  ///
  /// In en, this message translates to:
  /// **'Turn on Tasks'**
  String get hintTurnOnTasks;

  /// Title of the first page of the what's new hint about the component catalog.
  ///
  /// In en, this message translates to:
  /// **'Fork & shock catalog'**
  String get hintRelease45CatalogTitle;

  /// Body of the first page of the what's new hint about the component catalog.
  ///
  /// In en, this message translates to:
  /// **'Adding a fork or shock? Pick the model from the built-in catalog and its adjustments, like click ranges, air pressure and SAG, are filled in for you. Everything stays editable.'**
  String get hintRelease45CatalogBody;

  /// Title of the second page of the what's new hint about recommended tasks.
  ///
  /// In en, this message translates to:
  /// **'Recommended tasks'**
  String get hintRelease45TasksTitle;

  /// Body of the second page of the what's new hint when tasks are already on.
  ///
  /// In en, this message translates to:
  /// **'Whenever you add a component, matching maintenance tasks like a chain wear check or a fork service are suggested. Catalog forks and shocks use the manufacturer’s service intervals.'**
  String get hintRelease45TasksBody;

  /// Body of the second page of the what's new hint when tasks are still off.
  ///
  /// In en, this message translates to:
  /// **'Whenever you add a component, matching maintenance tasks like a chain wear check or a fork service are suggested. Catalog forks and shocks use the manufacturer’s service intervals. Turn on Tasks to get them.'**
  String get hintRelease45TasksBodyOfferTasks;

  /// Title of the what's new hint shown to people whose app switched language to match their device.
  ///
  /// In en, this message translates to:
  /// **'German is here'**
  String get hintRelease46LanguageTitle;

  /// Body of the what's new hint about the app language following the device language.
  ///
  /// In en, this message translates to:
  /// **'The app is now available in German and follows your device language. Prefer another language? Choose it below, or change it anytime in Preferences.'**
  String get hintRelease46LanguageBody;

  /// Button of the what's new hint that opens the language picker.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get hintRelease46ChooseLanguage;

  /// Title of the garage gestures hint.
  ///
  /// In en, this message translates to:
  /// **'Gestures in Garage'**
  String get hintGarageTitle;

  /// First tip of the garage gestures hint.
  ///
  /// In en, this message translates to:
  /// **'Drag component icons to reorder, swap them to other bikes, or drop them into Uninstalled.'**
  String get hintGarageTip1;

  /// Second tip of the garage gestures hint.
  ///
  /// In en, this message translates to:
  /// **'Double-tap a component icon to view its setup history, notes, and charts.'**
  String get hintGarageTip2;

  /// Third tip of the garage gestures hint.
  ///
  /// In en, this message translates to:
  /// **'Double-tap a bike card to quickly filter your view and focus on its parts.'**
  String get hintGarageTip3;

  /// Title of the installation timeline hint.
  ///
  /// In en, this message translates to:
  /// **'Track installation history'**
  String get hintTimelineTitle;

  /// Button of the installation timeline hint.
  ///
  /// In en, this message translates to:
  /// **'Activate Timeline'**
  String get hintTimelineAction;

  /// Title of the what's-new page about remembered filters.
  ///
  /// In en, this message translates to:
  /// **'Your filters are remembered'**
  String get hintReleaseFiltersTitle;

  /// Body of the what's-new page about remembered filters.
  ///
  /// In en, this message translates to:
  /// **'The selected bike and filters now stay applied when you reopen the app. Prefer a fresh start? Turn off Remember Filters in Settings › Preferences.'**
  String get hintReleaseFiltersBody;

  /// Title of the what's-new page about subcomponents.
  ///
  /// In en, this message translates to:
  /// **'Subcomponents'**
  String get hintReleaseSubcomponentsTitle;

  /// Body of the what's-new page about subcomponents.
  ///
  /// In en, this message translates to:
  /// **'Install parts on other parts, like a tire on a wheel. They move between bikes along with their parent.'**
  String get hintReleaseSubcomponentsBody;

  /// Title of the what's-new page about attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get hintReleaseAttachmentsTitle;

  /// Body of the what's-new page about attachments.
  ///
  /// In en, this message translates to:
  /// **'Add photos and files to bikes, components, setups and tasks. They are stored on this device only and are not included in backups.'**
  String get hintReleaseAttachmentsBody;

  /// Sentence appended to a what's-new page while its feature is off. Starts with a space.
  ///
  /// In en, this message translates to:
  /// **' Turn it on here or anytime in Settings › Features.'**
  String get hintReleaseTurnOnHere;

  /// Button of a what's-new page that turns its feature on.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get hintReleaseTurnOn;

  /// Title of the calendar hint.
  ///
  /// In en, this message translates to:
  /// **'See your history at a glance'**
  String get hintCalendarTitle;

  /// Body of the calendar hint.
  ///
  /// In en, this message translates to:
  /// **'Turn on the Calendar to browse your setups and entries by date.'**
  String get hintCalendarBody;

  /// Button of the calendar hint.
  ///
  /// In en, this message translates to:
  /// **'Turn on Calendar'**
  String get hintCalendarAction;

  /// Title of the setup comparison hint.
  ///
  /// In en, this message translates to:
  /// **'Compare two setups'**
  String get hintComparisonTitle;

  /// Body of the setup comparison hint.
  ///
  /// In en, this message translates to:
  /// **'By default, A is your current setup and B is the setup you chose. Tap either setup above to pick another one. Orange values indicate differences; switch to All to include all recorded values.'**
  String get hintComparisonBody;

  /// Title of the tasks hint.
  ///
  /// In en, this message translates to:
  /// **'Organize your bike tasks'**
  String get hintTasksTitle;

  /// Body of the tasks hint.
  ///
  /// In en, this message translates to:
  /// **'Turn on Task Management to note anything bike related — maintenance, tweaks to try, or trails to ride.'**
  String get hintTasksBody;

  /// Button of the tasks hint.
  ///
  /// In en, this message translates to:
  /// **'Activate Tasks'**
  String get hintTasksAction;

  /// Title of the Strava gear hint.
  ///
  /// In en, this message translates to:
  /// **'Link your Strava gear'**
  String get hintStravaLinkTitle;

  /// Body of the Strava gear hint.
  ///
  /// In en, this message translates to:
  /// **'Choose a bike for each gear. Your setups are then matched with the right Strava activities.'**
  String get hintStravaLinkBody;

  /// Label of the hint shown when Strava has no gear.
  ///
  /// In en, this message translates to:
  /// **'No gear found'**
  String get hintStravaNoGearsLabel;

  /// Title of the hint shown when Strava has no gear.
  ///
  /// In en, this message translates to:
  /// **'Add a bike in Strava'**
  String get hintStravaNoGearsTitle;

  /// Button of the hint shown when Strava has no gear.
  ///
  /// In en, this message translates to:
  /// **'Open Strava'**
  String get hintStravaNoGearsOpen;

  /// First step of the hint shown when Strava has no gear.
  ///
  /// In en, this message translates to:
  /// **'Open the Strava app'**
  String get hintStravaNoGearsStep1;

  /// Second step of the hint shown when Strava has no gear.
  ///
  /// In en, this message translates to:
  /// **'Profile picture → Gear → Add a new Bike'**
  String get hintStravaNoGearsStep2;

  /// Third step of the hint shown when Strava has no gear.
  ///
  /// In en, this message translates to:
  /// **'Come back here and tap Sync'**
  String get hintStravaNoGearsStep3;

  /// Closing tip of the hint shown when Strava has no gear.
  ///
  /// In en, this message translates to:
  /// **'Tip: you can also assign the bike to existing activities in Strava.'**
  String get hintStravaNoGearsTip;

  /// Title of the subcomponents hint for a crowded bike.
  ///
  /// In en, this message translates to:
  /// **'Group parts under their parent'**
  String get hintSubcomponentsTitle;

  /// Title of the subcomponents hint that suggests a parent. {parent} is the name of the parent component.
  ///
  /// In en, this message translates to:
  /// **'Mount it on {parent}?'**
  String hintSubcomponentsTitleParent(String parent);

  /// Body of the subcomponents hint.
  ///
  /// In en, this message translates to:
  /// **'Turn on Subcomponents to install parts on other parts, like a tire on a wheel. They move along with their parent.'**
  String get hintSubcomponentsBody;

  /// Button of the subcomponents hint.
  ///
  /// In en, this message translates to:
  /// **'Activate Subcomponents'**
  String get hintSubcomponentsAction;

  /// Title of the task swipe hint.
  ///
  /// In en, this message translates to:
  /// **'Postpone a task'**
  String get hintTaskListTitle;

  /// Body of the task swipe hint.
  ///
  /// In en, this message translates to:
  /// **'Swipe a task to the left to add a delay. This works for every interval type except a fixed date.'**
  String get hintTaskListBody;

  /// Label of the getting-started hint.
  ///
  /// In en, this message translates to:
  /// **'Steps to get started'**
  String get hintGuideLabel;

  /// Button that dismisses the getting-started hint.
  ///
  /// In en, this message translates to:
  /// **'Hide guide'**
  String get hintGuideHide;

  /// First step of the getting-started hint.
  ///
  /// In en, this message translates to:
  /// **'Add your bike'**
  String get hintGuideAddBike;

  /// Second step of the getting-started hint.
  ///
  /// In en, this message translates to:
  /// **'Add a component'**
  String get hintGuideAddComponent;

  /// Third step of the getting-started hint.
  ///
  /// In en, this message translates to:
  /// **'Record a setup'**
  String get hintGuideRecordSetup;

  /// Snackbar action that reverts the action just performed.
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get undo;

  /// Joins two items in a sentence.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String listJoinTwo(String first, String second);

  /// Joins three or more items in a sentence. {leading} is the comma-separated start of the list, {last} the final item.
  ///
  /// In en, this message translates to:
  /// **'{leading}, and {last}'**
  String listJoinMany(String leading, String last);

  /// Error under the installation timeline when it has no entries.
  ///
  /// In en, this message translates to:
  /// **'At least one entry is required'**
  String get timelineProblemNoEntries;

  /// Error under the installation timeline when an archival is followed by another entry.
  ///
  /// In en, this message translates to:
  /// **'Archival can only be the last entry in the timeline'**
  String get timelineProblemArchivalNotLast;

  /// Error under the installation timeline when two uninstall entries follow each other.
  ///
  /// In en, this message translates to:
  /// **'Cannot have consecutive uninstallations'**
  String get timelineProblemConsecutiveUninstallations;

  /// Error under the installation timeline when two entries in a row install the component on the same bike.
  ///
  /// In en, this message translates to:
  /// **'Cannot have consecutive installations on the same bike'**
  String get timelineProblemConsecutiveOnSameBike;

  /// Error under the installation timeline when two entries in a row install the component on the same parent component.
  ///
  /// In en, this message translates to:
  /// **'Cannot have consecutive installations on the same component'**
  String get timelineProblemConsecutiveOnSameComponent;

  /// Error under the installation timeline. "From beginning" is the timeline's date choice for the start of the component's life.
  ///
  /// In en, this message translates to:
  /// **'Multiple \"From beginning\" entries are not allowed'**
  String get timelineProblemMultipleFromBeginning;

  /// Error under the installation timeline when two entries share a date and time.
  ///
  /// In en, this message translates to:
  /// **'Two entries cannot have the same date & time'**
  String get timelineProblemSameDateTime;

  /// Error under the installation timeline when an entry points to a deleted bike.
  ///
  /// In en, this message translates to:
  /// **'This entry is installed on a bike that no longer exists'**
  String get timelineProblemBikeMissing;

  /// Error under the installation timeline when a component is installed on itself.
  ///
  /// In en, this message translates to:
  /// **'A component cannot be installed on itself'**
  String get timelineProblemInstalledOnItself;

  /// Error under the installation timeline when components would end up installed on each other in a circle.
  ///
  /// In en, this message translates to:
  /// **'This installation creates a loop of components'**
  String get timelineProblemComponentLoop;

  /// Snackbar after clearing the rider of bikes. {count} is the number of bikes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Rider removed from 1 Bike.} other{Rider removed from {count} Bikes.}}'**
  String bikeRiderRemoved(int count);

  /// Snackbar after assigning a rider to bikes. {name} is the rider's name, {count} the number of bikes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Rider set to \'{name}\' for 1 Bike.} other{Rider set to \'{name}\' for {count} Bikes.}}'**
  String bikeRiderSet(int count, String name);

  /// Snackbar after deleting bikes. {count} is the number of bikes, {name} the name of the first one.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Bike \'{name}\' moved to trash.} other{{count} bikes moved to trash.}}'**
  String bikeMovedToTrash(int count, String name);

  /// Part of the list of items trashed along with a bike. {count} is the number of components.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 component} other{{count} components}}'**
  String bikeTrashedComponents(int count);

  /// Part of the list of items trashed along with a bike. {count} is the number of setups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 setup} other{{count} setups}}'**
  String bikeTrashedSetups(int count);

  /// Part of the list of items trashed along with a bike. {count} is the number of tasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task and its entries} other{{count} tasks and their entries}}'**
  String bikeTrashedTasks(int count);

  /// Second line of the snackbar after deleting a bike. {summary} lists the related items, e.g. "2 components and 1 setup".
  ///
  /// In en, this message translates to:
  /// **'Also moved to trash: {summary}.'**
  String bikeAlsoTrashed(String summary);

  /// Snackbar after restoring a bike from the trash. {name} is the bike name.
  ///
  /// In en, this message translates to:
  /// **'Bike \'{name}\' restored from trash.'**
  String bikeRestoredFromTrash(String name);

  /// Snackbar after deleting entries from the bike timeline. {count} is the number of entries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry moved to trash.} other{{count} entries moved to trash.}}'**
  String timelineEntriesMovedToTrash(int count);

  /// Snackbar after unlinking a Strava gear from a bike. {gear} is the gear name, {bike} the bike name.
  ///
  /// In en, this message translates to:
  /// **'Unlinked \'{gear}\' from \'{bike}\'.'**
  String stravaGearUnlinked(String gear, String bike);

  /// Title of the installation timeline section on the component form and details.
  ///
  /// In en, this message translates to:
  /// **'Installation Timeline'**
  String get installationTimelineTitle;

  /// Date label of a timeline entry that applies from the very start of the component's life.
  ///
  /// In en, this message translates to:
  /// **'From beginning'**
  String get timelineFromBeginning;

  /// Menu item that sets a timeline entry to the current date and time.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get timelineNow;

  /// Menu item that opens the date and time pickers for a timeline entry.
  ///
  /// In en, this message translates to:
  /// **'Select date & time...'**
  String get timelineSelectDateTime;

  /// Tooltip of the button that adds an entry to the installation timeline.
  ///
  /// In en, this message translates to:
  /// **'Add Timeline Entry'**
  String get timelineAddEntryTooltip;

  /// Shown in red in the timeline when an entry points to a bike that no longer exists.
  ///
  /// In en, this message translates to:
  /// **'BIKE NOT FOUND'**
  String get bikeNotFound;

  /// Shown in red in the timeline when an entry points to a component that no longer exists.
  ///
  /// In en, this message translates to:
  /// **'COMPONENT NOT FOUND'**
  String get componentNotFound;

  /// Timeline entry for the moment a component was taken off.
  ///
  /// In en, this message translates to:
  /// **'Uninstalled'**
  String get timelineUninstalled;

  /// Timeline entry for the moment a component was archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get timelineArchived;

  /// Second line of an inherited timeline entry. {name} is the component the entry's placement comes through.
  ///
  /// In en, this message translates to:
  /// **'via {name}'**
  String timelineVia(String name);

  /// Timeline day header for today. {date} is the formatted date.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String timelineDayToday(String date);

  /// Timeline day header for yesterday. {date} is the formatted date.
  ///
  /// In en, this message translates to:
  /// **'Yesterday · {date}'**
  String timelineDayYesterday(String date);

  /// Info text of the installation timeline table title on the bike details.
  ///
  /// In en, this message translates to:
  /// **'Visualizes component setup history, including overlaps and periods with no active components.'**
  String get timelineTableInfo;

  /// Label of the component type filter chip of the timeline table while nothing is hidden.
  ///
  /// In en, this message translates to:
  /// **'All Component Types'**
  String get timelineAllComponentTypes;

  /// Label of the component type filter chip while some types are hidden. {visible} types are shown out of {total}.
  ///
  /// In en, this message translates to:
  /// **'Component Types {visible}/{total}'**
  String timelineComponentTypesCount(int visible, int total);

  /// Title of the empty state of the timeline table.
  ///
  /// In en, this message translates to:
  /// **'No installation history'**
  String get timelineEmptyTitle;

  /// Subtitle of the empty state of the timeline table.
  ///
  /// In en, this message translates to:
  /// **'Install components on this bike to see the timeline'**
  String get timelineEmptySubtitle;

  /// Title of the empty state when every component type is hidden in the timeline table.
  ///
  /// In en, this message translates to:
  /// **'No component types selected'**
  String get timelineNoTypesTitle;

  /// Subtitle of the empty state when every component type is hidden in the timeline table.
  ///
  /// In en, this message translates to:
  /// **'Select a component type to display the table'**
  String get timelineNoTypesSubtitle;

  /// Header of the date column in the timeline table.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineTableCorner;

  /// Menu item on a timeline table block that opens the component.
  ///
  /// In en, this message translates to:
  /// **'Component details'**
  String get timelineMenuComponentDetails;

  /// Menu item on a timeline table block that edits the installation entry.
  ///
  /// In en, this message translates to:
  /// **'Edit installation'**
  String get timelineMenuEditInstallation;

  /// Title of the garage empty state while the bike filter hides every bike.
  ///
  /// In en, this message translates to:
  /// **'No bikes match this filter'**
  String get garageNoBikesMatchTitle;

  /// Subtitle of the garage empty state while the bike filter hides every bike.
  ///
  /// In en, this message translates to:
  /// **'The bike filter is hiding all bikes.'**
  String get garageNoBikesMatchSubtitle;

  /// Title of the garage empty state when there are no bikes.
  ///
  /// In en, this message translates to:
  /// **'No bikes yet'**
  String get garageNoBikesTitle;

  /// Subtitle of the garage empty state when there are no bikes.
  ///
  /// In en, this message translates to:
  /// **'Add your first bike to get started.'**
  String get garageNoBikesSubtitle;

  /// Button of the garage empty state that opens the new bike form.
  ///
  /// In en, this message translates to:
  /// **'Add a bike'**
  String get garageAddBike;

  /// Menu item or button that opens an item for editing.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Menu item or button that creates a copy of an item.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// Menu item or button that replaces a component with another one.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// Menu item or button that moves an item to the trash.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Label of the 'not installed' step in a component's installation chain.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get timelineNotInstalled;

  /// Destination label of a timeline entry that moved a component to the archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get timelineArchive;

  /// Title of the first timeline entry of a component. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String timelineAdded(String name);

  /// Title of a timeline entry that installed a component. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Installed {name}'**
  String timelineInstalled(String name);

  /// Title of a timeline entry that took a component off. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Uninstalled {name}'**
  String timelineUninstalledName(String name);

  /// Title of a timeline entry that archived a component. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Archived {name}'**
  String timelineArchivedName(String name);

  /// Title of a timeline entry that swapped one component for another. {type} is the component type, e.g. "Fork".
  ///
  /// In en, this message translates to:
  /// **'Replaced {type}'**
  String timelineReplaced(String type);

  /// Error snackbar when saving an installation would make components sit on each other in a circle.
  ///
  /// In en, this message translates to:
  /// **'Not saved: this would create a loop of components.'**
  String get installationNotSavedLoop;

  /// Caption under the newly installed component in the replacement preview.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get timelineInstalledCaption;

  /// Title of a timeline section in the replacement sheet when both components share a name. {status} is e.g. "Installed".
  ///
  /// In en, this message translates to:
  /// **'{name} ({status})'**
  String replacementTitleWithStatus(String name, String status);

  /// Explanation at the top of the replacement sheet. {minutes} is the time window that groups two entries into a replacement.
  ///
  /// In en, this message translates to:
  /// **'A replacement is simply two installations within {minutes, plural, =1{1 minute} other{{minutes} minutes}}: one component removed and another installed on the same bike.'**
  String replacementExplanation(int minutes);

  /// Button that moves on to the next step of a sheet or flow.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Title of the replace component sheet. {name} is the component being replaced.
  ///
  /// In en, this message translates to:
  /// **'Replace \'{name}\''**
  String replaceTitle(String name);

  /// Label in the replace preview for the chosen replacement component when none is picked yet.
  ///
  /// In en, this message translates to:
  /// **'Replacement'**
  String get replaceOutcomeReplacement;

  /// Label in the replace preview for the component that will be created.
  ///
  /// In en, this message translates to:
  /// **'New component'**
  String get replaceOutcomeNewComponent;

  /// Segment of the replace sheet: replace with a component that already exists.
  ///
  /// In en, this message translates to:
  /// **'Existing'**
  String get replaceModeExisting;

  /// Segment of the replace sheet: replace with a newly created component.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get replaceModeNew;

  /// Explanation in the replace sheet: existing component, installation timeline on.
  ///
  /// In en, this message translates to:
  /// **'Pick an already uninstalled component to install in place of this one, and set the replacement date. This is when the current component is retired and the selected one installed.'**
  String get replaceDescriptionExistingDated;

  /// Explanation in the replace sheet: new component, installation timeline on.
  ///
  /// In en, this message translates to:
  /// **'Set the replacement date. This is when the current component will be retired and a new one installed. In the next step, you can configure the new component, which will be pre-filled with details from this one.'**
  String get replaceDescriptionNewDated;

  /// Explanation in the replace sheet: existing component, installation timeline off.
  ///
  /// In en, this message translates to:
  /// **'Pick an already uninstalled component to install in place of this one. The current component is uninstalled.'**
  String get replaceDescriptionExistingUndated;

  /// Explanation in the replace sheet: new component, installation timeline off.
  ///
  /// In en, this message translates to:
  /// **'The current component is uninstalled and a new one installed in its place. In the next step, you can configure the new component, which will be pre-filled with details from this one.'**
  String get replaceDescriptionNewUndated;

  /// Hint in the replace sheet that offers to turn on the installation timeline.
  ///
  /// In en, this message translates to:
  /// **'Without a swap date, the new part counts as installed from the start. Past setups then no longer show the old part and the values you recorded for it. Date the swap to keep both histories intact.'**
  String get replaceTimelineHint;

  /// Title of the empty hint in the replace sheet. {type} is the component type, e.g. "Fork".
  ///
  /// In en, this message translates to:
  /// **'No uninstalled {type} available'**
  String replaceNoUninstalledTitle(String type);

  /// Hint of the empty state in the replace sheet.
  ///
  /// In en, this message translates to:
  /// **'Create a new component instead.'**
  String get replaceNoUninstalledHint;

  /// Label of the dropdown in the replace sheet that picks the existing replacement.
  ///
  /// In en, this message translates to:
  /// **'Replacement Component'**
  String get replaceComponentLabel;

  /// Placeholder of the replacement dropdown.
  ///
  /// In en, this message translates to:
  /// **'Select a component'**
  String get replaceComponentHint;

  /// Validation error of the replacement dropdown.
  ///
  /// In en, this message translates to:
  /// **'Please select a component'**
  String get replaceComponentRequired;

  /// Label of the date field in the replace sheet.
  ///
  /// In en, this message translates to:
  /// **'Replacement Date'**
  String get replaceDateLabel;

  /// Validation error of the replacement date. {date} is the date and time of the last installation.
  ///
  /// In en, this message translates to:
  /// **'Must be after last installation ({date})'**
  String replaceDateAfterLast(String date);

  /// Option in the replace sheet.
  ///
  /// In en, this message translates to:
  /// **'Move subcomponents to replacement'**
  String get replaceMoveSubcomponents;

  /// Description of the option that moves subcomponents to the replacement.
  ///
  /// In en, this message translates to:
  /// **'They are installed on the replacement at the replacement date.'**
  String get replaceMoveSubcomponentsHint;

  /// Option in the replace sheet.
  ///
  /// In en, this message translates to:
  /// **'Uninstall subcomponents'**
  String get uninstallSubcomponents;

  /// Description of the option that uninstalls subcomponents.
  ///
  /// In en, this message translates to:
  /// **'They move to your uninstalled components.'**
  String get uninstallSubcomponentsHint;

  /// Tooltip of a picker option that marks the value the item had before it was edited.
  ///
  /// In en, this message translates to:
  /// **'Previous value'**
  String get previousValueTooltip;

  /// Validation error of a numeric field.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid value'**
  String get enterValidValue;

  /// Label of the optional notes field of a form.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptionalLabel;

  /// Tooltip of the paperclip chip that attaches images or files in a form.
  ///
  /// In en, this message translates to:
  /// **'Add Attachment'**
  String get addAttachmentTooltip;

  /// Button that expands the optional fields of a form.
  ///
  /// In en, this message translates to:
  /// **'Show Additional Fields'**
  String get showAdditionalFields;

  /// Button that collapses the optional fields of a form.
  ///
  /// In en, this message translates to:
  /// **'Hide Additional Fields'**
  String get hideAdditionalFields;

  /// Shown in red when an item points to a rider that no longer exists.
  ///
  /// In en, this message translates to:
  /// **'RIDER NOT FOUND'**
  String get riderNotFound;

  /// Shown in red when a bike points to a Strava gear that no longer exists.
  ///
  /// In en, this message translates to:
  /// **'GEAR NOT FOUND'**
  String get stravaGearNotFound;

  /// Title of the component type picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Select Component Type'**
  String get componentTypePickerTitle;

  /// Title of the sheet and label of the chip for the usage an item had before it was tracked.
  ///
  /// In en, this message translates to:
  /// **'Initial Stats'**
  String get initialStatsTitle;

  /// Label of the initial stats chip once values are set. {summary} lists them, e.g. "1,200 km · 30 h".
  ///
  /// In en, this message translates to:
  /// **'Initial: {summary}'**
  String initialStatsChip(String summary);

  /// Tooltip of the initial stats chip on the bike form.
  ///
  /// In en, this message translates to:
  /// **'Usage before this bike was tracked'**
  String get initialStatsBikeTooltip;

  /// Tooltip of the initial stats chip on the component form.
  ///
  /// In en, this message translates to:
  /// **'Usage before this component was tracked'**
  String get initialStatsComponentTooltip;

  /// Explanation in the initial stats sheet of a bike.
  ///
  /// In en, this message translates to:
  /// **'Usage this bike had before it was tracked here, e.g. for a second-hand bike. It is added on top of the stats from your activities. Components installed \'Since beginning\' inherit these stats.'**
  String get initialStatsBikeDescription;

  /// Explanation in the initial stats sheet of a component.
  ///
  /// In en, this message translates to:
  /// **'Usage this component had before it was tracked here, e.g. for a second-hand part. It is added on top of the stats from your activities. Components installed \'Since beginning\' also include their bike\'s initial stats.'**
  String get initialStatsComponentDescription;

  /// Activity count in the initial stats summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 activity} other{{count} activities}}'**
  String initialStatsActivities(int count);

  /// Label of the distance field in the initial stats sheet.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get initialStatsDistance;

  /// Label of the elevation gain field in the initial stats sheet.
  ///
  /// In en, this message translates to:
  /// **'Elevation Gain'**
  String get initialStatsElevationGain;

  /// Label of the moving time field in the initial stats sheet.
  ///
  /// In en, this message translates to:
  /// **'Moving Time'**
  String get initialStatsMovingTime;

  /// Label of the elapsed time field in the initial stats sheet.
  ///
  /// In en, this message translates to:
  /// **'Elapsed Time'**
  String get initialStatsElapsedTime;

  /// Label of the activity count field in the initial stats sheet.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get initialStatsActivityCount;

  /// Label of the energy field in the initial stats sheet.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get initialStatsEnergy;

  /// App bar title of the form that adds a bike.
  ///
  /// In en, this message translates to:
  /// **'Add Bike'**
  String get bikeFormAddTitle;

  /// App bar title of the form that edits a bike.
  ///
  /// In en, this message translates to:
  /// **'Edit Bike'**
  String get bikeFormEditTitle;

  /// Label of the bike name field.
  ///
  /// In en, this message translates to:
  /// **'Bike Name'**
  String get bikeFormNameLabel;

  /// Placeholder of the bike name field.
  ///
  /// In en, this message translates to:
  /// **'Enter bike name'**
  String get bikeFormNameHint;

  /// Validation error of the bike name field.
  ///
  /// In en, this message translates to:
  /// **'Please enter a bike name'**
  String get bikeFormNameRequired;

  /// Label of the rider dropdown on the bike form.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get bikeFormRiderLabel;

  /// Placeholder of the rider dropdown on the bike form.
  ///
  /// In en, this message translates to:
  /// **'Choose a rider for this bike'**
  String get bikeFormRiderHint;

  /// Helper text of the rider dropdown while no rider exists.
  ///
  /// In en, this message translates to:
  /// **'You can assign a rider later, as soon as you\'ve created one.'**
  String get bikeFormRiderHelper;

  /// Validation error of the rider dropdown.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid rider'**
  String get bikeFormRiderInvalid;

  /// Dropdown entry that leaves the bike without a rider.
  ///
  /// In en, this message translates to:
  /// **'No rider'**
  String get bikeFormNoRider;

  /// Placeholder of the notes field of the bike form.
  ///
  /// In en, this message translates to:
  /// **'Enter Bike brand, model, size, year, costs, ...'**
  String get bikeFormNotesHint;

  /// Label of the Strava gear dropdown on the bike form.
  ///
  /// In en, this message translates to:
  /// **'Strava Gear'**
  String get bikeFormStravaGearLabel;

  /// Placeholder of the Strava gear dropdown.
  ///
  /// In en, this message translates to:
  /// **'Link Strava Gear'**
  String get bikeFormStravaGearHint;

  /// Helper text when the chosen Strava gear is already linked to another bike.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Strava Gear already assigned to another Bike'**
  String get bikeFormStravaGearTaken;

  /// Validation error of the Strava gear dropdown.
  ///
  /// In en, this message translates to:
  /// **'Please select valid Gear'**
  String get bikeFormStravaGearInvalid;

  /// Dropdown entry that leaves the bike without Strava gear.
  ///
  /// In en, this message translates to:
  /// **'NOT LINKED'**
  String get bikeFormStravaGearNotLinked;

  /// App bar title of the form that adds a component.
  ///
  /// In en, this message translates to:
  /// **'Add Component'**
  String get componentFormAddTitle;

  /// App bar title of the form that edits a component.
  ///
  /// In en, this message translates to:
  /// **'Edit Component'**
  String get componentFormEditTitle;

  /// Label of the component name field.
  ///
  /// In en, this message translates to:
  /// **'Component Name'**
  String get componentFormNameLabel;

  /// Placeholder of the component name field.
  ///
  /// In en, this message translates to:
  /// **'Enter component name'**
  String get componentFormNameHint;

  /// Validation error of the component name field.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get componentFormNameRequired;

  /// Helper text of the component name field for forks, which offers catalog suggestions.
  ///
  /// In en, this message translates to:
  /// **'Tip: type a product name — e.g. \'Fox 38\''**
  String get componentFormNameTipFork;

  /// Helper text of the component name field for shocks, which offers catalog suggestions.
  ///
  /// In en, this message translates to:
  /// **'Tip: type a product name — e.g. \'Fox Float X\''**
  String get componentFormNameTipShock;

  /// Placeholder of the notes field of the component form.
  ///
  /// In en, this message translates to:
  /// **'Enter brand, model, serial number, costs, ...'**
  String get componentFormNotesHint;

  /// Label of the component type field.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get componentFormTypeLabel;

  /// Placeholder of the component type field while no type is chosen.
  ///
  /// In en, this message translates to:
  /// **'Please select type'**
  String get componentFormTypePlaceholder;

  /// Validation error of the component type field.
  ///
  /// In en, this message translates to:
  /// **'Component type cannot be empty. You can edit it later.'**
  String get componentFormTypeRequired;

  /// Helper text when the bike already carries as many components of the chosen type as allowed. {count} is that limit, {type} the type name.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{WARNING: There is already one {type}-Component installed on this bike.} other{WARNING: There are already {count} {type}-Components installed on this bike.}}'**
  String componentFormTypeOverLimit(int count, String type);

  /// Label of the field that picks where the component is installed.
  ///
  /// In en, this message translates to:
  /// **'Installed on'**
  String get componentFormInstalledOnLabel;

  /// Validation error of the installed-on field.
  ///
  /// In en, this message translates to:
  /// **'Please select valid bike'**
  String get componentFormInstalledOnInvalid;

  /// Helper text while the component is not installed anywhere.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Select Bike to install Component.'**
  String get componentFormInstalledOnWarning;

  /// Note under the installation timeline while replacing a component.
  ///
  /// In en, this message translates to:
  /// **'The timeline is locked during the replacement. The new component is installed at the same time the old one is removed. You can edit the timeline after saving.'**
  String get componentFormTimelineLocked;

  /// Section title of the adjustments on the component form.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get componentFormAdjustmentsTitle;

  /// Info text of the adjustments section on the component form.
  ///
  /// In en, this message translates to:
  /// **'Adjustments are physical parameters on this component that can be tuned—such as dial positions, switch settings, or pressure ranges. Step 1: Define what adjustment parameters exist for this component and set their limits here. Step 2: After you save this component, create a Setup to save actual adjustment values for your bike.'**
  String get componentFormAdjustmentsInfo;

  /// Title of the empty state of the adjustments list on the component form.
  ///
  /// In en, this message translates to:
  /// **'No adjustments yet'**
  String get componentFormAdjustmentsEmptyTitle;

  /// Subtitle of the empty adjustments list.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Add Adjustment\' to define settings for this component'**
  String get componentFormAdjustmentsEmptySubtitle;

  /// Subtitle of the empty adjustments list while the form shows an error.
  ///
  /// In en, this message translates to:
  /// **'Tap here to add the first adjustment'**
  String get componentFormAdjustmentsEmptyError;

  /// Button below the adjustments list of the component form.
  ///
  /// In en, this message translates to:
  /// **'Add Adjustment'**
  String get componentFormAddAdjustment;

  /// Snackbar after a catalog product was applied to the form. {name} is the product name.
  ///
  /// In en, this message translates to:
  /// **'Filled from {name}'**
  String componentFormPresetFilled(String name);

  /// Snackbar after a catalog product replaced the component's adjustments. {name} is the product name.
  ///
  /// In en, this message translates to:
  /// **'Replaced adjustments with {name}'**
  String componentFormPresetReplaced(String name);

  /// Snackbar after an existing component was linked to a catalog product. {name} is the product name, {count} the number of added adjustments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Linked to {name} · no adjustments added} =1{Linked to {name} · 1 adjustment added} other{Linked to {name} · {count} adjustments added}}'**
  String componentFormPresetLinked(String name, int count);

  /// Snackbar after the catalog update notice was dismissed.
  ///
  /// In en, this message translates to:
  /// **'Catalog update dismissed'**
  String get componentFormCatalogUpdateDismissed;

  /// Snackbar after the link to a catalog product was removed. {name} is the product name.
  ///
  /// In en, this message translates to:
  /// **'Unlinked from {name} — values kept'**
  String componentFormPresetUnlinked(String name);

  /// Replaces the product name in the unlink snackbar when the product is no longer in the catalog.
  ///
  /// In en, this message translates to:
  /// **'catalog'**
  String get componentFormCatalogFallback;

  /// Caption above the adjustments list. {count} adjustments came from the catalog product {name}.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 adjustment prefilled from {name}} other{{count} adjustments prefilled from {name}}}'**
  String componentFormPresetCaption(int count, String name);

  /// Appended to the prefill caption for adjustments that did not come from the catalog.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 other} other{{count} others}}'**
  String componentFormPresetOthers(int count);

  /// Button of an empty state that removes the active filters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// Label of the chip that opens the column picker of a table.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get columnsLabel;

  /// Button that opens the new component form.
  ///
  /// In en, this message translates to:
  /// **'Add Component'**
  String get addComponent;

  /// Table column that shows the rank of a setup.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get setupColumnRank;

  /// End of a component's time range in the column history when it is still on the bike.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get bikeDetailsLaneNow;

  /// Title of the bike details page when the bike no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Bike not found'**
  String get bikeDetailsNotFoundTitle;

  /// Subtitle of the bike details page when the bike no longer exists.
  ///
  /// In en, this message translates to:
  /// **'This bike was deleted or is no longer available.'**
  String get bikeDetailsNotFoundSubtitle;

  /// Row on the bike details page when the bike has no rider.
  ///
  /// In en, this message translates to:
  /// **'No rider linked to this bike.'**
  String get bikeDetailsNoRider;

  /// Row on the bike details page when the bike has no Strava gear.
  ///
  /// In en, this message translates to:
  /// **'No Strava Gear linked to this bike.'**
  String get bikeDetailsNoStravaGear;

  /// Shown in red on the bike details page when the linked Strava gear no longer exists.
  ///
  /// In en, this message translates to:
  /// **'STRAVA GEAR NOT FOUND'**
  String get bikeDetailsStravaGearNotFound;

  /// Title of the expandable components section of the bike details. {count} is the number of components.
  ///
  /// In en, this message translates to:
  /// **'Components ({count})'**
  String bikeDetailsComponentsTitle(int count);

  /// Title of the empty state of the components section of the bike details.
  ///
  /// In en, this message translates to:
  /// **'No components yet'**
  String get noComponentsTitle;

  /// Subtitle of the empty state of the components section of the bike details.
  ///
  /// In en, this message translates to:
  /// **'Add a component to this bike'**
  String get bikeDetailsNoComponentsSubtitle;

  /// Title of the expandable test sessions section of the bike details. {count} is the number of sessions.
  ///
  /// In en, this message translates to:
  /// **'Test sessions ({count})'**
  String bikeDetailsTestSessionsTitle(int count);

  /// Title of the empty state of the test sessions section.
  ///
  /// In en, this message translates to:
  /// **'No test sessions yet'**
  String get bikeDetailsNoTestSessionsTitle;

  /// Subtitle of the empty state of the test sessions section.
  ///
  /// In en, this message translates to:
  /// **'Try adjustments one after the other and see which works best'**
  String get bikeDetailsNoTestSessionsSubtitle;

  /// Button that starts a new test session.
  ///
  /// In en, this message translates to:
  /// **'Start Test Session'**
  String get startTestSession;

  /// Section title of the setup table on the bike details.
  ///
  /// In en, this message translates to:
  /// **'Setup History'**
  String get bikeDetailsSetupHistoryTitle;

  /// Info text of the setup history section on the bike details.
  ///
  /// In en, this message translates to:
  /// **'All setups of this bike. Add or remove columns via the Columns button, or long-press a column header to remove it. Green values are new (no prior value), orange values have changed from the previous setup. Select rows to compare setups in the charts below.'**
  String get bikeDetailsSetupHistoryInfo;

  /// Second paragraph of the setup history info text, appended to it.
  ///
  /// In en, this message translates to:
  /// **'\n\nComponents that followed each other in the same position (e.g. the tire on the front wheel) share a column, so a replacement continues its predecessor\'s column and starts with a green value. Red values belong to a component that was not installed at that setup.'**
  String get bikeDetailsMergedColumnsInfo;

  /// Title of the empty state of the setup history when the bike has no setups.
  ///
  /// In en, this message translates to:
  /// **'No setups yet'**
  String get noSetupsTitle;

  /// Subtitle of the empty state of the setup history when the bike has no setups.
  ///
  /// In en, this message translates to:
  /// **'No setups reference this bike'**
  String get bikeDetailsNoSetupsSubtitle;

  /// Title of the empty state of the setup history while the filters hide every setup.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches this filter'**
  String get bikeDetailsFilterEmptyTitle;

  /// Subtitle of the empty state of the setup history while the filters hide every setup.
  ///
  /// In en, this message translates to:
  /// **'Your filters are hiding all setups.'**
  String get bikeDetailsFilterEmptySubtitle;

  /// Title of the empty state of the setup history when every column is hidden.
  ///
  /// In en, this message translates to:
  /// **'No columns'**
  String get tableNoColumnsTitle;

  /// Subtitle of the empty state of the setup history when every column is hidden.
  ///
  /// In en, this message translates to:
  /// **'Select a column to display the table'**
  String get tableNoColumnsSubtitle;

  /// Section title of the line chart on the bike details.
  ///
  /// In en, this message translates to:
  /// **'Line Chart'**
  String get chartLineTitle;

  /// Info text of the line chart section on the bike details.
  ///
  /// In en, this message translates to:
  /// **'• Shows the setups selected in the table above in their current sort order.\n• The y-axis represents adjustment values.\n• Select at least two setups to display a trend.\n• Tap a legend entry to highlight a specific line.\n• Long-press a legend entry to remove its column.'**
  String get bikeDetailsLineChartInfo;

  /// Section title of the radial chart on the bike details.
  ///
  /// In en, this message translates to:
  /// **'Radial Chart'**
  String get chartRadialTitle;

  /// Info text of the radial chart section on the bike details.
  ///
  /// In en, this message translates to:
  /// **'• Shows the setups selected in the table above.\n• Axes are normalized across all data for stable comparison.\n• Tap a legend entry to highlight a specific graph.\n• Long-press a legend entry to remove it from the selection.'**
  String get chartRadialInfo;

  /// Section title of the activity histogram on the bike details.
  ///
  /// In en, this message translates to:
  /// **'Activity Histogram'**
  String get chartHistogramTitle;

  /// Info text of the activity histogram section on the bike details.
  ///
  /// In en, this message translates to:
  /// **'• Shows how many Strava activities were ridden with each adjustment value.\n• Counts all setups in the table above, not just the selected ones.\n• Components that followed each other in the same position are counted together in one column.\n• Numerical values are grouped into ranges when there are many distinct values.\n• Tap a legend entry to show a different adjustment.\n• Long-press a legend entry to remove its column.'**
  String get bikeDetailsHistogramInfo;

  /// Title of the locked activity histogram without a Strava subscription.
  ///
  /// In en, this message translates to:
  /// **'Strava Sync required'**
  String get chartHistogramLockedTitle;

  /// Subtitle of the locked activity histogram without a Strava subscription.
  ///
  /// In en, this message translates to:
  /// **'See how many activities you rode with each adjustment value.'**
  String get chartHistogramLockedSubtitle;

  /// Button of the locked activity histogram that opens the Strava plans.
  ///
  /// In en, this message translates to:
  /// **'View plans'**
  String get viewPlans;

  /// Title of the component details page when the component no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Component not found'**
  String get componentDetailsNotFoundTitle;

  /// Subtitle of the component details page when the component no longer exists.
  ///
  /// In en, this message translates to:
  /// **'This component was deleted or is no longer available.'**
  String get componentDetailsNotFoundSubtitle;

  /// Title of the expandable installation history section of the component details.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get componentDetailsHistory;

  /// Title of the expandable subcomponents section of the component details. {count} is the number of subcomponents.
  ///
  /// In en, this message translates to:
  /// **'Subcomponents ({count})'**
  String componentDetailsSubcomponentsTitle(int count);

  /// Subtitle of the empty state of the subcomponents section.
  ///
  /// In en, this message translates to:
  /// **'Install a component on this component'**
  String get componentDetailsNoSubcomponentsSubtitle;

  /// Section title of the setup table on the component details.
  ///
  /// In en, this message translates to:
  /// **'Adjustment History'**
  String get componentDetailsAdjustmentHistoryTitle;

  /// Info text of the adjustment history section on the component details.
  ///
  /// In en, this message translates to:
  /// **'• Add or remove columns via the Columns button.\n• Long-press a column header to remove it.\n• Tap a column header to sort.\n• Use the filter button to narrow down by bike or tags.\n• Select rows to compare setups in the charts below.\n\nValue colors:\n• Green: new value (no prior value).\n• Orange: changed from the previous setup.\n• Red: dangling value (component not installed or rider not linked at setup time).'**
  String get componentDetailsAdjustmentHistoryInfo;

  /// Title of the empty state of the adjustment history when the component has no adjustments.
  ///
  /// In en, this message translates to:
  /// **'No adjustments'**
  String get componentDetailsNoAdjustmentsTitle;

  /// Subtitle of the empty state of the adjustment history when the component has no adjustments.
  ///
  /// In en, this message translates to:
  /// **'No adjustments are defined for this component'**
  String get componentDetailsNoAdjustmentsSubtitle;

  /// Info text of the line chart section on the component details.
  ///
  /// In en, this message translates to:
  /// **'• Shows the setups selected in the table above in their current sort order.\n• The y-axis represents adjustment values.\n• Select at least two setups to display a trend.\n• Tap a legend entry to highlight a specific line.\n• Long-press a legend entry to remove it from the selection.'**
  String get componentDetailsLineChartInfo;

  /// Info text of the activity histogram section on the component details.
  ///
  /// In en, this message translates to:
  /// **'• Shows how many Strava activities were ridden with each adjustment value.\n• Counts all setups in the table above, not just the selected ones.\n• Numerical values are grouped into ranges when there are many distinct values.\n• Tap a legend entry to show a different adjustment.\n• Long-press a legend entry to remove its column.'**
  String get componentDetailsHistogramInfo;

  /// Snackbar action that starts adding the missing item.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get snackbarAdd;

  /// Error snackbar when a component is added while no bike exists.
  ///
  /// In en, this message translates to:
  /// **'Add a bike first'**
  String get componentAddBikeFirst;

  /// Snackbar after copying task rules to a component. {count} is the number of tasks, {name} the component name.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copied 1 task to \'{name}\'.} other{Copied {count} tasks to \'{name}\'.}}'**
  String componentTasksCopied(int count, String name);

  /// Snackbar after adding recommended task rules to a component. {count} is the number of tasks, {name} the component name.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 task to \'{name}\'.} other{Added {count} tasks to \'{name}\'.}}'**
  String componentTasksAdded(int count, String name);

  /// Snackbar after a component was swapped for an existing one. {oldName} is the retired component, {newName} the replacement.
  ///
  /// In en, this message translates to:
  /// **'Replaced \'{oldName}\' with \'{newName}\'.'**
  String componentReplaced(String oldName, String newName);

  /// Part of the list of items trashed along with a component. {count} is the number of subcomponents.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 subcomponent} other{{count} subcomponents}}'**
  String componentTrashedSubcomponents(int count);

  /// Line of the snackbar after removing a component whose subcomponents were uninstalled. {count} is their number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 subcomponent uninstalled.} other{{count} subcomponents uninstalled.}}'**
  String componentSubcomponentsUninstalled(int count);

  /// Line of the snackbar after removing a component whose subcomponents moved to its bike. {count} is their number, {bike} the bike name.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 subcomponent installed on \'{bike}\'.} other{{count} subcomponents installed on \'{bike}\'.}}'**
  String componentSubcomponentsInstalledOnBike(int count, String bike);

  /// First line of the snackbar after deleting a component. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Component \'{name}\' moved to trash.'**
  String componentMovedToTrash(String name);

  /// Snackbar after restoring a component from the trash. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Component \'{name}\' restored from trash.'**
  String componentRestoredFromTrash(String name);

  /// Button that archives an item.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// Option in the archive and remove sheets. {bike} is the bike name.
  ///
  /// In en, this message translates to:
  /// **'Install subcomponents on \'{bike}\''**
  String installSubcomponentsOnBike(String bike);

  /// Description of the option that installs subcomponents on the bike.
  ///
  /// In en, this message translates to:
  /// **'They are installed directly on the bike.'**
  String get installSubcomponentsOnBikeHint;

  /// Description of the option that archives or removes only the component itself.
  ///
  /// In en, this message translates to:
  /// **'Subcomponents are kept. Choose what happens to them below.'**
  String get subcomponentsKeepHint;

  /// Title of the archive component sheet. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Archive \'{name}\''**
  String archiveComponentTitle(String name);

  /// Explanation in the archive component sheet. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Other components are mounted on \'{name}\'. Choose whether they are archived along with it.'**
  String archiveComponentIntro(String name);

  /// Option in the archive component sheet.
  ///
  /// In en, this message translates to:
  /// **'Archive with subcomponents'**
  String get archiveWithSubcomponents;

  /// Description of the option that archives subcomponents too.
  ///
  /// In en, this message translates to:
  /// **'They stay mounted and are archived along with it.'**
  String get archiveWithSubcomponentsHint;

  /// Option in the archive component sheet. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Archive only \'{name}\''**
  String archiveOnly(String name);

  /// Title of the remove component sheet. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Remove \'{name}\''**
  String removeComponentTitle(String name);

  /// Explanation in the remove component sheet. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Other components are mounted on \'{name}\'. Choose what happens to them.'**
  String removeComponentIntro(String name);

  /// Option in the remove component sheet.
  ///
  /// In en, this message translates to:
  /// **'Remove with subcomponents'**
  String get removeWithSubcomponents;

  /// Description of the option that trashes the subcomponents too. {count} includes the component itself.
  ///
  /// In en, this message translates to:
  /// **'All {count} components are moved to the trash.'**
  String removeWithSubcomponentsHint(int count);

  /// Option in the remove component sheet. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Remove only \'{name}\''**
  String removeOnly(String name);

  /// Option in the remove component sheet.
  ///
  /// In en, this message translates to:
  /// **'Keep subcomponents linked'**
  String get removeKeepLinked;

  /// Description of the option that leaves subcomponents mounted on the trashed component. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'They stay mounted on \'{name}\' and return with it when restored from the trash. Until then they are shown under uninstalled components with a missing parent.'**
  String removeKeepLinkedHint(String name);

  /// Label in the remove preview for items that go to the trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get removeOutcomeTrash;

  /// Label in the remove preview for subcomponents whose parent is trashed.
  ///
  /// In en, this message translates to:
  /// **'Missing parent'**
  String get removeOutcomeMissingParent;

  /// Button of the remove sheet when subcomponents go along. {count} includes the component itself.
  ///
  /// In en, this message translates to:
  /// **'Move {count} components to trash'**
  String removeMoveToTrashMany(int count);

  /// Button of the remove sheet when only the component is trashed.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get removeMoveToTrash;

  /// Title of the sheet that explains the installation timeline.
  ///
  /// In en, this message translates to:
  /// **'Installation history'**
  String get installationHintTitle;

  /// First paragraph of the installation timeline explanation sheet.
  ///
  /// In en, this message translates to:
  /// **'Track when you install, remove, move, or archive components. Set the date for each change to keep an accurate history. This lets your setups show only the components that were installed on the bike at that time.'**
  String get installationHintBody;

  /// Second paragraph of the installation timeline explanation sheet.
  ///
  /// In en, this message translates to:
  /// **'Without installation history, the app only saves the bike where this component is installed now. It does not save past installs or removals.'**
  String get installationHintWithout;

  /// Sentence appended to the second paragraph while the sheet offers the choice for the first time.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Settings.'**
  String get installationHintChangeAnytime;

  /// Title of the sample timeline in the explanation sheet.
  ///
  /// In en, this message translates to:
  /// **'Example timeline'**
  String get installationHintExample;

  /// Name of the first sample bike in the example timeline.
  ///
  /// In en, this message translates to:
  /// **'Trail bike'**
  String get installationHintExampleTrailBike;

  /// Name of the second sample bike in the example timeline.
  ///
  /// In en, this message translates to:
  /// **'Enduro bike'**
  String get installationHintExampleEnduroBike;

  /// Button of the explanation sheet that turns the installation timeline on.
  ///
  /// In en, this message translates to:
  /// **'Activate now'**
  String get installationHintActivate;

  /// Button of the explanation sheet that keeps the installation timeline off.
  ///
  /// In en, this message translates to:
  /// **'Continue without tracking'**
  String get installationHintDecline;

  /// Button that reveals items that were hidden by default.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// Empty state of the installed-on picker while searching. {query} is the search text.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\"'**
  String parentPickerNoMatches(String query);

  /// Note under the installed-on picker about parts that are not suggested. {count} is their number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 part hidden} other{{count} parts hidden}}'**
  String parentPickerHidden(int count);

  /// Note under the installed-on picker about parts that are not suggested for the component's type. {count} is their number, {type} the type name.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 part hidden · unusual for a {type}} other{{count} parts hidden · unusual for a {type}}}'**
  String parentPickerHiddenUnusual(int count, String type);

  /// Placeholder of the search field of the installed-on picker.
  ///
  /// In en, this message translates to:
  /// **'Search bikes and parts…'**
  String get parentPickerSearchHint;

  /// Section title of the bikes in the installed-on picker.
  ///
  /// In en, this message translates to:
  /// **'Bikes'**
  String get parentPickerBikes;

  /// Section title in the installed-on picker for components whose parent no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Components with a missing parent'**
  String get parentPickerMissingParent;

  /// Section title in the installed-on picker for components that are not installed.
  ///
  /// In en, this message translates to:
  /// **'Uninstalled components'**
  String get parentPickerUninstalled;

  /// Section title in the installed-on picker for archived components.
  ///
  /// In en, this message translates to:
  /// **'Archived components'**
  String get parentPickerArchived;

  /// Section title in the installed-on picker for the components mounted on a bike. {bike} is the bike name.
  ///
  /// In en, this message translates to:
  /// **'Components on {bike}'**
  String parentPickerOnBike(String bike);

  /// Reason shown under a component in the installed-on picker that cannot become a parent because it sits on another component.
  ///
  /// In en, this message translates to:
  /// **'Mounted on a component itself'**
  String get parentFieldMountedOnComponent;

  /// Entry of the installed-on field for a component that is not installed.
  ///
  /// In en, this message translates to:
  /// **'UNINSTALLED'**
  String get parentFieldUninstalled;

  /// Entry of the installed-on field for an archived component.
  ///
  /// In en, this message translates to:
  /// **'ARCHIVED'**
  String get parentFieldArchived;

  /// Hint in the installed-on picker that offers to turn on the installation timeline.
  ///
  /// In en, this message translates to:
  /// **'Keep a dated history of where this part was installed, so setups and ride stats match the parts that were really on the bike.'**
  String get parentFieldTimelineHint;

  /// Note in the installed-on picker. A component that carries parts cannot itself be mounted on a component. {count} is the number of parts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Can\'t mount on a component while it carries 1 part} other{Can\'t mount on a component while it carries {count} parts}}'**
  String parentFieldDepthCap(int count);

  /// Placeholder of the installed-on field while nothing is selected.
  ///
  /// In en, this message translates to:
  /// **'Select Bike'**
  String get parentFieldSelectBike;

  /// Hint on a bike card in the garage while a component is dragged. {bike} is the bike name.
  ///
  /// In en, this message translates to:
  /// **'Drag here to install on {bike}'**
  String garageDragToInstall(String bike);

  /// Hint on a bike card while a dragged component hovers over it. {bike} is the bike name.
  ///
  /// In en, this message translates to:
  /// **'Release to install to {bike}'**
  String garageReleaseToInstall(String bike);

  /// Hint on the uninstalled area while an archived component hovers over it.
  ///
  /// In en, this message translates to:
  /// **'Release to unarchive'**
  String get garageReleaseToUnarchive;

  /// Hint on the uninstalled area while a component hovers over it.
  ///
  /// In en, this message translates to:
  /// **'Release to uninstall component'**
  String get garageReleaseToUninstall;

  /// Hint on the uninstalled area while a subcomponent hovers over it. {parent} is the component it is mounted on.
  ///
  /// In en, this message translates to:
  /// **'Release to uninstall from {parent}'**
  String garageReleaseToUninstallFrom(String parent);

  /// Placeholder of the uninstalled area of the garage while it is empty.
  ///
  /// In en, this message translates to:
  /// **'Drag components here to uninstall from bike'**
  String get garageDragComponentsToUninstall;

  /// Second line of the empty uninstalled area of the garage.
  ///
  /// In en, this message translates to:
  /// **'or tap to add new'**
  String get garageOrTapToAdd;

  /// Hint on the uninstalled area while a component is dragged.
  ///
  /// In en, this message translates to:
  /// **'Drag here to uninstall'**
  String get garageDragToUninstall;

  /// Hint on the uninstalled area while a subcomponent is dragged. {parent} is the component it is mounted on.
  ///
  /// In en, this message translates to:
  /// **'Drag here to uninstall from {parent}'**
  String garageDragToUninstallFrom(String parent);

  /// Hint on the archive area while a component is dragged.
  ///
  /// In en, this message translates to:
  /// **'Drag here to archive'**
  String get garageDragToArchive;

  /// Hint on the archive area while a component hovers over it.
  ///
  /// In en, this message translates to:
  /// **'Release to archive'**
  String get garageReleaseToArchive;

  /// Title of the dialog shown when a component preset would add adjustments to a component that already has some.
  ///
  /// In en, this message translates to:
  /// **'Apply preset adjustments?'**
  String get applyPresetTitle;

  /// Body of the apply-preset dialog. {count} is the number of adjustments the component already has.
  ///
  /// In en, this message translates to:
  /// **'This component already has {count, plural, =1{1 adjustment} other{{count} adjustments}}. Replace them with the preset, or keep both?'**
  String applyPresetBody(int count);

  /// Dialog button that keeps the existing adjustments and adds the preset ones.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get applyPresetKeepBoth;

  /// Default title of the generic confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get confirmationTitle;

  /// Default body of the generic confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get confirmationBody;

  /// Title of the dialog shown when leaving a form with unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get discardChangesTitle;

  /// Body of the discard-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to exit without saving?'**
  String get discardChangesBody;

  /// Destructive button of the discard-changes dialog.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get discardChangesConfirm;

  /// Hint text of the text field in the rename dialog.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get renameNameHint;

  /// Confirm button of the rename dialog.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameConfirm;

  /// Title of the dialog that confirms disconnecting Strava.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Strava?'**
  String get stravaDisconnectTitle;

  /// Body of the Strava disconnect dialog.
  ///
  /// In en, this message translates to:
  /// **'This will revoke the app\'s access and delete all your synced activities from our secure storage. Your Strava account itself will not be affected.'**
  String get stravaDisconnectBody;

  /// Destructive button of the Strava disconnect dialog.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get stravaDisconnectConfirm;

  /// Label of the name field on the adjustment forms. {term} is "adjustment" or "attribute" (a rider attribute).
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Attribute Name} other{Adjustment Name}}'**
  String adjustmentNameLabel(String term);

  /// Hint of the name field on the adjustment forms. {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Enter Attribute Name} other{Enter Adjustment Name}}'**
  String adjustmentNameHint(String term);

  /// Validation error when the adjustment name is empty.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get adjustmentNameRequired;

  /// Warning under the name field when the adjustment name is long.
  ///
  /// In en, this message translates to:
  /// **'Short names display better in other views.'**
  String get adjustmentNameTooLong;

  /// Hint of the notes field on the adjustment forms.
  ///
  /// In en, this message translates to:
  /// **'Enter measuring procedure/instrument/...'**
  String get adjustmentNotesHint;

  /// Helper text under the notes field of an adjustment form once notes are entered.
  ///
  /// In en, this message translates to:
  /// **'View these notes by tapping the ⓘ icon next to the name.'**
  String get adjustmentNotesHelper;

  /// Collapsed label of the preview bar at the bottom of the adjustment forms.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get adjustmentPreviewTitle;

  /// Label of the expanded preview bar on the adjustment forms.
  ///
  /// In en, this message translates to:
  /// **'Preview only — changes won’t be saved!'**
  String get adjustmentPreviewExpanded;

  /// App bar title of the On/Off adjustment form (add mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Add On/Off Attribute} other{Add On/Off Adjustment}}'**
  String adjustmentPageAddBoolean(String term);

  /// App bar title of the On/Off adjustment form (edit mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Edit On/Off Attribute} other{Edit On/Off Adjustment}}'**
  String adjustmentPageEditBoolean(String term);

  /// App bar title of the Categorical adjustment form (add mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Add Categorical Attribute} other{Add Categorical Adjustment}}'**
  String adjustmentPageAddCategorical(String term);

  /// App bar title of the Categorical adjustment form (edit mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Edit Categorical Attribute} other{Edit Categorical Adjustment}}'**
  String adjustmentPageEditCategorical(String term);

  /// App bar title of the Duration adjustment form (add mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Add Duration Attribute} other{Add Duration Adjustment}}'**
  String adjustmentPageAddDuration(String term);

  /// App bar title of the Duration adjustment form (edit mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Edit Duration Attribute} other{Edit Duration Adjustment}}'**
  String adjustmentPageEditDuration(String term);

  /// App bar title of the Numerical adjustment form (add mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Add Numerical Attribute} other{Add Numerical Adjustment}}'**
  String adjustmentPageAddNumerical(String term);

  /// App bar title of the Numerical adjustment form (edit mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Edit Numerical Attribute} other{Edit Numerical Adjustment}}'**
  String adjustmentPageEditNumerical(String term);

  /// App bar title of the SAG adjustment form (add mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Add SAG Attribute} other{Add SAG Adjustment}}'**
  String adjustmentPageAddSag(String term);

  /// App bar title of the SAG adjustment form (edit mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Edit SAG Attribute} other{Edit SAG Adjustment}}'**
  String adjustmentPageEditSag(String term);

  /// App bar title of the Step adjustment form (add mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Add Step Attribute} other{Add Step Adjustment}}'**
  String adjustmentPageAddStep(String term);

  /// App bar title of the Step adjustment form (edit mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Edit Step Attribute} other{Edit Step Adjustment}}'**
  String adjustmentPageEditStep(String term);

  /// App bar title of the Text adjustment form (add mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Add Text Attribute} other{Add Text Adjustment}}'**
  String adjustmentPageAddText(String term);

  /// App bar title of the Text adjustment form (edit mode). {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Edit Text Attribute} other{Edit Text Adjustment}}'**
  String adjustmentPageEditText(String term);

  /// Validation error when a categorical adjustment has no options.
  ///
  /// In en, this message translates to:
  /// **'At least one option is required.'**
  String get adjustmentOptionsAtLeastOne;

  /// Validation error shown under the options when two options are equal.
  ///
  /// In en, this message translates to:
  /// **'Options must be unique.'**
  String get adjustmentOptionsUniqueError;

  /// Validation error on an empty option field.
  ///
  /// In en, this message translates to:
  /// **'Option is required'**
  String get adjustmentOptionRequired;

  /// Validation error on an option field when two options are equal.
  ///
  /// In en, this message translates to:
  /// **'Options must be unique'**
  String get adjustmentOptionUnique;

  /// Heading above the option fields of a categorical adjustment.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get adjustmentOptionsTitle;

  /// Generic text button that adds an item.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel;

  /// Label of one option field. {number} is its position, starting at 1.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String adjustmentOptionLabel(int number);

  /// Hint of an option field.
  ///
  /// In en, this message translates to:
  /// **'Enter option value'**
  String get adjustmentOptionHint;

  /// Tooltip of the button that removes an option field.
  ///
  /// In en, this message translates to:
  /// **'Remove option'**
  String get adjustmentOptionRemoveTooltip;

  /// Title of the switch that allows picking several options.
  ///
  /// In en, this message translates to:
  /// **'Multi Select'**
  String get adjustmentMultiSelectTitle;

  /// Subtitle of the multi select switch.
  ///
  /// In en, this message translates to:
  /// **'Allow more than one selection'**
  String get adjustmentMultiSelectSubtitle;

  /// Title of the switch that lets an option be picked several times.
  ///
  /// In en, this message translates to:
  /// **'Count Occurrences'**
  String get adjustmentCountTitle;

  /// Subtitle of the count occurrences switch.
  ///
  /// In en, this message translates to:
  /// **'Allow the same option multiple times'**
  String get adjustmentCountSubtitle;

  /// Short name of the minimum of a range.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get labelMin;

  /// Short name of the maximum of a range.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get labelMax;

  /// Label of the optional minimum duration field.
  ///
  /// In en, this message translates to:
  /// **'Min Duration (optional)'**
  String get adjustmentMinDurationLabel;

  /// Hint of the minimum duration field.
  ///
  /// In en, this message translates to:
  /// **'Select minimum duration'**
  String get adjustmentMinDurationHint;

  /// Label of the optional maximum duration field.
  ///
  /// In en, this message translates to:
  /// **'Max Duration (optional)'**
  String get adjustmentMaxDurationLabel;

  /// Hint of the maximum duration field.
  ///
  /// In en, this message translates to:
  /// **'Select maximum duration'**
  String get adjustmentMaxDurationHint;

  /// Label of the optional minimum value field.
  ///
  /// In en, this message translates to:
  /// **'Min Value (optional)'**
  String get adjustmentMinValueOptionalLabel;

  /// Label of the optional maximum value field.
  ///
  /// In en, this message translates to:
  /// **'Max Value (optional)'**
  String get adjustmentMaxValueOptionalLabel;

  /// Label of the required minimum value field.
  ///
  /// In en, this message translates to:
  /// **'Min Value'**
  String get adjustmentMinValueLabel;

  /// Label of the required maximum value field.
  ///
  /// In en, this message translates to:
  /// **'Max Value'**
  String get adjustmentMaxValueLabel;

  /// Hint of the minimum value field.
  ///
  /// In en, this message translates to:
  /// **'Enter minimum value'**
  String get adjustmentMinValueHint;

  /// Hint of the maximum value field.
  ///
  /// In en, this message translates to:
  /// **'Enter maximum value'**
  String get adjustmentMaxValueHint;

  /// Title of the banner that offers converting a numerical adjustment to a SAG adjustment.
  ///
  /// In en, this message translates to:
  /// **'Convert to SAG adjustment'**
  String get adjustmentConvertToSagTitle;

  /// Body of the convert-to-SAG banner.
  ///
  /// In en, this message translates to:
  /// **'Unlocks entering and reading sag in mm as well as %.'**
  String get adjustmentConvertToSagBody;

  /// Validation error when a numeric field has no valid number.
  ///
  /// In en, this message translates to:
  /// **'Valid number required'**
  String get adjustmentValidNumberRequired;

  /// Validation error when the maximum is below the minimum.
  ///
  /// In en, this message translates to:
  /// **'Max must be greater than min'**
  String get adjustmentMaxGreaterThanMin;

  /// Notice shown when the unit of an adjustment changes to a convertible unit.
  ///
  /// In en, this message translates to:
  /// **'{oldUnit} can be converted to {newUnit}.'**
  String adjustmentUnitConvertible(String oldUnit, String newUnit);

  /// Label of the unit field.
  ///
  /// In en, this message translates to:
  /// **'Unit (optional)'**
  String get adjustmentUnitLabel;

  /// Hint of the unit field.
  ///
  /// In en, this message translates to:
  /// **'Choose a unit'**
  String get adjustmentUnitHint;

  /// Shown in the unit field when no unit is chosen.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get adjustmentUnitNone;

  /// Menu entry that converts a SAG adjustment to a plain numerical one.
  ///
  /// In en, this message translates to:
  /// **'Convert to plain numerical'**
  String get adjustmentConvertToNumerical;

  /// Label of the reference travel field for a fork.
  ///
  /// In en, this message translates to:
  /// **'Fork Travel'**
  String get adjustmentTravelFork;

  /// Label of the reference travel field for a shock.
  ///
  /// In en, this message translates to:
  /// **'Shock Stroke'**
  String get adjustmentTravelShock;

  /// Label of the reference travel field for other component types.
  ///
  /// In en, this message translates to:
  /// **'Travel / Stroke'**
  String get adjustmentTravelGeneric;

  /// Hint of the reference travel field for a fork.
  ///
  /// In en, this message translates to:
  /// **'e.g. 160'**
  String get adjustmentTravelHintFork;

  /// Hint of the reference travel field for a shock.
  ///
  /// In en, this message translates to:
  /// **'e.g. 65 (stroke, not rear travel)'**
  String get adjustmentTravelHintShock;

  /// Hint of the reference travel field for other component types.
  ///
  /// In en, this message translates to:
  /// **'e.g. 160 fork, 65 shock stroke'**
  String get adjustmentTravelHintGeneric;

  /// Label of the optional travel field. {label} is the travel name.
  ///
  /// In en, this message translates to:
  /// **'{label} (optional)'**
  String adjustmentTravelOptionalLabel(String label);

  /// Helper text under the empty reference travel field.
  ///
  /// In en, this message translates to:
  /// **'Add it to enter and read sag in mm as well as %.'**
  String get adjustmentTravelHelper;

  /// Validation error when a number is zero or negative.
  ///
  /// In en, this message translates to:
  /// **'Must be greater than 0'**
  String get adjustmentMustBePositive;

  /// Label of the step size field.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get adjustmentStepLabel;

  /// Hint of the step size field.
  ///
  /// In en, this message translates to:
  /// **'Enter step value'**
  String get adjustmentStepHint;

  /// Validation error on an empty step size.
  ///
  /// In en, this message translates to:
  /// **'Step is required'**
  String get adjustmentStepRequired;

  /// Validation error when the step size is not a positive number.
  ///
  /// In en, this message translates to:
  /// **'Valid step greater than zero is required'**
  String get adjustmentStepInvalid;

  /// Validation error on an empty minimum.
  ///
  /// In en, this message translates to:
  /// **'Min is required'**
  String get adjustmentMinRequired;

  /// Validation error when the minimum is not a number.
  ///
  /// In en, this message translates to:
  /// **'Valid min value is required'**
  String get adjustmentMinInvalid;

  /// Validation error on an empty maximum.
  ///
  /// In en, this message translates to:
  /// **'Max is required'**
  String get adjustmentMaxRequired;

  /// Validation error when the maximum is not a number.
  ///
  /// In en, this message translates to:
  /// **'Valid max value is required'**
  String get adjustmentMaxInvalid;

  /// Validation error when the range does not fit a single step.
  ///
  /// In en, this message translates to:
  /// **'Max must be greater than min+step'**
  String get adjustmentMaxGreaterThanMinStep;

  /// Tooltip of the dial style button.
  ///
  /// In en, this message translates to:
  /// **'Change dial color and size'**
  String get adjustmentDialTooltip;

  /// Label of the dial style field.
  ///
  /// In en, this message translates to:
  /// **'Dial'**
  String get adjustmentDialLabel;

  /// Label of the visualization dropdown of a step adjustment.
  ///
  /// In en, this message translates to:
  /// **'Visualization'**
  String get adjustmentVisualizationLabel;

  /// Hint of the visualization dropdown. {term} is "adjustment" or "attribute".
  ///
  /// In en, this message translates to:
  /// **'{term, select, attribute{Choose a visualization for this attribute} other{Choose a visualization for this adjustment}}'**
  String adjustmentVisualizationHint(String term);

  /// Placeholder of the visualization dropdown.
  ///
  /// In en, this message translates to:
  /// **'Please select visualization'**
  String get adjustmentVisualizationPlaceholder;

  /// Validation error when no visualization is chosen.
  ///
  /// In en, this message translates to:
  /// **'Visualization cannot be empty'**
  String get adjustmentVisualizationRequired;

  /// Button that sets a value for an optional adjustment.
  ///
  /// In en, this message translates to:
  /// **'Set value'**
  String get setValueButton;

  /// Validation error when a categorical value contains options the adjustment no longer has.
  ///
  /// In en, this message translates to:
  /// **'Contains options that no longer exist'**
  String get setCategoricalMissingOptions;

  /// Validation error when several options are selected on a single-select adjustment.
  ///
  /// In en, this message translates to:
  /// **'Only one option can be selected'**
  String get setCategoricalSingleOnly;

  /// Validation error when an option is selected twice but counting is off.
  ///
  /// In en, this message translates to:
  /// **'An option cannot be selected more than once'**
  String get setCategoricalNoDuplicates;

  /// Validation error when a single-select adjustment has no option.
  ///
  /// In en, this message translates to:
  /// **'Please select an option'**
  String get setCategoricalSelectOption;

  /// Placeholder of the categorical value field.
  ///
  /// In en, this message translates to:
  /// **'Please select'**
  String get setCategoricalPlaceholder;

  /// Tooltip of the button that reverts a value to its initial one.
  ///
  /// In en, this message translates to:
  /// **'Revert'**
  String get revertTooltip;

  /// Hint of the numerical value field.
  ///
  /// In en, this message translates to:
  /// **'Please enter'**
  String get setNumericalHint;

  /// Validation error on an empty value field.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get setValueRequired;

  /// Validation error when the value is not a number.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get setNumberInvalid;

  /// Validation error when a value is above the maximum. {value} is the maximum with its unit.
  ///
  /// In en, this message translates to:
  /// **'Max {value}'**
  String setNumericalMax(String value);

  /// Validation error when a value is below the minimum. {value} is the minimum with its unit.
  ///
  /// In en, this message translates to:
  /// **'Min {value}'**
  String setNumericalMin(String value);

  /// Hint of the text value field.
  ///
  /// In en, this message translates to:
  /// **'Enter Text'**
  String get setTextHint;

  /// Validation error when a text value looks like a duration.
  ///
  /// In en, this message translates to:
  /// **'Pure Duration Format not allowed. Add characters or use Duration Adjustment type.'**
  String get setTextPureDuration;

  /// Note under a stored categorical value that is no longer one of the options.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t match the current options'**
  String get outdatedValueOptions;

  /// Note under a stored step value that no longer fits the range or step.
  ///
  /// In en, this message translates to:
  /// **'Outside the current range or step'**
  String get outdatedValueRangeOrStep;

  /// Note under a stored value that is outside the adjustment range.
  ///
  /// In en, this message translates to:
  /// **'Outside the current range'**
  String get outdatedValueRange;

  /// Screen reader label of an adjustment value that changed between setups.
  ///
  /// In en, this message translates to:
  /// **'{name}, changed from {previous} to {current}'**
  String adjustmentChangedFromTo(String name, String previous, String current);

  /// Screen reader label of a comparison row whose values differ. {label} is the adjustment name.
  ///
  /// In en, this message translates to:
  /// **'Different {label}'**
  String compareRowDifferent(String label);

  /// Title of the setup comparison sheet.
  ///
  /// In en, this message translates to:
  /// **'Setup comparison'**
  String get compareTitle;

  /// Tooltip of the button that swaps the two compared setups.
  ///
  /// In en, this message translates to:
  /// **'Swap A and B'**
  String get compareSwapTooltip;

  /// Title of the sheet that picks a setup to compare. {side} is A or B.
  ///
  /// In en, this message translates to:
  /// **'Choose setup {side}'**
  String compareChooseSetup(String side);

  /// Subtitle of a comparison card whose component has no adjustments.
  ///
  /// In en, this message translates to:
  /// **'No adjustments'**
  String get compareNoAdjustments;

  /// Subtitle of a comparison card. {differenceCount} of {totalCount} values differ between the two setups.
  ///
  /// In en, this message translates to:
  /// **'{differenceCount}/{totalCount} values {differenceCount, plural, =1{differs} other{differ}}'**
  String compareValuesDiffer(int differenceCount, int totalCount);

  /// Snackbar shown when both comparison sides are the same setup.
  ///
  /// In en, this message translates to:
  /// **'Choose two different setups to compare.'**
  String get compareChooseTwoDifferent;

  /// Title of the hint shown when a compared setup was deleted.
  ///
  /// In en, this message translates to:
  /// **'A setup is no longer available'**
  String get compareSetupUnavailableTitle;

  /// Hint of the setup-unavailable message in the comparison sheet.
  ///
  /// In en, this message translates to:
  /// **'Close this sheet and choose two available setups to compare.'**
  String get compareSetupUnavailableHint;

  /// Title shown when the two compared setups have identical values.
  ///
  /// In en, this message translates to:
  /// **'These setups have no value differences'**
  String get compareNoDifferencesTitle;

  /// Title shown when there are no values to compare.
  ///
  /// In en, this message translates to:
  /// **'No comparable values'**
  String get compareNoComparableTitle;

  /// Hint that switches the comparison from differences only to all values.
  ///
  /// In en, this message translates to:
  /// **'Show every recorded value instead.'**
  String get compareShowAllHint;

  /// Hint shown when the setups have no values.
  ///
  /// In en, this message translates to:
  /// **'No setup values are available to compare.'**
  String get compareNoValuesHint;

  /// Badge shown when the context (place, weather) of the two setups differs.
  ///
  /// In en, this message translates to:
  /// **'Context varies'**
  String get compareContextVaries;

  /// Segment of the comparison filter that shows only differing values. {count} is their number.
  ///
  /// In en, this message translates to:
  /// **'Differences ({count})'**
  String compareFilterDifferences(int count);

  /// Segment of the comparison filter that shows all values.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get compareFilterAll;

  /// Section title for the context (place, weather) of a setup.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get setupSectionContext;

  /// Section title for the adjustment values of a setup.
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get setupSectionValues;

  /// Section title for the feedback of a setup.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get setupSectionFeedback;

  /// Name shown for a setup without a name.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Setup'**
  String get setupUnnamed;

  /// Positive answer button of a yes/no dialog.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Negative answer button of a yes/no dialog.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Menu entry that shares an item.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Setup menu entry that restores the values of this setup.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get setupOptionRestore;

  /// Setup menu entry that opens the comparison.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get setupOptionCompare;

  /// Setup menu entry that adds feedback.
  ///
  /// In en, this message translates to:
  /// **'Add Feedback'**
  String get setupOptionAddFeedback;

  /// Setup menu entry that shows the setup on the map.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get setupOptionViewOnMap;

  /// Setup menu entry that opens the place in the maps app.
  ///
  /// In en, this message translates to:
  /// **'Open in maps app'**
  String get setupOptionOpenInMaps;

  /// Tooltip of the bookmark button of a setup.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get setupTooltipBookmark;

  /// Tooltip of the bookmark button of a bookmarked setup.
  ///
  /// In en, this message translates to:
  /// **'Remove Bookmark'**
  String get setupTooltipRemoveBookmark;

  /// Title of a group of setups. {count} is the number of setups.
  ///
  /// In en, this message translates to:
  /// **'{count} Setups'**
  String setupGroupTitle(int count);

  /// Shown in an embedded setup tile that has no changed values.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get setupTileNoChanges;

  /// Shown in an embedded setup tile that has no values.
  ///
  /// In en, this message translates to:
  /// **'No values'**
  String get setupTileNoValues;

  /// Title of the empty setup list when filters hide everything.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches this filter'**
  String get setupListFilteredTitle;

  /// Subtitle of the empty setup list when filters hide everything.
  ///
  /// In en, this message translates to:
  /// **'Your filters are hiding all entries.'**
  String get setupListFilteredSubtitle;

  /// Title of the empty setup list.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get setupListEmptyTitle;

  /// Subtitle of the empty setup list.
  ///
  /// In en, this message translates to:
  /// **'Record your first setup to start tracking your adjustments.'**
  String get setupListEmptySubtitle;

  /// Button of the empty setup list.
  ///
  /// In en, this message translates to:
  /// **'Record a setup'**
  String get setupListEmptyAction;

  /// Explanation in the tags sheet of a setup.
  ///
  /// In en, this message translates to:
  /// **'Use tags to group and organize your setups. For example, to categorize by specific test sessions, tracks, or terrains.'**
  String get setupTagsSubtitle;

  /// Snackbar shown when a setup is started without any bike.
  ///
  /// In en, this message translates to:
  /// **'A bike is required to create a setup'**
  String get setupActionBikeRequired;

  /// Snackbar shown when a setup is started without any component.
  ///
  /// In en, this message translates to:
  /// **'A component is required to create a setup'**
  String get setupActionComponentRequired;

  /// Snackbar after bookmarking setups. {count} is the number of setups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Setup bookmarked.} other{{count} Setups bookmarked.}}'**
  String setupsBookmarked(int count);

  /// Snackbar after removing bookmarks. {count} is the number of setups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Bookmark removed from 1 Setup.} other{Bookmark removed from {count} Setups.}}'**
  String setupsBookmarkRemoved(int count);

  /// Title of the bulk tags sheet for setups.
  ///
  /// In en, this message translates to:
  /// **'Set Tags'**
  String get setupSetTagsTitle;

  /// Apply button of the bulk tags sheet. {count} is the number of setups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Apply to 1 Setup} other{Apply to {count} Setups}}'**
  String setupApplyTags(int count);

  /// Snackbar after changing tags. {count} is the number of setups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Tags updated for 1 Setup.} other{Tags updated for {count} Setups.}}'**
  String setupTagsUpdated(int count);

  /// Snackbar after a setup was removed.
  ///
  /// In en, this message translates to:
  /// **'Setup \'{name}\' moved to trash.'**
  String setupMovedToTrash(String name);

  /// Snackbar after a setup was restored.
  ///
  /// In en, this message translates to:
  /// **'Setup \'{name}\' restored from trash.'**
  String setupRestoredFromTrash(String name);

  /// Title of the sheet that adds an adjustment to a component.
  ///
  /// In en, this message translates to:
  /// **'Add Adjustment'**
  String get addAdjustmentTitle;

  /// Section header of the adjustment templates when no component type is chosen.
  ///
  /// In en, this message translates to:
  /// **'Pre-filled Templates'**
  String get addAdjustmentTemplates;

  /// Section header of the adjustment templates. {type} is the component type.
  ///
  /// In en, this message translates to:
  /// **'Suggested for {type}'**
  String addAdjustmentSuggested(String type);

  /// Section header of the adjustment templates once some were added.
  ///
  /// In en, this message translates to:
  /// **'Suggested for {type} · {added}/{total} added'**
  String addAdjustmentSuggestedProgress(String type, int added, int total);

  /// Title of the hint that asks for a component type before templates show.
  ///
  /// In en, this message translates to:
  /// **'Select a component type'**
  String get addAdjustmentSelectTypeTitle;

  /// Title of the hint shown when no templates exist.
  ///
  /// In en, this message translates to:
  /// **'No templates available'**
  String get addAdjustmentNoTemplatesTitle;

  /// Hint under the select-a-component-type title.
  ///
  /// In en, this message translates to:
  /// **'Templates are suggested per component type.'**
  String get addAdjustmentTemplatesPerType;

  /// Hint under the no-templates title.
  ///
  /// In en, this message translates to:
  /// **'Select a component type first.'**
  String get addAdjustmentSelectTypeFirst;

  /// Shown when all templates of the component type were added.
  ///
  /// In en, this message translates to:
  /// **'Add a custom adjustment below.'**
  String get addAdjustmentAllAdded;

  /// Shown when the component type has no templates.
  ///
  /// In en, this message translates to:
  /// **'No templates available.'**
  String get addAdjustmentNoTemplates;

  /// Section header of the custom adjustment types.
  ///
  /// In en, this message translates to:
  /// **'Custom Adjustment'**
  String get addAdjustmentCustom;

  /// Name of the numerical adjustment type.
  ///
  /// In en, this message translates to:
  /// **'Numerical Adjustment'**
  String get adjustmentTypeNumerical;

  /// Examples for the numerical adjustment type.
  ///
  /// In en, this message translates to:
  /// **'Pressure (psi/bar), Length, Angle, Weight'**
  String get adjustmentTypeNumericalHint;

  /// Name of the step adjustment type.
  ///
  /// In en, this message translates to:
  /// **'Step Adjustment'**
  String get adjustmentTypeStep;

  /// Examples for the step adjustment type.
  ///
  /// In en, this message translates to:
  /// **'Rebound/Compression clicks, Spacers, Increments'**
  String get adjustmentTypeStepHint;

  /// Name of the categorical adjustment type.
  ///
  /// In en, this message translates to:
  /// **'Categorical Adjustment'**
  String get adjustmentTypeCategorical;

  /// Examples for the categorical adjustment type.
  ///
  /// In en, this message translates to:
  /// **'Tire Compound (soft/hard), Brand, Style, Mode'**
  String get adjustmentTypeCategoricalHint;

  /// Name of the on/off adjustment type.
  ///
  /// In en, this message translates to:
  /// **'On/Off Adjustment'**
  String get adjustmentTypeBoolean;

  /// Examples for the on/off adjustment type.
  ///
  /// In en, this message translates to:
  /// **'Lockout, Climb switch, Component installed? Yes/No'**
  String get adjustmentTypeBooleanHint;

  /// Name of the text adjustment type.
  ///
  /// In en, this message translates to:
  /// **'Text Adjustment'**
  String get adjustmentTypeText;

  /// Examples for the text adjustment type.
  ///
  /// In en, this message translates to:
  /// **'Notes, advanced settings details'**
  String get adjustmentTypeTextHint;

  /// Name of the duration adjustment type.
  ///
  /// In en, this message translates to:
  /// **'Duration Adjustment'**
  String get adjustmentTypeDuration;

  /// Examples for the duration adjustment type.
  ///
  /// In en, this message translates to:
  /// **'Time Span'**
  String get adjustmentTypeDurationHint;

  /// Error when a new option equals an existing option.
  ///
  /// In en, this message translates to:
  /// **'Already exists'**
  String get setCategoricalDuplicate;

  /// Error shown when the value contains options the adjustment no longer has.
  ///
  /// In en, this message translates to:
  /// **'Some selected options no longer exist.'**
  String get setCategoricalDanglingError;

  /// Error shown when several options are selected on a single-select adjustment.
  ///
  /// In en, this message translates to:
  /// **'Multiple options selected, but only one is allowed.'**
  String get setCategoricalMultipleError;

  /// Title shown when an adjustment has no options.
  ///
  /// In en, this message translates to:
  /// **'No options yet'**
  String get setCategoricalEmptyTitle;

  /// Hint shown when options can only be added by editing the adjustment.
  ///
  /// In en, this message translates to:
  /// **'Edit this adjustment to add options.'**
  String get setCategoricalEmptyEdit;

  /// Hint shown when options can be added in the sheet.
  ///
  /// In en, this message translates to:
  /// **'Tap + below to add the first option.'**
  String get setCategoricalEmptyAdd;

  /// Tooltip of the button that adds an option.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get setCategoricalAddTooltip;

  /// Hint of the new option field.
  ///
  /// In en, this message translates to:
  /// **'New option'**
  String get setCategoricalNewHint;

  /// Tooltip of a selected option that the adjustment no longer has.
  ///
  /// In en, this message translates to:
  /// **'This option no longer exists'**
  String get setCategoricalDanglingTooltip;

  /// Title of the sheet that sets the trail condition.
  ///
  /// In en, this message translates to:
  /// **'Select Trail Condition'**
  String get setConditionTitle;

  /// Explanation in the trail condition sheet.
  ///
  /// In en, this message translates to:
  /// **'Conditions are automatically calculated based on soil moisture (see weather data). You can manually adjust the trail condition here:'**
  String get setConditionInfo;

  /// Error when a new tag equals an existing tag.
  ///
  /// In en, this message translates to:
  /// **'Tag already exists'**
  String get tagAlreadyExists;

  /// Shown in a tags sheet that has no tags.
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get tagsEmpty;

  /// Tooltip of a tag that all selected items carry.
  ///
  /// In en, this message translates to:
  /// **'On all — tap to remove from all'**
  String get tagsBulkOnAll;

  /// Tooltip of a tag that some selected items carry.
  ///
  /// In en, this message translates to:
  /// **'On {count} of {total} — tap to add to all'**
  String tagsBulkOnSome(int count, int total);

  /// Tooltip of a tag that no selected item carries.
  ///
  /// In en, this message translates to:
  /// **'On none — tap to add to all'**
  String get tagsBulkOnNone;

  /// Explanation of half-filled tag chips in the bulk tags sheet.
  ///
  /// In en, this message translates to:
  /// **'Half-filled tags apply to only part of your selection — they stay that way unless you tap them.'**
  String get tagsBulkHalfFilled;

  /// Title of the unit picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose Unit'**
  String get unitPickerTitle;

  /// Heading of the custom unit chips.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get unitPickerCustom;

  /// Chip that opens the custom unit field.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get unitPickerOther;

  /// Label of the custom unit field.
  ///
  /// In en, this message translates to:
  /// **'Custom unit'**
  String get unitPickerCustomLabel;

  /// Hint of the custom unit field.
  ///
  /// In en, this message translates to:
  /// **'Enter a custom unit'**
  String get unitPickerCustomHint;

  /// Title of the weather sheet.
  ///
  /// In en, this message translates to:
  /// **'Weather Context'**
  String get weatherSheetTitle;

  /// Shown in the weather sheet when no location is set.
  ///
  /// In en, this message translates to:
  /// **'Update Weather is not possible without location.'**
  String get weatherNeedsLocation;

  /// Label of the weather code field.
  ///
  /// In en, this message translates to:
  /// **'Weather Code'**
  String get weatherCodeLabel;

  /// Hint of the weather code field.
  ///
  /// In en, this message translates to:
  /// **'Choose Weather Code'**
  String get weatherCodeHint;

  /// Label of the temperature field. {unit} is the temperature unit.
  ///
  /// In en, this message translates to:
  /// **'Current Air Temperature in {unit}.'**
  String weatherTemperatureLabel(String unit);

  /// Hint of the temperature field.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get weatherTemperatureHint;

  /// Label of the precipitation field. {unit} is the precipitation unit.
  ///
  /// In en, this message translates to:
  /// **'Accumulated Precipitation since midnight in {unit}'**
  String weatherPrecipitationLabel(String unit);

  /// Hint of the precipitation field.
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get weatherPrecipitationHint;

  /// Label of the humidity field.
  ///
  /// In en, this message translates to:
  /// **'Current Relative Air Humidity as percentage value'**
  String get weatherHumidityLabel;

  /// Hint of the humidity field.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get weatherHumidityHint;

  /// Label of the wind speed field. {unit} is the wind speed unit.
  ///
  /// In en, this message translates to:
  /// **'Current Wind Speed in {unit}'**
  String weatherWindLabel(String unit);

  /// Hint of the wind speed field.
  ///
  /// In en, this message translates to:
  /// **'Wind Speed'**
  String get weatherWindHint;

  /// Label of the soil moisture field.
  ///
  /// In en, this message translates to:
  /// **'Average Soil Moisture 0-7cm'**
  String get weatherSoilLabel;

  /// Hint of the soil moisture field.
  ///
  /// In en, this message translates to:
  /// **'Soil Moisture'**
  String get weatherSoilHint;

  /// Validation error for a negative weather value.
  ///
  /// In en, this message translates to:
  /// **'Value cannot be negative'**
  String get weatherValueNegative;

  /// Validation error for a humidity outside 0 to 100.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid value in the range 0..100 %'**
  String get weatherHumidityRange;

  /// Attribution link of the weather data.
  ///
  /// In en, this message translates to:
  /// **'Weather data by Open-Meteo.com'**
  String get weatherAttribution;

  /// Button that fetches the weather for the location.
  ///
  /// In en, this message translates to:
  /// **'Update Weather by Location'**
  String get weatherUpdateByLocation;

  /// Description of WMO weather code 0.
  ///
  /// In en, this message translates to:
  /// **'Clear sky'**
  String get weatherCode0;

  /// Description of WMO weather code 1.
  ///
  /// In en, this message translates to:
  /// **'Mainly clear'**
  String get weatherCode1;

  /// Description of WMO weather code 2.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherCode2;

  /// Description of WMO weather code 3.
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get weatherCode3;

  /// Description of WMO weather code 45.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherCode45;

  /// Description of WMO weather code 48.
  ///
  /// In en, this message translates to:
  /// **'Depositing rime fog'**
  String get weatherCode48;

  /// Description of WMO weather code 51.
  ///
  /// In en, this message translates to:
  /// **'Light drizzle'**
  String get weatherCode51;

  /// Description of WMO weather code 53.
  ///
  /// In en, this message translates to:
  /// **'Moderate drizzle'**
  String get weatherCode53;

  /// Description of WMO weather code 55.
  ///
  /// In en, this message translates to:
  /// **'Dense drizzle'**
  String get weatherCode55;

  /// Description of WMO weather code 56.
  ///
  /// In en, this message translates to:
  /// **'Light freezing drizzle'**
  String get weatherCode56;

  /// Description of WMO weather code 57.
  ///
  /// In en, this message translates to:
  /// **'Dense freezing drizzle'**
  String get weatherCode57;

  /// Description of WMO weather code 61.
  ///
  /// In en, this message translates to:
  /// **'Slight rain'**
  String get weatherCode61;

  /// Description of WMO weather code 63.
  ///
  /// In en, this message translates to:
  /// **'Moderate rain'**
  String get weatherCode63;

  /// Description of WMO weather code 65.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain'**
  String get weatherCode65;

  /// Description of WMO weather code 66.
  ///
  /// In en, this message translates to:
  /// **'Light freezing rain'**
  String get weatherCode66;

  /// Description of WMO weather code 67.
  ///
  /// In en, this message translates to:
  /// **'Heavy freezing rain'**
  String get weatherCode67;

  /// Description of WMO weather code 71.
  ///
  /// In en, this message translates to:
  /// **'Slight snow fall'**
  String get weatherCode71;

  /// Description of WMO weather code 73.
  ///
  /// In en, this message translates to:
  /// **'Moderate snow fall'**
  String get weatherCode73;

  /// Description of WMO weather code 75.
  ///
  /// In en, this message translates to:
  /// **'Heavy snow fall'**
  String get weatherCode75;

  /// Description of WMO weather code 77.
  ///
  /// In en, this message translates to:
  /// **'Snow grains'**
  String get weatherCode77;

  /// Description of WMO weather code 80.
  ///
  /// In en, this message translates to:
  /// **'Slight rain showers'**
  String get weatherCode80;

  /// Description of WMO weather code 81.
  ///
  /// In en, this message translates to:
  /// **'Moderate rain showers'**
  String get weatherCode81;

  /// Description of WMO weather code 82.
  ///
  /// In en, this message translates to:
  /// **'Violent rain showers'**
  String get weatherCode82;

  /// Description of WMO weather code 85.
  ///
  /// In en, this message translates to:
  /// **'Slight snow showers'**
  String get weatherCode85;

  /// Description of WMO weather code 86.
  ///
  /// In en, this message translates to:
  /// **'Heavy snow showers'**
  String get weatherCode86;

  /// Description of WMO weather code 95.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherCode95;

  /// Description of WMO weather code 96.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm with slight hail'**
  String get weatherCode96;

  /// Description of WMO weather code 99.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm with heavy hail'**
  String get weatherCode99;

  /// Description of an unknown weather code.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get weatherCodeUnknown;

  /// Title of the location sheet.
  ///
  /// In en, this message translates to:
  /// **'Location Context'**
  String get locationSheetTitle;

  /// Title of the notice shown when location services are off.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// Hint of the location-services-off notice.
  ///
  /// In en, this message translates to:
  /// **'Enable location services, then try GPS again'**
  String get locationServicesDisabledHint;

  /// Button that opens the system settings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationOpenSettings;

  /// Title of the notice shown when location permission was denied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// Hint of the permission-denied notice.
  ///
  /// In en, this message translates to:
  /// **'Try GPS again to request permission'**
  String get locationPermissionDeniedHint;

  /// Title of the notice shown when location permission was denied for good.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied'**
  String get locationPermissionForever;

  /// Hint of the permanently-denied notice.
  ///
  /// In en, this message translates to:
  /// **'Allow location access in app settings, then try again'**
  String get locationPermissionForeverHint;

  /// Title of the notice shown when the location request timed out.
  ///
  /// In en, this message translates to:
  /// **'Location request timed out'**
  String get locationTimeout;

  /// Hint of the timeout notice.
  ///
  /// In en, this message translates to:
  /// **'Move to an open area and try GPS again'**
  String get locationTimeoutHint;

  /// Title of the notice shown when the location failed.
  ///
  /// In en, this message translates to:
  /// **'Could not determine location'**
  String get locationUndetermined;

  /// Hint of the location-failed notice.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try GPS again'**
  String get locationUndeterminedHint;

  /// Title of the notice shown when the elevation lookup failed.
  ///
  /// In en, this message translates to:
  /// **'Fetching Elevation failed'**
  String get locationElevationFailed;

  /// Hint of the elevation-failed notice.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection'**
  String get locationElevationFailedHint;

  /// Title of the notice shown when the address lookup failed.
  ///
  /// In en, this message translates to:
  /// **'Fetching Address failed'**
  String get locationAddressFailed;

  /// Hint of the address-failed notice.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and spelling'**
  String get locationAddressFailedHint;

  /// Label and hint of the latitude field.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get locationLatitude;

  /// Label and hint of the longitude field.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get locationLongitude;

  /// Validation error for a latitude out of range.
  ///
  /// In en, this message translates to:
  /// **'Latitude must be between -90..90°'**
  String get locationLatitudeRange;

  /// Validation error for a longitude out of range.
  ///
  /// In en, this message translates to:
  /// **'Longitude must be between -180..180°'**
  String get locationLongitudeRange;

  /// Label of the altitude field. {unit} is the altitude unit.
  ///
  /// In en, this message translates to:
  /// **'Altitude in {unit}'**
  String locationAltitudeLabel(String unit);

  /// Hint of the altitude field.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get locationAltitudeHint;

  /// Button that looks up the address of the coordinates.
  ///
  /// In en, this message translates to:
  /// **'Update Address from Latitude/Longitude'**
  String get locationUpdateAddress;

  /// Label of the address search field.
  ///
  /// In en, this message translates to:
  /// **'Enter street, city, or landmark and press Search Icon'**
  String get locationAddressSearchLabel;

  /// Hint of the address search field.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get locationAddressHint;

  /// Button that fetches the GPS location.
  ///
  /// In en, this message translates to:
  /// **'Find Location via GPS'**
  String get locationFindByGps;

  /// Error shown when an address lookup has no coordinates.
  ///
  /// In en, this message translates to:
  /// **'Could not find address without latitude and longitude'**
  String get locationNoCoordinatesForAddress;

  /// Error shown when the address search has no result.
  ///
  /// In en, this message translates to:
  /// **'No Address found'**
  String get locationNoAddressFound;

  /// Error shown when the address search found no location.
  ///
  /// In en, this message translates to:
  /// **'Could not find location.'**
  String get locationNotFound;

  /// Error shown when the system location settings could not be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open location settings.'**
  String get locationSettingsOpenFailed;

  /// Error shown when the app settings could not be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open app settings.'**
  String get locationAppSettingsOpenFailed;

  /// Placeholder title of the bike tab when adding is not allowed.
  ///
  /// In en, this message translates to:
  /// **'No bike adjustments to change'**
  String get setupTabNoBikeAdjustments;

  /// Subtitle of the empty bike tab.
  ///
  /// In en, this message translates to:
  /// **'Add a component to this bike to start tracking adjustments'**
  String get setupTabAddComponentSubtitle;

  /// Subtitle of a component card in a setup. {count} is its number of adjustments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No adjustments yet.} =1{1 adjustment} other{{count} adjustments}}'**
  String setupAdjustmentCount(int count);

  /// Subtitle of a rider card in a setup. {count} is its number of attributes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No attributes yet.} =1{1 attribute} other{{count} attributes}}'**
  String setupAttributeCount(int count);

  /// Title of the card with values whose adjustment no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Dangling Adjustment Values'**
  String get setupDanglingAdjustmentsTitle;

  /// Cause shown on the dangling adjustment values card.
  ///
  /// In en, this message translates to:
  /// **'Component with adjustment was deleted'**
  String get setupDanglingAdjustmentsCause;

  /// Title of the card with values whose attribute no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Dangling Attribute Values'**
  String get setupDanglingAttributesTitle;

  /// Cause shown on the dangling attribute values card.
  ///
  /// In en, this message translates to:
  /// **'Attribute was deleted'**
  String get setupDanglingAttributesCause;

  /// Subtitle of a component card whose component was not installed at the setup.
  ///
  /// In en, this message translates to:
  /// **'Component was not installed at setup time'**
  String get setupComponentNotInstalled;

  /// Subtitle of a rider card whose rider is not linked to the setup.
  ///
  /// In en, this message translates to:
  /// **'Rider is not linked to this setup'**
  String get setupRiderNotLinked;

  /// Title of the empty rider tab.
  ///
  /// In en, this message translates to:
  /// **'No rider linked'**
  String get setupTabNoRiderTitle;

  /// Subtitle of the empty rider tab.
  ///
  /// In en, this message translates to:
  /// **'Link a rider to this bike to track rider attributes'**
  String get setupTabNoRiderSubtitle;

  /// Menu entry that links an existing rider to the bike.
  ///
  /// In en, this message translates to:
  /// **'Link \'{name}\''**
  String setupTabLinkRider(String name);

  /// Menu entry that creates a rider for the bike.
  ///
  /// In en, this message translates to:
  /// **'Create new rider'**
  String get setupTabCreateRider;

  /// Button that opens the rider link menu.
  ///
  /// In en, this message translates to:
  /// **'Link rider'**
  String get setupTabLinkRiderButton;

  /// Button that opens the previous setup.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get setupDetailsPrev;

  /// Button that opens the next setup.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get setupDetailsNext;

  /// Tooltip of the setup actions menu.
  ///
  /// In en, this message translates to:
  /// **'Setup actions'**
  String get setupDetailsActionsTooltip;

  /// Shown when a setup has no location.
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get setupDetailsLocationUnavailable;

  /// Title of the feedback placeholder of a setup.
  ///
  /// In en, this message translates to:
  /// **'No feedback yet'**
  String get setupDetailsNoFeedbackTitle;

  /// Subtitle of the feedback placeholder of a setup.
  ///
  /// In en, this message translates to:
  /// **'Tap to note how this setup rode'**
  String get setupDetailsNoFeedbackSubtitle;

  /// Title shown when the setup does not exist.
  ///
  /// In en, this message translates to:
  /// **'Setup not found'**
  String get setupDetailsNotFoundTitle;

  /// Subtitle shown when the setup does not exist.
  ///
  /// In en, this message translates to:
  /// **'This setup was deleted or is no longer available.'**
  String get setupDetailsNotFoundSubtitle;

  /// Name of the name column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get setupColumnName;

  /// Name of the notes column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get setupColumnNotes;

  /// Name of the tags column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get setupColumnTags;

  /// Name of the date column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get setupColumnDate;

  /// Name of the time column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get setupColumnTime;

  /// Name of the place column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get setupColumnPlace;

  /// Name of the altitude column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get setupColumnAltitude;

  /// Name of the bike column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get setupColumnBike;

  /// Name of the bookmarked column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get setupColumnBookmarked;

  /// Name of the activities column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get setupColumnActivities;

  /// Name of the weather code column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Weather Code'**
  String get setupColumnWeatherCode;

  /// Name of the temperature column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get setupColumnTemperature;

  /// Name of the precipitation column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get setupColumnPrecipitation;

  /// Name of the humidity column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get setupColumnHumidity;

  /// Name of the windspeed column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Windspeed'**
  String get setupColumnWindSpeed;

  /// Name of the soil moisture column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Soil Moisture'**
  String get setupColumnSoilMoisture;

  /// Name of the condition column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get setupColumnCondition;

  /// Name of the test session column of the setup table.
  ///
  /// In en, this message translates to:
  /// **'Test session'**
  String get setupColumnTestSession;

  /// Heading of the general context columns in the column picker.
  ///
  /// In en, this message translates to:
  /// **'General Context'**
  String get tableSectionGeneralContext;

  /// Heading of the weather context columns in the column picker.
  ///
  /// In en, this message translates to:
  /// **'Weather Context'**
  String get tableSectionWeatherContext;

  /// Heading of the component adjustments columns in the column picker.
  ///
  /// In en, this message translates to:
  /// **'Component Adjustments'**
  String get tableSectionComponentAdjustments;

  /// Heading of the rider attributes columns in the column picker.
  ///
  /// In en, this message translates to:
  /// **'Rider Attributes'**
  String get tableSectionPersonAttributes;

  /// Heading of the feedback columns in the column picker.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get tableSectionFeedback;

  /// App bar title of the setup form in edit mode.
  ///
  /// In en, this message translates to:
  /// **'Edit Setup'**
  String get setupFormEditTitle;

  /// App bar title of the setup form for the first run of a test session.
  ///
  /// In en, this message translates to:
  /// **'First Run'**
  String get setupFormFirstRun;

  /// App bar title of the setup form for a later run of a test session.
  ///
  /// In en, this message translates to:
  /// **'Next Run'**
  String get setupFormNextRun;

  /// Label of the setup name field.
  ///
  /// In en, this message translates to:
  /// **'Setup Name'**
  String get setupFormNameLabel;

  /// Hint of the setup name field.
  ///
  /// In en, this message translates to:
  /// **'Enter setup name'**
  String get setupFormNameHint;

  /// Hint of the setup notes field.
  ///
  /// In en, this message translates to:
  /// **'Add notes (optional)'**
  String get setupFormNotesHint;

  /// Tooltip and sheet title of the tags button of the setup form.
  ///
  /// In en, this message translates to:
  /// **'Add Tags'**
  String get setupFormAddTags;

  /// Label of the bike field of the setup form.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get setupFormBikeLabel;

  /// Hint of the bike field of the setup form.
  ///
  /// In en, this message translates to:
  /// **'Choose a bike for this setup'**
  String get setupFormBikeHint;

  /// Validation error when no bike is chosen.
  ///
  /// In en, this message translates to:
  /// **'Bike cannot be empty.'**
  String get setupFormBikeEmpty;

  /// Validation error when the chosen bike does not exist.
  ///
  /// In en, this message translates to:
  /// **'Please select valid bike'**
  String get setupFormBikeInvalid;

  /// Error on the bike field when editing a setup of a bike with a running test session.
  ///
  /// In en, this message translates to:
  /// **'A test session is running on this bike. End it before editing its setups.'**
  String get setupFormSessionRunningEdit;

  /// Error on the bike field when recording a setup on a bike with a running test session.
  ///
  /// In en, this message translates to:
  /// **'A test session is running on this bike. End it before recording a setup.'**
  String get setupFormSessionRunningRecord;

  /// Label next to a bike in the bike dropdown that has a running test session.
  ///
  /// In en, this message translates to:
  /// **'Session running'**
  String get setupFormSessionRunning;

  /// Snackbar shown when a run is dated before the previous run.
  ///
  /// In en, this message translates to:
  /// **'A run must be after the previous run of its test session.'**
  String get setupFormRunOrder;

  /// Snackbar shown when fetching the location failed because services are off.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get setupFormLocationDisabled;

  /// Snackbar shown when fetching the location failed because permission is missing.
  ///
  /// In en, this message translates to:
  /// **'Location permission was not granted.'**
  String get setupFormLocationNoPermission;

  /// Snackbar shown when fetching the location failed because permission is denied for good.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied.'**
  String get setupFormLocationDeniedForever;

  /// Snackbar shown when the location request timed out.
  ///
  /// In en, this message translates to:
  /// **'Location request timed out.'**
  String get setupFormLocationTimeout;

  /// Snackbar shown when fetching the location failed.
  ///
  /// In en, this message translates to:
  /// **'Error fetching location.'**
  String get setupFormLocationError;

  /// Snackbar shown when updating the address without a location.
  ///
  /// In en, this message translates to:
  /// **'Cannot update address without location.'**
  String get setupFormAddressNeedsLocation;

  /// Snackbar shown when fetching the address failed.
  ///
  /// In en, this message translates to:
  /// **'Error fetching address.'**
  String get setupFormAddressError;

  /// Snackbar shown when updating the weather without a location.
  ///
  /// In en, this message translates to:
  /// **'Cannot update weather without location.'**
  String get setupFormWeatherNeedsLocation;

  /// Snackbar shown when fetching the weather failed.
  ///
  /// In en, this message translates to:
  /// **'Error fetching weather.'**
  String get setupFormWeatherError;

  /// Location chip text when the address lookup failed.
  ///
  /// In en, this message translates to:
  /// **'Address Error'**
  String get setupFormChipAddressError;

  /// Location chip text when location services are off.
  ///
  /// In en, this message translates to:
  /// **'No GPS Service'**
  String get setupFormChipNoGpsService;

  /// Location chip text when permission is missing.
  ///
  /// In en, this message translates to:
  /// **'No GPS Permission'**
  String get setupFormChipNoGpsPermission;

  /// Location chip text when the location request timed out.
  ///
  /// In en, this message translates to:
  /// **'GPS Timeout'**
  String get setupFormChipGpsTimeout;

  /// Location chip text when the location failed.
  ///
  /// In en, this message translates to:
  /// **'Location Error'**
  String get setupFormChipLocationError;

  /// Weather chip text when the weather lookup failed.
  ///
  /// In en, this message translates to:
  /// **'Weather Error'**
  String get setupFormChipWeatherError;

  /// Title of the dialog shown when the previous setup changed while editing.
  ///
  /// In en, this message translates to:
  /// **'Previous Setup has changed. Reset Values?'**
  String get setupFormResetTitle;

  /// Body of the dialog shown when the previous setup changed while editing.
  ///
  /// In en, this message translates to:
  /// **'Your current unsaved adjustments were based on the old setup. Resetting the values will discard these changes.'**
  String get setupFormResetBody;

  /// Help text of the date picker of the setup form.
  ///
  /// In en, this message translates to:
  /// **'Select Setup Date'**
  String get setupFormPickDate;

  /// Error text of the date picker of the setup form.
  ///
  /// In en, this message translates to:
  /// **'Date cannot be in the future'**
  String get setupFormDateInFuture;

  /// Help text of the time picker of the setup form.
  ///
  /// In en, this message translates to:
  /// **'Select Setup Time'**
  String get setupFormPickTime;

  /// Snackbar shown when the chosen time is in the future.
  ///
  /// In en, this message translates to:
  /// **'Date and Time cannot be in the future.'**
  String get setupFormDateTimeInFuture;

  /// Title of the dialog that asks whether to fetch the weather again.
  ///
  /// In en, this message translates to:
  /// **'Update Weather?'**
  String get updateWeatherTitle;

  /// Body of the dialog that asks whether to fetch the weather again.
  ///
  /// In en, this message translates to:
  /// **'Do you want to fetch the latest weather data for this location, date and time?'**
  String get updateWeatherBody;

  /// Used in the test session notice when the source setup is unknown. Follows "rides" / "fährt mit".
  ///
  /// In en, this message translates to:
  /// **'the setup to compare'**
  String get setupFormSessionFromFallback;

  /// The source setup in the test session notice. {name} is its name.
  ///
  /// In en, this message translates to:
  /// **'\'{name}\''**
  String setupFormSessionFromSetup(String name);

  /// Notice on the first run of a tournament test session. {from} is the source setup.
  ///
  /// In en, this message translates to:
  /// **'The first run rides {from}. Its adjustments are locked so the setups stay comparable. Set the date, weather and notes of this ride, then save to start the session.'**
  String setupFormSessionFirstTournament(String from);

  /// Notice on a later run of a tournament test session. {from} is the source setup.
  ///
  /// In en, this message translates to:
  /// **'This run rides {from}. Its adjustments are locked so the setups stay comparable.'**
  String setupFormSessionNextTournament(String from);

  /// Notice on the first run of a non-tournament test session.
  ///
  /// In en, this message translates to:
  /// **'This is the base setup the session starts from. If your bike is set up like this, just save. Otherwise change the session\'s adjustments to match your bike.'**
  String get setupFormSessionFirstBase;

  /// Notice on a later run of a non-tournament test session.
  ///
  /// In en, this message translates to:
  /// **'Only the adjustments of the session can change, locked ones stay as they are. Everything else is copied from the previous run.'**
  String get setupFormSessionNextBase;

  /// Title of the test session notice on the first run. {name} is the session name.
  ///
  /// In en, this message translates to:
  /// **'First run of \'{name}\''**
  String setupFormSessionFirstRunTitle(String name);

  /// Title of the test session notice on a later run. {name} is the session name.
  ///
  /// In en, this message translates to:
  /// **'Run of \'{name}\''**
  String setupFormSessionRunTitle(String name);

  /// Hint under the weight field of the setup guide card. {name} is the rider.
  ///
  /// In en, this message translates to:
  /// **'Saved with this setup as {name}\'s riding weight'**
  String setupFormGuideWeightSaved(String name);

  /// Hint under the weight field of the setup guide card when no rider attribute is used.
  ///
  /// In en, this message translates to:
  /// **'Only used for these recommendations'**
  String get setupFormGuideWeightLocal;

  /// Button of the setup guide card that adds a riding weight attribute to the rider.
  ///
  /// In en, this message translates to:
  /// **'Add riding weight to {name}'**
  String setupFormGuideAddWeight(String name);

  /// Snackbar after a riding weight attribute was added to the rider.
  ///
  /// In en, this message translates to:
  /// **'Added riding weight to {name}'**
  String setupFormGuideWeightAdded(String name);

  /// Snackbar after applying all recommended values. {count} is their number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Applied 1 recommended value} other{Applied {count} recommended values}}'**
  String setupFormGuideApplied(int count);

  /// Line added to the setup notes after applying all recommended values. {guides} lists the guide names.
  ///
  /// In en, this message translates to:
  /// **'Started from recommended values ({guides})'**
  String guideNotesLine(String guides);

  /// Title of the location card when the setup has no address.
  ///
  /// In en, this message translates to:
  /// **'No Address available'**
  String get contextNoAddress;

  /// Row of the location card. {latitude} and {longitude} are the formatted coordinates.
  ///
  /// In en, this message translates to:
  /// **'Latitude/Longitude: {latitude}°/{longitude}°'**
  String contextLatLon(String latitude, String longitude);

  /// Row of the location card. {value} is the altitude with its unit.
  ///
  /// In en, this message translates to:
  /// **'Altitude: {value}'**
  String contextAltitude(String value);

  /// Title of the weather card. {label} is the weather description.
  ///
  /// In en, this message translates to:
  /// **'Weather: {label}'**
  String contextWeather(String label);

  /// Row of the weather card. {value} is the temperature with its unit.
  ///
  /// In en, this message translates to:
  /// **'Temperature: {value}'**
  String contextTemperature(String value);

  /// Row of the weather card. {value} is the precipitation with its unit.
  ///
  /// In en, this message translates to:
  /// **'Precipitation: {value}'**
  String contextPrecipitation(String value);

  /// Row of the weather card. {value} is the humidity with its unit.
  ///
  /// In en, this message translates to:
  /// **'Humidity: {value}'**
  String contextHumidity(String value);

  /// Row of the weather card. {value} is the wind speed with its unit.
  ///
  /// In en, this message translates to:
  /// **'Windspeed: {value}'**
  String contextWindSpeed(String value);

  /// Row of the weather card. {value} is the soil moisture with its unit.
  ///
  /// In en, this message translates to:
  /// **'Soil Moisture: {value}'**
  String contextSoilMoisture(String value);

  /// Entry of the map menu in the setup comparison. {label} is A or B.
  ///
  /// In en, this message translates to:
  /// **'Open {label} in maps app'**
  String contextOpenPointInMaps(String label);

  /// Row of the bike card when the setup has no rider.
  ///
  /// In en, this message translates to:
  /// **'No rider linked to this setup.'**
  String get contextNoRiderLinked;

  /// Shown when the test session of a setup no longer exists.
  ///
  /// In en, this message translates to:
  /// **'TEST SESSION NOT FOUND'**
  String get testSessionNotFound;

  /// Badge of an adjustment that does not count toward the rating score.
  ///
  /// In en, this message translates to:
  /// **'not scored'**
  String get adjustmentNotScored;

  /// Chip of an adjustment card. {step} is the step size.
  ///
  /// In en, this message translates to:
  /// **'Step {step}'**
  String adjustmentChipStep(String step);

  /// Chip of a text adjustment card.
  ///
  /// In en, this message translates to:
  /// **'Free text'**
  String get adjustmentChipFreeText;

  /// Shown on an adjustment card that has no constraints.
  ///
  /// In en, this message translates to:
  /// **'Any value'**
  String get adjustmentChipAnyValue;

  /// Legend entry for a value recorded for the first time.
  ///
  /// In en, this message translates to:
  /// **'Initial Value'**
  String get legendInitialValue;

  /// Legend entry for a value that changed.
  ///
  /// In en, this message translates to:
  /// **'Changed Value'**
  String get legendChangedValue;

  /// Legend entry for a value whose owner was not part of the setup.
  ///
  /// In en, this message translates to:
  /// **'Dangling Value'**
  String get legendDanglingValue;

  /// Header of the group of templates that were already added. {count} is their number.
  ///
  /// In en, this message translates to:
  /// **'Already added ({count})'**
  String adjustmentPresetAlreadyAdded(int count);

  /// Title shown when all suggested templates were added.
  ///
  /// In en, this message translates to:
  /// **'All suggestions added'**
  String get adjustmentPresetAllAdded;

  /// Name of a task that is not linked to a bike or a component.
  ///
  /// In en, this message translates to:
  /// **'General Task'**
  String get taskGeneral;

  /// Shown instead of the task name when the task of an entry no longer exists.
  ///
  /// In en, this message translates to:
  /// **'TASK NOT FOUND'**
  String get taskNotFound;

  /// Unit word after a number of days, without the number. {count} only selects singular or plural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String taskUnitDays(int count);

  /// Unit word after a number of weeks, without the number. {count} only selects singular or plural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{week} other{weeks}}'**
  String taskUnitWeeks(int count);

  /// Unit word after a number of months, without the number. {count} only selects singular or plural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{month} other{months}}'**
  String taskUnitMonths(int count);

  /// Unit word after a number of years, without the number. {count} only selects singular or plural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{year} other{years}}'**
  String taskUnitYears(int count);

  /// Unit word after a number of rides, without the number. {count} only selects singular or plural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{ride} other{rides}}'**
  String taskUnitRides(int count);

  /// Recurring interval in days, inside a sentence. {count} is the number of days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{every day} other{every {count} days}}'**
  String taskIntervalEveryDays(int count);

  /// Recurring interval in weeks, inside a sentence. {count} is the number of weeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{every week} other{every {count} weeks}}'**
  String taskIntervalEveryWeeks(int count);

  /// Recurring interval in months, inside a sentence. {count} is the number of months.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{every month} other{every {count} months}}'**
  String taskIntervalEveryMonths(int count);

  /// Recurring interval in years, inside a sentence. {count} is the number of years.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{every year} other{every {count} years}}'**
  String taskIntervalEveryYears(int count);

  /// Recurring interval, inside a sentence. {value} is the amount with its unit, like 2,000 km.
  ///
  /// In en, this message translates to:
  /// **'every {value}'**
  String taskIntervalEvery(String value);

  /// Start of the interval line of a repeating task. The amount follows, like Every 500 km.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get taskIntervalPrefixEvery;

  /// Start of the interval line of a task that does not repeat. The amount follows, like After 500 km. German avoids the case ending a literal translation would need.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get taskIntervalPrefixAfter;

  /// Interval line of a task that repeats daily, instead of the prefix and an amount. German needs the case ending a literal Every 1 day would miss.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get taskIntervalCardEveryDay;

  /// Interval line of a task that repeats after every ride, instead of the prefix and an amount. German needs the gender a literal Every 1 ride would miss.
  ///
  /// In en, this message translates to:
  /// **'Every ride'**
  String get taskIntervalCardEveryRide;

  /// First line of the note of a task created from a recommendation. It is stored with the note. {interval} is the interval, like every 6 months.
  ///
  /// In en, this message translates to:
  /// **'Recommended interval: {interval}'**
  String taskRecommendedInterval(String interval);

  /// Added to the recommended interval line when no Strava is connected. Keep the leading space. {interval} is the ride-based interval that applies with Strava.
  ///
  /// In en, this message translates to:
  /// **' (time-based; {interval} with Strava)'**
  String taskRecommendedTimeBased(String interval);

  /// Origin line of a recommended task when it falls back to a time-based interval. {interval} is the interval that applies with Strava.
  ///
  /// In en, this message translates to:
  /// **'Time-based · {interval} with Strava'**
  String taskSuggestionTimeBased(String interval);

  /// Origin line of a recommended task. {type} is the component type.
  ///
  /// In en, this message translates to:
  /// **'Typical interval for {type}'**
  String taskSuggestionTypical(String type);

  /// Forecast of when a task becomes due.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get taskForecastToday;

  /// Forecast of when a task becomes due.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get taskForecastTomorrow;

  /// Forecast of when a task becomes due. {count} is the number of days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 day} other{in {count} days}}'**
  String taskForecastInDays(int count);

  /// Forecast of when a task becomes due. {count} is the number of weeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 week} other{in {count} weeks}}'**
  String taskForecastInWeeks(int count);

  /// Tooltip of the due forecast on a task card.
  ///
  /// In en, this message translates to:
  /// **'Forecast for when this task will become due. Exact for date and duration intervals; for other intervals it is estimated from recent riding activity and needs a connected Strava subscription.'**
  String get taskForecastTooltip;

  /// Progress of a task toward its interval. {amount} is the amount left with its unit, like 12 km.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String taskRemaining(String amount);

  /// Progress of a task past its interval. {amount} is the amount over with its unit, like 12 km.
  ///
  /// In en, this message translates to:
  /// **'{amount} exceeded'**
  String taskExceeded(String amount);

  /// Snackbar after a task was renamed. {count} is the number of entries renamed with it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Renamed 1 corresponding Task Entry.} other{Renamed {count} corresponding Task Entries.}}'**
  String taskActionRenamedEntries(int count);

  /// Snackbar after changing the priority. {priority} is the new priority, {count} the number of tasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Priority set to \'{priority}\' for 1 Task.} other{Priority set to \'{priority}\' for {count} Tasks.}}'**
  String taskActionPrioritySet(int count, String priority);

  /// Title of the sheet that sets the tags of selected tasks.
  ///
  /// In en, this message translates to:
  /// **'Set Tags'**
  String get taskSetTagsTitle;

  /// Explanation in the tags sheets of a task.
  ///
  /// In en, this message translates to:
  /// **'Use tags to group and organize your tasks (e.g. maintenance, order list, setup test, ...)'**
  String get taskTagsSubtitle;

  /// Apply button of the bulk tags sheet. {count} is the number of tasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Apply to 1 Task} other{Apply to {count} Tasks}}'**
  String taskApplyTags(int count);

  /// Snackbar after changing tags. {count} is the number of tasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Tags updated for 1 Task.} other{Tags updated for {count} Tasks.}}'**
  String taskTagsUpdated(int count);

  /// Snackbar after removing tasks. {name} is the task if there is one, {count} the number of tasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Task \'{name}\' and corresponding entries moved to trash.} other{{count} Tasks and corresponding entries moved to trash.}}'**
  String taskRulesMovedToTrash(int count, String name);

  /// Snackbar after a task was restored.
  ///
  /// In en, this message translates to:
  /// **'Task \'{name}\' restored from trash.'**
  String taskRestoredFromTrash(String name);

  /// Snackbar after completing tasks. {name} is the task if there is one, {count} the number of tasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Task \'{name}\' completed.} other{{count} Tasks completed.}}'**
  String taskCompleted(int count, String name);

  /// Snackbar after removing task entries. {name} is the entry if there is one, {count} the number of entries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Task Entry \'{name}\' moved to trash.} other{{count} Task Entries moved to trash.}}'**
  String taskEntriesMovedToTrash(int count, String name);

  /// Snackbar after a task entry was restored.
  ///
  /// In en, this message translates to:
  /// **'Task Entry \'{name}\' restored from trash.'**
  String taskEntryRestoredFromTrash(String name);

  /// Used in a sentence when the component type is not known.
  ///
  /// In en, this message translates to:
  /// **'component'**
  String get taskComponentTypeFallback;

  /// Title of the priority sheet and of the priority section of the task filter.
  ///
  /// In en, this message translates to:
  /// **'Task Priority'**
  String get taskPriorityTitle;

  /// Title of the tags section of the task filter.
  ///
  /// In en, this message translates to:
  /// **'Task Tags'**
  String get taskFilterTagsTitle;

  /// Shown in the task filter when no task has a tag.
  ///
  /// In en, this message translates to:
  /// **'No task tags yet'**
  String get taskFilterTagsEmptyTitle;

  /// Hint below the empty tags title in the task filter.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit a Task Rule to add tags.'**
  String get taskFilterTagsEmptyHint;

  /// Tooltip of the remove button on the chip of the applied task preset.
  ///
  /// In en, this message translates to:
  /// **'Unlink preset (keeps values)'**
  String get taskPresetUnlinkTooltip;

  /// Menu entry, swipe label and sheet title for a task that has no delay yet.
  ///
  /// In en, this message translates to:
  /// **'Add Delay'**
  String get taskDelayAdd;

  /// Menu entry, swipe label and sheet title for a task that already has a delay.
  ///
  /// In en, this message translates to:
  /// **'Edit Delay'**
  String get taskDelayEdit;

  /// Warning on a task entry whose link differs from its task. {name} is what the entry is linked to.
  ///
  /// In en, this message translates to:
  /// **'Linked to {name}'**
  String taskEntryLinkedTo(String name);

  /// Button that adds a task.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get taskAdd;

  /// Header of the list section of due tasks.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get taskListDueNow;

  /// Header of the list section of tasks that are not due yet.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get taskListUpcoming;

  /// Header of the list section of completed tasks.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskListCompleted;

  /// Title of the empty task list.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get taskListEmptyTitle;

  /// Subtitle of the empty task list.
  ///
  /// In en, this message translates to:
  /// **'Add a task to track service intervals or other bike related todos.'**
  String get taskListEmptySubtitle;

  /// Button of the empty task list.
  ///
  /// In en, this message translates to:
  /// **'Add a task'**
  String get taskListEmptyAction;

  /// Title of the due section when filters hide the tasks that are due.
  ///
  /// In en, this message translates to:
  /// **'Nothing due in this view'**
  String get taskListFilteredTitle;

  /// Subtitle of the due section when filters hide the tasks that are due.
  ///
  /// In en, this message translates to:
  /// **'Priority or tag filters are hiding tasks that need attention.'**
  String get taskListFilteredSubtitle;

  /// Screen reader label of the button that collapses the upcoming section.
  ///
  /// In en, this message translates to:
  /// **'Show fewer upcoming tasks'**
  String get taskListShowFewerUpcoming;

  /// Screen reader label of the button that collapses the completed section.
  ///
  /// In en, this message translates to:
  /// **'Show fewer completed tasks'**
  String get taskListShowFewerCompleted;

  /// Screen reader label of the button that expands the upcoming section. {count} is the number of tasks.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} upcoming tasks'**
  String taskListShowAllUpcoming(int count);

  /// Screen reader label of the button that expands the completed section. {count} is the number of tasks.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} completed tasks'**
  String taskListShowAllCompleted(int count);

  /// Button that collapses a task list section.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get taskListShowLess;

  /// Button that expands a task list section. {count} is the number of tasks.
  ///
  /// In en, this message translates to:
  /// **'Show all ({count})'**
  String taskListShowAllCount(int count);

  /// Screen reader label of a list section header. {label} is the header with its count.
  ///
  /// In en, this message translates to:
  /// **'{label}. Scroll to section'**
  String taskListScrollToSection(String label);

  /// Title shown when no task is due.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get taskCaughtUpTitle;

  /// Subtitle shown when no task is due.
  ///
  /// In en, this message translates to:
  /// **'There are no tasks due right now.'**
  String get taskCaughtUpScope;

  /// Subtitle shown when no task of a bike is due. {name} is the bike.
  ///
  /// In en, this message translates to:
  /// **'{name} has no tasks due right now.'**
  String taskCaughtUpScopeBike(String name);

  /// Screen reader addition naming the next task. {name} is the task.
  ///
  /// In en, this message translates to:
  /// **'Next up: {name}.'**
  String taskCaughtUpNext(String name);

  /// Button below the caught up message.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get taskCaughtUpAction;

  /// Title of the open tasks tile of a bike or component.
  ///
  /// In en, this message translates to:
  /// **'Open Tasks'**
  String get taskOpenTasksTitle;

  /// Title of the open tasks tile when it is empty.
  ///
  /// In en, this message translates to:
  /// **'No open tasks'**
  String get taskOpenEmptyTitle;

  /// Subtitle of the open tasks tile when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Add a task to keep track of maintenance'**
  String get taskOpenEmptySubtitle;

  /// Title of the sheet that asks which related tasks are deleted along with a bike or component.
  ///
  /// In en, this message translates to:
  /// **'Delete related tasks?'**
  String get taskDeleteTitle;

  /// Explanation in the delete related tasks sheet.
  ///
  /// In en, this message translates to:
  /// **'Deleting a task also deletes its corresponding task entries.'**
  String get taskDeleteBody;

  /// Header of the task list in the delete sheet. {selected} of {total} tasks are checked.
  ///
  /// In en, this message translates to:
  /// **'Tasks ({selected} / {total})'**
  String taskDeleteCount(int selected, int total);

  /// Button of the delete sheet while no task is checked.
  ///
  /// In en, this message translates to:
  /// **'Continue without deleting tasks'**
  String get taskDeleteContinue;

  /// Button of the delete sheet. {count} is the number of checked tasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 task} other{Delete {count} tasks}}'**
  String taskDeleteButton(int count);

  /// Group header in the delete sheet for tasks of a component that no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Component not found'**
  String get taskGroupComponentNotFound;

  /// Marker on the group header of the component itself in the delete sheet.
  ///
  /// In en, this message translates to:
  /// **'This component'**
  String get taskGroupThisComponent;

  /// Marker on the group header of a subcomponent in the delete sheet.
  ///
  /// In en, this message translates to:
  /// **'Subcomponent'**
  String get taskGroupSubcomponent;

  /// Title of the sheet that copies tasks.
  ///
  /// In en, this message translates to:
  /// **'Copy tasks?'**
  String get taskSheetCopyTitle;

  /// Title of the sheet that recommends tasks. {name} is the component.
  ///
  /// In en, this message translates to:
  /// **'Recommended tasks for \'{name}\''**
  String taskSheetRecommendTitle(String name);

  /// Title of the sheet that copies and recommends tasks. {name} is the component.
  ///
  /// In en, this message translates to:
  /// **'Tasks for \'{name}\''**
  String taskSheetMergedTitle(String name);

  /// Description of the copy sheet. {name} is the component the tasks go to.
  ///
  /// In en, this message translates to:
  /// **'Pick the tasks to copy to \'{name}\'. Copies start fresh — the completion history stays with the original component.'**
  String taskSheetCopyDescription(String name);

  /// Description of the recommendation sheet.
  ///
  /// In en, this message translates to:
  /// **'Pick the tasks to add. Each one becomes a normal task you can edit later.'**
  String get taskSheetRecommendDescription;

  /// Description of the sheet that copies and recommends. {from} is the source component.
  ///
  /// In en, this message translates to:
  /// **'Copies start fresh — the completion history stays with \'{from}\'. Recommended tasks become normal tasks you can edit later.'**
  String taskSheetMergedDescription(String from);

  /// Description of the copy sheet when it opens after adding a component. {name} is the component the tasks go to.
  ///
  /// In en, this message translates to:
  /// **'Optional — pick the tasks to copy to \'{name}\'. Copies start fresh — the completion history stays with the original component.'**
  String taskSheetCopyDescriptionOptional(String name);

  /// Description of the recommendation sheet when it opens after adding a component.
  ///
  /// In en, this message translates to:
  /// **'Optional — pick the tasks to add. Each one becomes a normal task you can edit later.'**
  String get taskSheetRecommendDescriptionOptional;

  /// Description of the sheet that copies and recommends when it opens after adding a component. {from} is the source component.
  ///
  /// In en, this message translates to:
  /// **'Optional — copies start fresh — the completion history stays with \'{from}\'. Recommended tasks become normal tasks you can edit later.'**
  String taskSheetMergedDescriptionOptional(String from);

  /// Title of the task sheet after a component was added. {name} is the component.
  ///
  /// In en, this message translates to:
  /// **'\'{name}\' added'**
  String taskSheetAdded(String name);

  /// Title of the task sheet after a component was replaced. {name} is the component.
  ///
  /// In en, this message translates to:
  /// **'\'{name}\' replaced'**
  String taskSheetReplaced(String name);

  /// Question in the task sheet after adding a component. {from} is the source component.
  ///
  /// In en, this message translates to:
  /// **'Copy tasks from \'{from}\'?'**
  String taskSheetPromptCopy(String from);

  /// Question in the task sheet after adding a component. {type} is the component type.
  ///
  /// In en, this message translates to:
  /// **'Add tasks for this {type}?'**
  String taskSheetPromptRecommend(String type);

  /// Question in the task sheet after adding a component. {type} is the component type.
  ///
  /// In en, this message translates to:
  /// **'Set up tasks for this {type}?'**
  String taskSheetPromptMerged(String type);

  /// Snackbar after the task recommendations were switched off.
  ///
  /// In en, this message translates to:
  /// **'Task recommendations turned off. Turn them back on in Settings › Features › Task Presets.'**
  String get taskSheetRecommendationsOff;

  /// Header of the copied tasks when recommendations are shown too. {from} is the source component.
  ///
  /// In en, this message translates to:
  /// **'Copy from \'{from}\''**
  String taskSheetCopyFrom(String from);

  /// Header of the copied tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get taskSheetTasks;

  /// Header of the recommended tasks. {name} is the catalog model or the component type.
  ///
  /// In en, this message translates to:
  /// **'Recommended for {name}'**
  String taskSheetRecommendedFor(String name);

  /// Button that switches the task recommendations off.
  ///
  /// In en, this message translates to:
  /// **'Turn off recommendations'**
  String get taskSheetTurnOff;

  /// Main button of the copy sheet. {count} is the number of checked tasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copy 1 task} other{Copy {count} tasks}}'**
  String taskSheetCopyButton(int count);

  /// Main button of the recommendation sheet. {count} is the number of checked tasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 task} other{Add {count} tasks}}'**
  String taskSheetAddButton(int count);

  /// Secondary button of the copy sheet.
  ///
  /// In en, this message translates to:
  /// **'Continue without copying tasks'**
  String get taskSheetContinueWithoutCopy;

  /// Secondary button of the recommendation sheet.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get taskSheetNotNow;

  /// Label of the value field in the delay sheet.
  ///
  /// In en, this message translates to:
  /// **'Delay Value'**
  String get taskDelayValueLabel;

  /// Button in the delay sheet that sets a delay which makes the task due right away.
  ///
  /// In en, this message translates to:
  /// **'Make Due Now'**
  String get taskDelayMakeDueNow;

  /// Explanation of the task delay, in the delay sheet and the tooltip of the task form.
  ///
  /// In en, this message translates to:
  /// **'A delay postpones when this task becomes due, or brings it forward when negative, without changing its interval. It only applies once: completing the task clears the delay automatically.'**
  String get taskDelayExplanation;

  /// Tooltip of a button that empties a text field.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearTooltip;

  /// Validation message of a task value field.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get taskValidationEnterValue;

  /// Validation message of a task value field.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get taskValidationWholeNumber;

  /// Validation message of a task value field.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get taskValidationValidNumber;

  /// Validation message of a task delay field.
  ///
  /// In en, this message translates to:
  /// **'Must not be 0'**
  String get taskValidationNotZero;

  /// Validation message of a task delay field when a negative delay exceeds the interval.
  ///
  /// In en, this message translates to:
  /// **'Cannot bring it forward by more than its interval'**
  String get taskValidationForwardTooFar;

  /// Title of the sheet that picks what a task is linked to.
  ///
  /// In en, this message translates to:
  /// **'Link task to'**
  String get taskAssociationTitle;

  /// Explanation in the link picker.
  ///
  /// In en, this message translates to:
  /// **'Tap a bike or a component to link this task to it.'**
  String get taskAssociationHint;

  /// Hint of the search field of the link picker.
  ///
  /// In en, this message translates to:
  /// **'Search bikes and parts…'**
  String get taskAssociationSearchHint;

  /// Shown in the link picker when the search finds nothing. {query} is the search text.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\"'**
  String taskAssociationNoMatches(String query);

  /// Tooltip of the General Task chip in the link picker.
  ///
  /// In en, this message translates to:
  /// **'A task that is not linked to a bike or component'**
  String get taskAssociationGeneralTooltip;

  /// Tooltip of the chip of a deleted bike or component in the link picker.
  ///
  /// In en, this message translates to:
  /// **'This entry no longer exists'**
  String get taskAssociationMissingTooltip;

  /// Minimum shown in the duration sheet. {value} is the duration.
  ///
  /// In en, this message translates to:
  /// **'Min: {value}'**
  String setDurationMin(String value);

  /// Maximum shown in the duration sheet. {value} is the duration.
  ///
  /// In en, this message translates to:
  /// **'Max: {value}'**
  String setDurationMax(String value);

  /// Error in the duration sheet.
  ///
  /// In en, this message translates to:
  /// **'Selected duration is below the minimum'**
  String get setDurationBelowMin;

  /// Error in the duration sheet.
  ///
  /// In en, this message translates to:
  /// **'Selected duration exceeds the maximum'**
  String get setDurationAboveMax;

  /// Trigger type: the task has no trigger.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get taskTriggerTypeNone;

  /// Trigger type of a task.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get taskTriggerTypeDistance;

  /// Trigger type of a task.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get taskTriggerTypeElevation;

  /// Trigger type of a task.
  ///
  /// In en, this message translates to:
  /// **'Moving Time'**
  String get taskTriggerTypeMovingTime;

  /// Trigger type of a task.
  ///
  /// In en, this message translates to:
  /// **'Elapsed Time'**
  String get taskTriggerTypeElapsedTime;

  /// Trigger type of a task: a time span.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get taskTriggerTypeDuration;

  /// Trigger type of a task.
  ///
  /// In en, this message translates to:
  /// **'Activity Count'**
  String get taskTriggerTypeActivityCount;

  /// Trigger type of a task.
  ///
  /// In en, this message translates to:
  /// **'Kilojoules (Accumulated Watts)'**
  String get taskTriggerTypeKilojoules;

  /// Trigger type of a task: a fixed date. Also the label of its date field.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get taskTriggerTypeDate;

  /// Header of the time-based trigger types in the dropdown. It is shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Time-based'**
  String get taskTriggerSectionTimeBased;

  /// Header of the Strava trigger types in the dropdown. It is shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Activity-based (Strava)'**
  String get taskTriggerSectionActivityBased;

  /// Title of the banner shown without a Strava subscription.
  ///
  /// In en, this message translates to:
  /// **'Activity-based triggers need Strava'**
  String get taskTriggerStravaTitle;

  /// Body of the banner shown without a Strava subscription.
  ///
  /// In en, this message translates to:
  /// **'Distance, elevation, time and ride-count triggers update automatically from your Strava activities.'**
  String get taskTriggerStravaBody;

  /// Button of the Strava banner.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get taskTriggerStravaConnect;

  /// App bar title of the task rule form when adding.
  ///
  /// In en, this message translates to:
  /// **'Add Task Rule'**
  String get taskFormAddTitle;

  /// App bar title of the task rule form when editing.
  ///
  /// In en, this message translates to:
  /// **'Edit Task Rule'**
  String get taskFormEditTitle;

  /// Label of the name field of the task rule form.
  ///
  /// In en, this message translates to:
  /// **'Task Rule Name'**
  String get taskFormNameLabel;

  /// Hint of the name field of the task rule form.
  ///
  /// In en, this message translates to:
  /// **'Enter task name'**
  String get taskFormNameHint;

  /// Validation message of the name field of the task rule form.
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get taskFormNameRequired;

  /// Hint of the notes field of the task rule form.
  ///
  /// In en, this message translates to:
  /// **'Add additional details or instructions...'**
  String get taskFormNotesHint;

  /// Tooltip of the add tags chip and title of its sheet.
  ///
  /// In en, this message translates to:
  /// **'Add Tags'**
  String get taskFormAddTags;

  /// Label of the link field of the task forms.
  ///
  /// In en, this message translates to:
  /// **'Linked To'**
  String get taskFormLinkedTo;

  /// Second line of the link field for a component. {bike} is the bike it is installed on.
  ///
  /// In en, this message translates to:
  /// **'on {bike}'**
  String taskFormOnBike(String bike);

  /// Warning below the link field when the component is archived.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Tasks of archived components are hidden in the task list.'**
  String get taskFormArchivedWarning;

  /// Validation message of the link field when the trigger measures ride data.
  ///
  /// In en, this message translates to:
  /// **'The selected trigger needs a linked Bike or Component'**
  String get taskFormTriggerNeedsLink;

  /// Section title of the trigger part of the task rule form.
  ///
  /// In en, this message translates to:
  /// **'Task Trigger'**
  String get taskFormTriggerTitle;

  /// Info text of the trigger section title.
  ///
  /// In en, this message translates to:
  /// **'(Optional) Set a trigger to display a progress bar that updates automatically based on activity stats or time.'**
  String get taskFormTriggerInfo;

  /// Label of the trigger type dropdown.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get taskFormTypeLabel;

  /// Label of the value fields of the trigger and the delay.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get taskFormValueLabel;

  /// Placeholder of the date field of a date trigger.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get taskFormSelectDate;

  /// Validation message of the date field of a date trigger.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get taskFormSelectDateError;

  /// Tooltip of the unit button of a duration value.
  ///
  /// In en, this message translates to:
  /// **'Change unit'**
  String get taskFormChangeUnitTooltip;

  /// Title of the repeat switch of the task rule form.
  ///
  /// In en, this message translates to:
  /// **'Repeat Interval'**
  String get taskFormRepeatTitle;

  /// Subtitle of the repeat switch of the task rule form.
  ///
  /// In en, this message translates to:
  /// **'Start the interval over after each entry'**
  String get taskFormRepeatSubtitle;

  /// Title of the delay row of the task rule form.
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get taskFormDelayLabel;

  /// Subtitle of the delay row of the task rule form.
  ///
  /// In en, this message translates to:
  /// **'Postpone the next due date once'**
  String get taskFormDelaySubtitle;

  /// App bar title of the task entry form when adding.
  ///
  /// In en, this message translates to:
  /// **'Add Task Entry'**
  String get taskEntryFormAddTitle;

  /// App bar title of the task entry form when editing.
  ///
  /// In en, this message translates to:
  /// **'Edit Task Entry'**
  String get taskEntryFormEditTitle;

  /// Label of the name field of the task entry form.
  ///
  /// In en, this message translates to:
  /// **'Task Entry Name'**
  String get taskEntryFormNameLabel;

  /// Hint of the name field of the task entry form.
  ///
  /// In en, this message translates to:
  /// **'Enter task entry name'**
  String get taskEntryFormNameHint;

  /// Validation message of the name field of the task entry form.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get taskEntryFormNameRequired;

  /// Hint of the notes field of the task entry form.
  ///
  /// In en, this message translates to:
  /// **'Add additional details...'**
  String get taskEntryFormNotesHint;

  /// Title of the date picker.
  ///
  /// In en, this message translates to:
  /// **'Select Task Entry Date'**
  String get taskEntryPickDate;

  /// Title of the time picker.
  ///
  /// In en, this message translates to:
  /// **'Select Task Entry Time'**
  String get taskEntryPickTime;

  /// Names what the task rule is linked to, after “linked to”.
  ///
  /// In en, this message translates to:
  /// **'a deleted component'**
  String get taskEntryDeletedComponent;

  /// Names what the task rule is linked to, after “linked to”.
  ///
  /// In en, this message translates to:
  /// **'a deleted bike'**
  String get taskEntryDeletedBike;

  /// Names what the task rule is linked to, after “linked to”.
  ///
  /// In en, this message translates to:
  /// **'a general task'**
  String get taskEntryGeneralTask;

  /// Warning below the link field of an entry whose link differs from its task. {target} is what the task is linked to.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Differs from the task rule, which is linked to {target}.'**
  String taskEntryLinkMismatch(String target);

  /// App bar title of the task details page.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskDetailsTitle;

  /// Title shown when the task no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Task not found'**
  String get taskDetailsNotFoundTitle;

  /// Subtitle shown when the task no longer exists.
  ///
  /// In en, this message translates to:
  /// **'This task was deleted or is no longer available.'**
  String get taskDetailsNotFoundSubtitle;

  /// Section title of the entries of a task.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get taskDetailsEntriesTitle;

  /// Info text of the entries section title.
  ///
  /// In en, this message translates to:
  /// **'The card above is the Task — the rule defining what to do and when it\'s due. Each time you complete it, an entry is logged below. A recurring task collects multiple entries, one per completion.'**
  String get taskDetailsEntriesInfo;

  /// Title shown when a task has no entries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get taskDetailsEmptyTitle;

  /// Subtitle shown when a task has no entries.
  ///
  /// In en, this message translates to:
  /// **'Complete this task to log your first entry.'**
  String get taskDetailsEmptySubtitle;

  /// Button shown when a task has no entries.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get taskDetailsEmptyAction;

  /// App bar title of the trash page.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trashTitle;

  /// Info line at the top of the trash page.
  ///
  /// In en, this message translates to:
  /// **'Items in the Trash are permanently deleted after 30 days. The Trash is emptied automatically.'**
  String get trashInfo;

  /// Title of the empty state of the trash page.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmptyTitle;

  /// Subtitle of the empty state of the trash page.
  ///
  /// In en, this message translates to:
  /// **'Deleted items will appear here.'**
  String get trashEmptySubtitle;

  /// Subtitle of a trash entry. {time} is the formatted time of deletion.
  ///
  /// In en, this message translates to:
  /// **'Deleted at: {time}'**
  String trashDeletedAt(String time);

  /// Tooltip of the app bar button that restores all selected trash entries.
  ///
  /// In en, this message translates to:
  /// **'Restore selected'**
  String get trashRestoreSelectedTooltip;

  /// Snackbar after restoring one item from the trash. {name} is the item name.
  ///
  /// In en, this message translates to:
  /// **'\'{name}\' restored from trash.'**
  String trashRestoredOne(String name);

  /// Snackbar after restoring several items from the trash. {count} is the number of items.
  ///
  /// In en, this message translates to:
  /// **'{count} items restored from trash.'**
  String trashRestoredMany(int count);

  /// Name of a feedback entry where it has no title of its own, e.g. in the trash and the calendar.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackName;

  /// App bar title of the rider form when adding a rider.
  ///
  /// In en, this message translates to:
  /// **'Add Rider'**
  String get riderFormAddTitle;

  /// App bar title of the rider form when editing a rider.
  ///
  /// In en, this message translates to:
  /// **'Edit Rider'**
  String get riderFormEditTitle;

  /// Label of the name field of the rider form.
  ///
  /// In en, this message translates to:
  /// **'Rider Name'**
  String get riderFormNameLabel;

  /// Hint of the name field of the rider form.
  ///
  /// In en, this message translates to:
  /// **'Enter rider name'**
  String get riderFormNameHint;

  /// Validation error of the rider name field.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get riderFormNameRequired;

  /// Hint of the notes field of the rider form.
  ///
  /// In en, this message translates to:
  /// **'Enter notes about the rider...'**
  String get riderFormNotesHint;

  /// Label of the Strava athlete dropdown of the rider form.
  ///
  /// In en, this message translates to:
  /// **'Strava Athlete'**
  String get riderFormStravaLabel;

  /// Hint of the Strava athlete dropdown.
  ///
  /// In en, this message translates to:
  /// **'Link Strava Athlete'**
  String get riderFormStravaHint;

  /// Helper text when the chosen Strava athlete belongs to another rider.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Strava Athlete already assigned to another rider'**
  String get riderFormStravaTaken;

  /// Validation error of the Strava athlete dropdown.
  ///
  /// In en, this message translates to:
  /// **'Please select valid Athlete'**
  String get riderFormStravaInvalid;

  /// Shown in red when a rider points to a Strava athlete that no longer exists.
  ///
  /// In en, this message translates to:
  /// **'ATHLETE NOT FOUND'**
  String get riderStravaAthleteNotFound;

  /// Section title of the rider attributes in the rider form.
  ///
  /// In en, this message translates to:
  /// **'Attributes'**
  String get riderFormAttributesTitle;

  /// Title of the empty state of the rider attributes.
  ///
  /// In en, this message translates to:
  /// **'No attributes yet'**
  String get riderFormAttributesEmptyTitle;

  /// Subtitle of the empty state of the rider attributes.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Add Attribute\' to define parameters for this rider'**
  String get riderFormAttributesEmptySubtitle;

  /// Subtitle of the empty state of the rider attributes when validation failed.
  ///
  /// In en, this message translates to:
  /// **'Tap here to add the first attribute'**
  String get riderFormAttributesEmptyError;

  /// Button and sheet title that adds an attribute to a rider.
  ///
  /// In en, this message translates to:
  /// **'Add Attribute'**
  String get riderFormAddAttribute;

  /// Section header of the rider attribute templates once some are added.
  ///
  /// In en, this message translates to:
  /// **'Pre-filled Templates · {added}/{total} added'**
  String riderAttributeTemplatesProgress(int added, int total);

  /// Hint when every rider attribute template is already added.
  ///
  /// In en, this message translates to:
  /// **'Add a custom attribute below.'**
  String get riderAttributeAllAdded;

  /// Section header of the custom rider attribute types.
  ///
  /// In en, this message translates to:
  /// **'Custom Attribute'**
  String get riderAttributeCustom;

  /// Rider attribute type with a number.
  ///
  /// In en, this message translates to:
  /// **'Numerical Attribute'**
  String get riderAttributeTypeNumerical;

  /// Examples of numerical rider attributes.
  ///
  /// In en, this message translates to:
  /// **'Body Weight, Height, Age'**
  String get riderAttributeTypeNumericalHint;

  /// Rider attribute type with steps.
  ///
  /// In en, this message translates to:
  /// **'Step Attribute'**
  String get riderAttributeTypeStep;

  /// Examples of step rider attributes.
  ///
  /// In en, this message translates to:
  /// **'Increments'**
  String get riderAttributeTypeStepHint;

  /// Rider attribute type with a list of options.
  ///
  /// In en, this message translates to:
  /// **'Categorical Attribute'**
  String get riderAttributeTypeCategorical;

  /// Examples of categorical rider attributes.
  ///
  /// In en, this message translates to:
  /// **'Training status, Riding Gear, Riding style'**
  String get riderAttributeTypeCategoricalHint;

  /// Rider attribute type that is on or off.
  ///
  /// In en, this message translates to:
  /// **'On/Off Attribute'**
  String get riderAttributeTypeBoolean;

  /// Example of an on/off rider attribute.
  ///
  /// In en, this message translates to:
  /// **'Wearing a backpack?'**
  String get riderAttributeTypeBooleanHint;

  /// Rider attribute type with free text.
  ///
  /// In en, this message translates to:
  /// **'Text Attribute'**
  String get riderAttributeTypeText;

  /// Description of the text rider attribute.
  ///
  /// In en, this message translates to:
  /// **'Flexible field for any other attribute'**
  String get riderAttributeTypeTextHint;

  /// Title shown when the rider of the details page no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Rider not found'**
  String get riderDetailsNotFoundTitle;

  /// Subtitle shown when the rider of the details page no longer exists.
  ///
  /// In en, this message translates to:
  /// **'This rider was deleted or is no longer available.'**
  String get riderDetailsNotFoundSubtitle;

  /// Shown on the rider details when no Strava athlete is linked.
  ///
  /// In en, this message translates to:
  /// **'No Strava Athlete linked to this rider.'**
  String get riderDetailsNoStrava;

  /// Shown in red when the linked Strava athlete no longer exists.
  ///
  /// In en, this message translates to:
  /// **'STRAVA ATHLETE NOT FOUND'**
  String get riderDetailsStravaNotFound;

  /// Shown on the rider details when no bike is linked.
  ///
  /// In en, this message translates to:
  /// **'No bikes linked to this rider.'**
  String get riderDetailsNoBikes;

  /// Title of the empty state of the rider list.
  ///
  /// In en, this message translates to:
  /// **'No rider yet'**
  String get riderListEmptyTitle;

  /// Subtitle of the empty state of the rider list.
  ///
  /// In en, this message translates to:
  /// **'Add a rider to link to your bikes and setups.'**
  String get riderListEmptySubtitle;

  /// Button of the empty state of the rider list.
  ///
  /// In en, this message translates to:
  /// **'Add a rider'**
  String get riderListEmptyAction;

  /// Menu item of a rider card that opens the bike link sheet.
  ///
  /// In en, this message translates to:
  /// **'Link bikes'**
  String get riderOptionLinkBikes;

  /// Snackbar when the bike of an action no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Bike not found.'**
  String get riderBikeNotFoundMessage;

  /// Snackbar after a rider was created and linked to a bike.
  ///
  /// In en, this message translates to:
  /// **'\'{rider}\' is now the rider of \'{bike}\'.'**
  String riderSetForBike(String rider, String bike);

  /// Snackbar after deleting a rider.
  ///
  /// In en, this message translates to:
  /// **'Rider \'{name}\' moved to trash.'**
  String riderMovedToTrash(String name);

  /// Snackbar after restoring a rider.
  ///
  /// In en, this message translates to:
  /// **'Rider \'{name}\' restored from trash.'**
  String riderRestoredFromTrash(String name);

  /// Hint of the name field of the rider creation form.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get riderNameFormHint;

  /// Validation error of the rider creation form.
  ///
  /// In en, this message translates to:
  /// **'Enter a name to continue.'**
  String get riderNameFormRequired;

  /// Snackbar after creating a rider.
  ///
  /// In en, this message translates to:
  /// **'Rider \'{name}\' created.'**
  String riderCreated(String name);

  /// Snackbar after creating a rider from a bike.
  ///
  /// In en, this message translates to:
  /// **'Rider \'{name}\' created and linked to this bike.'**
  String riderCreatedLinked(String name);

  /// Headline of the rider creation form.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get riderNameFormTitle;

  /// Explanation under the headline of the rider creation form.
  ///
  /// In en, this message translates to:
  /// **'Your rider profile tracks values like your riding weight with each setup.'**
  String get riderNameFormBody;

  /// Button of the rider creation form.
  ///
  /// In en, this message translates to:
  /// **'Create rider'**
  String get riderNameFormCreate;

  /// Title of the rider sheet.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get riderSheetTitle;

  /// Explanation at the top of the rider sheet.
  ///
  /// In en, this message translates to:
  /// **'Suspension, sag and tire pressure depend on your weight. Recording rider values with each setup keeps your setups comparable when your weight changes.'**
  String get riderSheetIntro;

  /// Button of the rider sheet that links a bike to the rider.
  ///
  /// In en, this message translates to:
  /// **'Link bike'**
  String get riderSheetLinkBike;

  /// Hint under the link bike button.
  ///
  /// In en, this message translates to:
  /// **'Link a bike to record rider values with its setups.'**
  String get riderSheetLinkBikeHint;

  /// Hint when there is no bike to link to a rider.
  ///
  /// In en, this message translates to:
  /// **'Add a bike to link it to this rider.'**
  String get riderAddBikeHint;

  /// Button of the rider sheet that starts a new setup with rider values.
  ///
  /// In en, this message translates to:
  /// **'Record rider values'**
  String get riderSheetRecordValues;

  /// Hint under the record rider values button.
  ///
  /// In en, this message translates to:
  /// **'Rider values are saved with a new setup.'**
  String get riderSheetRecordValuesHint;

  /// Hint when no component exists to record a setup.
  ///
  /// In en, this message translates to:
  /// **'Add a component to record setups.'**
  String get riderSheetAddComponentHint;

  /// Title of the sheet that links bikes to a rider.
  ///
  /// In en, this message translates to:
  /// **'Link bikes'**
  String get bikeLinkSheetTitle;

  /// Save button of the bike link sheet when only links are added.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Link 1 bike} other{Link {count} bikes}}'**
  String bikeLinkSaveLink(int count);

  /// Save button of the bike link sheet when only links are removed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Unlink 1 bike} other{Unlink {count} bikes}}'**
  String bikeLinkSaveUnlink(int count);

  /// Save button of the bike link sheet when links are added and removed.
  ///
  /// In en, this message translates to:
  /// **'Link {link} · Unlink {unlink}'**
  String bikeLinkSaveBoth(int link, int unlink);

  /// Explanation at the top of the bike link sheet. {name} is the rider.
  ///
  /// In en, this message translates to:
  /// **'Rider values of \'{name}\' are recorded with the setups of linked bikes.'**
  String bikeLinkIntro(String name);

  /// Title shown in the bike link sheet when there is no bike.
  ///
  /// In en, this message translates to:
  /// **'No bikes yet'**
  String get bikeLinkEmptyTitle;

  /// Subtitle of a bike that already has another rider.
  ///
  /// In en, this message translates to:
  /// **'Ridden by \'{name}\''**
  String bikeLinkRiddenBy(String name);

  /// Button that links a bike to the rider.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get bikeLinkLink;

  /// Button that removes the link between a bike and the rider.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get bikeLinkUnlink;

  /// Tooltip of the link button. {name} is the bike.
  ///
  /// In en, this message translates to:
  /// **'Link \'{name}\''**
  String bikeLinkLinkTooltip(String name);

  /// Tooltip of the unlink button. {name} is the bike.
  ///
  /// In en, this message translates to:
  /// **'Unlink \'{name}\''**
  String bikeLinkUnlinkTooltip(String name);

  /// Title of the sheet that sets the rider of the selected bikes.
  ///
  /// In en, this message translates to:
  /// **'Set Rider'**
  String get setBikePersonTitle;

  /// Chip that removes the rider from the selected bikes.
  ///
  /// In en, this message translates to:
  /// **'No rider'**
  String get setBikePersonNoRider;

  /// Tooltip of a rider chip that was just picked.
  ///
  /// In en, this message translates to:
  /// **'Set for all — tap to undo'**
  String get setBikePersonAllUndo;

  /// Tooltip of a rider chip that every selected bike already has.
  ///
  /// In en, this message translates to:
  /// **'On all'**
  String get setBikePersonOnAll;

  /// Tooltip of a rider chip that only some selected bikes have.
  ///
  /// In en, this message translates to:
  /// **'On {count} of {total} — tap to set for all'**
  String setBikePersonOnSome(int count, int total);

  /// Tooltip of a rider chip that no selected bike has.
  ///
  /// In en, this message translates to:
  /// **'Tap to set for all'**
  String get setBikePersonTapToSet;

  /// Info line of the set rider sheet when no rider exists.
  ///
  /// In en, this message translates to:
  /// **'You can assign a rider as soon as you\'ve created one.'**
  String get setBikePersonNoRidersInfo;

  /// Info line of the set rider sheet.
  ///
  /// In en, this message translates to:
  /// **'Each bike has one rider. Pick the rider for all selected bikes.'**
  String get setBikePersonInfo;

  /// Legend line explaining half-filled chips.
  ///
  /// In en, this message translates to:
  /// **'Half-filled chips apply to only part of your selection.'**
  String get setBikePersonHalfFilled;

  /// Button of the set rider sheet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Apply to 1 Bike} other{Apply to {count} Bikes}}'**
  String setBikePersonApply(int count);

  /// Calendar view that lists the entries by day.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get calendarViewSchedule;

  /// Calendar view that shows a month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarViewMonth;

  /// Calendar view that shows a week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarViewWeek;

  /// Calendar view that shows three days.
  ///
  /// In en, this message translates to:
  /// **'3 Day'**
  String get calendarViewThreeDay;

  /// Calendar view that shows one day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get calendarViewDay;

  /// Chip of the calendar that jumps to today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// Label of a calendar cell that has more entries than fit. {count} is the number of hidden entries.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String calendarMore(int count);

  /// Calendar entry title of a component replacement. {type} is the component type.
  ///
  /// In en, this message translates to:
  /// **'Replaced {type}'**
  String calendarReplacedSubject(String type);

  /// Calendar entry title of a group of setups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 setup} other{{count} setups}}'**
  String calendarSetupGroupSubject(int count);

  /// Label of the empty calendar slot that adds a setup.
  ///
  /// In en, this message translates to:
  /// **'Add setup'**
  String get calendarAddSetup;

  /// Snackbar when a setup is dropped on a future day.
  ///
  /// In en, this message translates to:
  /// **'Can\'t add a setup in the future.'**
  String get calendarNoSetupInFuture;

  /// Snackbar when an entry is dragged to a future day.
  ///
  /// In en, this message translates to:
  /// **'Can\'t move this into the future.'**
  String get calendarNoMoveFuture;

  /// Snackbar when a replacement is dragged to an invalid time.
  ///
  /// In en, this message translates to:
  /// **'Can\'t move this replacement there.'**
  String get calendarNoMoveReplacement;

  /// Snackbar when a replacement move would create a component loop.
  ///
  /// In en, this message translates to:
  /// **'Can\'t move this replacement there: it would create a loop of components.'**
  String get calendarNoMoveReplacementLoop;

  /// Snackbar when an installation is dragged to an invalid time.
  ///
  /// In en, this message translates to:
  /// **'Can\'t move this installation there.'**
  String get calendarNoMoveInstallation;

  /// Snackbar when an installation move would create a component loop.
  ///
  /// In en, this message translates to:
  /// **'Can\'t move this installation there: it would create a loop of components.'**
  String get calendarNoMoveInstallationLoop;

  /// Snackbar when feedback is dragged before the first setup of its bike.
  ///
  /// In en, this message translates to:
  /// **'Can\'t move this feedback before the bike\'s first setup.'**
  String get calendarNoMoveFeedback;

  /// Snackbar when a Strava activity is dragged.
  ///
  /// In en, this message translates to:
  /// **'Strava activities can\'t be edited.'**
  String get calendarStravaReadOnly;

  /// Snackbar when a test session is dragged.
  ///
  /// In en, this message translates to:
  /// **'A test session can\'t be moved. Change the times of its runs instead.'**
  String get calendarTestSessionNoMove;

  /// Snackbar after moving a calendar entry. {from} and {to} are the old and new date and time.
  ///
  /// In en, this message translates to:
  /// **'\'{subject}\' moved\n{from}  →  {to}'**
  String calendarMoved(String subject, String from, String to);

  /// Snackbar of the map when finding the user's location timed out.
  ///
  /// In en, this message translates to:
  /// **'Location request timed out. Try again.'**
  String get mapLocationTimeout;

  /// Snackbar of the map when the user's location could not be found.
  ///
  /// In en, this message translates to:
  /// **'Unable to determine your location.'**
  String get mapLocationError;

  /// Snackbar of the map when the location service returned no usable position.
  ///
  /// In en, this message translates to:
  /// **'No valid location was returned.'**
  String get mapLocationNone;

  /// Title of the map card shown when Strava activities failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load activities'**
  String get mapEmptyErrorTitle;

  /// Subtitle of the map card shown when Strava activities failed to load.
  ///
  /// In en, this message translates to:
  /// **'Setups and feedback are still shown.'**
  String get mapEmptyErrorSubtitle;

  /// Collapsed label of the map card shown when Strava activities failed to load.
  ///
  /// In en, this message translates to:
  /// **'Activities failed'**
  String get mapEmptyErrorPill;

  /// Button that reloads the Strava activities for the map.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get mapEmptyRetry;

  /// Title of the map card shown when filters hide every pin.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the map in this view'**
  String get mapEmptyFilteredTitle;

  /// Subtitle of the map card shown when filters hide every pin.
  ///
  /// In en, this message translates to:
  /// **'Your current filters hide every pin.'**
  String get mapEmptyFilteredSubtitle;

  /// Collapsed label of the map card shown when there is nothing to show.
  ///
  /// In en, this message translates to:
  /// **'No pins'**
  String get mapEmptyNoPins;

  /// Title of the map card shown when nothing has a location yet.
  ///
  /// In en, this message translates to:
  /// **'No locations yet'**
  String get mapEmptyNoneTitle;

  /// Button of the empty map card that adds a setup.
  ///
  /// In en, this message translates to:
  /// **'Add setup'**
  String get mapEmptyAddSetup;

  /// First line of the subtitle of the empty map card.
  ///
  /// In en, this message translates to:
  /// **'Setups appear here once one is saved with a location.'**
  String get mapEmptySetupsHint;

  /// Second line of the subtitle of the empty map card. {sources} lists the other pin sources.
  ///
  /// In en, this message translates to:
  /// **'Same for {sources}.'**
  String mapEmptySameFor(String sources);

  /// Pin source named in the subtitle of the empty map card.
  ///
  /// In en, this message translates to:
  /// **'Strava activities'**
  String get mapEmptySourceStrava;

  /// Pin source named in the subtitle of the empty map card.
  ///
  /// In en, this message translates to:
  /// **'feedback'**
  String get mapEmptySourceFeedback;

  /// Link of the map attribution that opens Mapbox's map feedback page.
  ///
  /// In en, this message translates to:
  /// **'Improve this map'**
  String get mapAttributionImprove;

  /// Tooltip of the button that collapses the empty map card.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get mapEmptyCollapse;

  /// Title of the filter sheet and label of the filter chip while nothing is filtered.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// Tooltip of the button of the filter sheet that clears all filters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get filterResetTooltip;

  /// Label of the bike filter chip while no bike is selected.
  ///
  /// In en, this message translates to:
  /// **'All Bikes'**
  String get filterAllBikes;

  /// Filter chip text for the number of selected tags.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Tag} other{{count} Tags}}'**
  String filterCountTags(int count);

  /// Filter chip text for the number of selected test sessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Test session} other{{count} Test sessions}}'**
  String filterCountTestSessions(int count);

  /// Filter chip text for the number of selected task priorities.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Priority} other{{count} Priorities}}'**
  String filterCountPriorities(int count);

  /// Filter chip text while the visibility filter hides something.
  ///
  /// In en, this message translates to:
  /// **'1 Filter'**
  String get filterLayersActive;

  /// Title of the component type filter sheet with the number of shown types.
  ///
  /// In en, this message translates to:
  /// **'Component Types ({selected}/{total})'**
  String componentTypeFilterTitle(int selected, int total);

  /// Tooltip of the button that selects every option of a sheet.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// Tooltip of the button that deselects every option of a sheet.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// Title of the sheet that chooses the visible table columns.
  ///
  /// In en, this message translates to:
  /// **'Column Select'**
  String get columnFilterTitle;

  /// Section title of the setup filters when bookmarks or test sessions are filterable.
  ///
  /// In en, this message translates to:
  /// **'Setups'**
  String get filterSetupsTitle;

  /// Section title of the setup filters when only tags are filterable.
  ///
  /// In en, this message translates to:
  /// **'Setup Tags'**
  String get filterSetupTagsTitle;

  /// Title shown when no setup has a tag.
  ///
  /// In en, this message translates to:
  /// **'No setup tags yet'**
  String get filterNoSetupTagsTitle;

  /// Hint shown when no setup has a tag and test sessions can be filtered.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit a Setup to add tags, or start a test session to filter its runs.'**
  String get filterNoSetupTagsHintSessions;

  /// Hint shown when no setup has a tag.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit a Setup to add tags.'**
  String get filterNoSetupTagsHint;

  /// Title shown when no test session exists.
  ///
  /// In en, this message translates to:
  /// **'No test sessions yet'**
  String get filterNoTestSessionsTitle;

  /// Hint shown when no test session exists.
  ///
  /// In en, this message translates to:
  /// **'Start a test session to filter its runs.'**
  String get filterNoTestSessionsHint;

  /// Section title of the date range filter.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get filterDateTitle;

  /// Help text of the date range picker of the filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get filterDateRangeHelp;

  /// Value of the date range filter while no range is set.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get filterAnyDate;

  /// Tooltip of the button that opens the date range picker.
  ///
  /// In en, this message translates to:
  /// **'Pick exact dates'**
  String get filterPickDatesTooltip;

  /// Section title of the activity distance and elevation filters.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get filterActivitiesTitle;

  /// Title of the activity distance range filter.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get filterDistance;

  /// Title of the activity elevation gain range filter.
  ///
  /// In en, this message translates to:
  /// **'Elevation Gain'**
  String get filterElevationGain;

  /// Value of a range filter while no limit is set.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get filterAnyValue;

  /// Section title of the filter that shows or hides entry kinds.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get filterVisibilityTitle;

  /// Entry kind setups in the visibility filter.
  ///
  /// In en, this message translates to:
  /// **'Setups'**
  String get filterLayerSetups;

  /// Entry kind Strava activities in the map visibility filter.
  ///
  /// In en, this message translates to:
  /// **'Strava Activities'**
  String get filterLayerStravaActivities;

  /// Entry kind Strava activities in the calendar visibility filter.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get filterLayerActivities;

  /// Entry kind tasks in the visibility filter.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get filterLayerTasks;

  /// Entry kind installations in the visibility filter.
  ///
  /// In en, this message translates to:
  /// **'Installations'**
  String get filterLayerInstallations;

  /// Entry kind feedback in the visibility filter.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get filterLayerFeedback;

  /// Section title of the bike filter.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get filterBikeTitle;

  /// Title shown in the bike filter when no bike exists.
  ///
  /// In en, this message translates to:
  /// **'No bikes yet'**
  String get filterNoBikesTitle;

  /// Hint shown in the bike filter when no bike exists.
  ///
  /// In en, this message translates to:
  /// **'Add a bike to filter this list by bike.'**
  String get filterNoBikesHint;

  /// The front end of the bike in feedback.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get feedbackEndFront;

  /// The rear end of the bike in feedback.
  ///
  /// In en, this message translates to:
  /// **'Rear'**
  String get feedbackEndRear;

  /// Feedback attribute grip, as a quality for goals and comparisons.
  ///
  /// In en, this message translates to:
  /// **'Grip'**
  String get feedbackAttributeGripQuality;

  /// Feedback problem chip for too little grip.
  ///
  /// In en, this message translates to:
  /// **'Low grip'**
  String get feedbackAttributeGripProblem;

  /// Explanation of the low grip problem.
  ///
  /// In en, this message translates to:
  /// **'Wheel slides or lets go'**
  String get feedbackAttributeGripHint;

  /// Feedback attribute comfort, as a quality for goals and comparisons.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get feedbackAttributeComfortQuality;

  /// Feedback problem chip for a harsh ride.
  ///
  /// In en, this message translates to:
  /// **'Harsh'**
  String get feedbackAttributeComfortProblem;

  /// Explanation of the harsh problem.
  ///
  /// In en, this message translates to:
  /// **'Hits come through to hands or feet'**
  String get feedbackAttributeComfortHint;

  /// Feedback attribute support, as a quality for goals and comparisons.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get feedbackAttributeSupportQuality;

  /// Feedback problem chip for too little support.
  ///
  /// In en, this message translates to:
  /// **'Sinks / dives'**
  String get feedbackAttributeSupportProblem;

  /// Explanation of the sinks / dives problem.
  ///
  /// In en, this message translates to:
  /// **'Sits low, dives under braking, wallows in berms'**
  String get feedbackAttributeSupportHint;

  /// Feedback attribute calm, as a quality for goals and comparisons.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get feedbackAttributeCalmQuality;

  /// Feedback problem chip for an unsettled ride.
  ///
  /// In en, this message translates to:
  /// **'Unsettled'**
  String get feedbackAttributeCalmProblem;

  /// Explanation of the unsettled problem.
  ///
  /// In en, this message translates to:
  /// **'Bouncy, kicks, doesn\'t settle after hits'**
  String get feedbackAttributeCalmHint;

  /// Feedback attribute bottoming, as a quality for goals and comparisons.
  ///
  /// In en, this message translates to:
  /// **'Bottoming'**
  String get feedbackAttributeBottomingQuality;

  /// Feedback problem chip for bottoming out.
  ///
  /// In en, this message translates to:
  /// **'Bottoms out'**
  String get feedbackAttributeBottomingProblem;

  /// Explanation of the bottoms out problem.
  ///
  /// In en, this message translates to:
  /// **'Hits the end of travel hard or often'**
  String get feedbackAttributeBottomingHint;

  /// Comparison answer: clearly worse.
  ///
  /// In en, this message translates to:
  /// **'Worse'**
  String get feedbackOutcomeWorse;

  /// Comparison answer: slightly worse.
  ///
  /// In en, this message translates to:
  /// **'Slightly worse'**
  String get feedbackOutcomeSlightlyWorse;

  /// Comparison answer: no difference.
  ///
  /// In en, this message translates to:
  /// **'Same'**
  String get feedbackOutcomeSame;

  /// Comparison answer: slightly better.
  ///
  /// In en, this message translates to:
  /// **'Slightly better'**
  String get feedbackOutcomeSlightlyBetter;

  /// Comparison answer: clearly better.
  ///
  /// In en, this message translates to:
  /// **'Better'**
  String get feedbackOutcomeBetter;

  /// Verdict of a feedback. {reference} is the name of the reference setup.
  ///
  /// In en, this message translates to:
  /// **'Worse than {reference}'**
  String feedbackVerdictWorse(String reference);

  /// Verdict of a feedback. {reference} is the name of the reference setup.
  ///
  /// In en, this message translates to:
  /// **'Slightly worse than {reference}'**
  String feedbackVerdictSlightlyWorse(String reference);

  /// Verdict of a feedback. {reference} is the name of the reference setup.
  ///
  /// In en, this message translates to:
  /// **'Same as {reference}'**
  String feedbackVerdictSame(String reference);

  /// Verdict of a feedback. {reference} is the name of the reference setup.
  ///
  /// In en, this message translates to:
  /// **'Slightly better than {reference}'**
  String feedbackVerdictSlightlyBetter(String reference);

  /// Verdict of a feedback. {reference} is the name of the reference setup.
  ///
  /// In en, this message translates to:
  /// **'Better than {reference}'**
  String feedbackVerdictBetter(String reference);

  /// Chip and summary that say no problem was felt.
  ///
  /// In en, this message translates to:
  /// **'No issues'**
  String get feedbackNoIssues;

  /// Helper text of the feedback notes field.
  ///
  /// In en, this message translates to:
  /// **'Not used for ranking or proposals.'**
  String get feedbackNotesHelper;

  /// Stands in for the name of a setup that no longer exists, inside a sentence.
  ///
  /// In en, this message translates to:
  /// **'a deleted setup'**
  String get feedbackDeletedSetup;

  /// Prompt under the outcome faces while no answer is chosen.
  ///
  /// In en, this message translates to:
  /// **'Tap a face'**
  String get feedbackTapAFace;

  /// Heading of the rider-defined problems in the feedback form.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackIssueOther;

  /// Chip that adds a rider-defined problem.
  ///
  /// In en, this message translates to:
  /// **'Add issue'**
  String get feedbackAddIssue;

  /// Chip that opens the list of all rider-defined problems.
  ///
  /// In en, this message translates to:
  /// **'All issues'**
  String get feedbackAllIssues;

  /// Heading of the values that changed between the reference and the rated setup.
  ///
  /// In en, this message translates to:
  /// **'What changed'**
  String get feedbackWhatChanged;

  /// Left part of the line "reference → rated setup".
  ///
  /// In en, this message translates to:
  /// **'reference'**
  String get feedbackReferenceShort;

  /// Right part of the line "reference → rated setup".
  ///
  /// In en, this message translates to:
  /// **'rated setup'**
  String get feedbackRatedSetupShort;

  /// Tooltip of the button that opens the setup comparison.
  ///
  /// In en, this message translates to:
  /// **'View comparison'**
  String get feedbackViewComparison;

  /// Question above the overall comparison answer.
  ///
  /// In en, this message translates to:
  /// **'How did it ride?'**
  String get feedbackHowDidItRide;

  /// Tooltip of the dropdown arrow of the reference setup.
  ///
  /// In en, this message translates to:
  /// **'Change reference setup'**
  String get feedbackChangeReference;

  /// Tooltip of the button that removes a comparison.
  ///
  /// In en, this message translates to:
  /// **'Remove comparison'**
  String get feedbackRemoveComparison;

  /// Title of the sheet that picks the reference setup.
  ///
  /// In en, this message translates to:
  /// **'Reference setup'**
  String get feedbackReferenceSetupTitle;

  /// Side label of the rated setup in the reference picker.
  ///
  /// In en, this message translates to:
  /// **'Rated'**
  String get feedbackRatedSideLabel;

  /// Shown when the reference setup no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Values of the reference are unavailable'**
  String get feedbackReferenceUnavailable;

  /// Shown when the reference and the rated setup have the same values.
  ///
  /// In en, this message translates to:
  /// **'No values changed'**
  String get feedbackNoValuesChanged;

  /// Button that adds feedback.
  ///
  /// In en, this message translates to:
  /// **'Add feedback'**
  String get feedbackAddButton;

  /// Button that adds feedback for a Strava ride.
  ///
  /// In en, this message translates to:
  /// **'Add feedback for this ride'**
  String get feedbackAddForRide;

  /// Rank of a setup among the compared setups.
  ///
  /// In en, this message translates to:
  /// **'{rank}/{total} compared'**
  String feedbackRankLabel(int rank, int total);

  /// Tooltip of the rank badge. {count} is the number of compared setups.
  ///
  /// In en, this message translates to:
  /// **'Estimated rank among the {count} setups of this bike you compared in feedback'**
  String feedbackRankTooltip(int count);

  /// Shown in red when an item points to a setup that no longer exists.
  ///
  /// In en, this message translates to:
  /// **'SETUP NOT FOUND'**
  String get setupNotFound;

  /// App bar title of the feedback form when adding feedback.
  ///
  /// In en, this message translates to:
  /// **'Add Feedback'**
  String get feedbackFormAddTitle;

  /// App bar title of the feedback form when editing feedback.
  ///
  /// In en, this message translates to:
  /// **'Edit Feedback'**
  String get feedbackFormEditTitle;

  /// Help text of the date picker of the feedback form.
  ///
  /// In en, this message translates to:
  /// **'Select Feedback Date'**
  String get feedbackFormPickDate;

  /// Help text of the time picker of the feedback form.
  ///
  /// In en, this message translates to:
  /// **'Select Feedback Time'**
  String get feedbackFormPickTime;

  /// Snackbar when a changed date moves the feedback to another setup. {name} is the setup.
  ///
  /// In en, this message translates to:
  /// **'Now rating \'{name}\'.'**
  String feedbackFormNowRating(String name);

  /// Snackbar when a changed date leaves the feedback without a setup.
  ///
  /// In en, this message translates to:
  /// **'No setup was active at this time.'**
  String get feedbackFormNoSetupActive;

  /// Snackbar when the feedback form fails validation.
  ///
  /// In en, this message translates to:
  /// **'Please check all fields for missing or invalid input.'**
  String get feedbackFormInvalid;

  /// Snackbar when saving feedback that no setup can be rated for.
  ///
  /// In en, this message translates to:
  /// **'No setup exists before this date/time for the selected bike. Create a setup first.'**
  String get feedbackFormNoSetupBefore;

  /// Subtitle of the empty state when the bike has no setup. {bike} is the bike name.
  ///
  /// In en, this message translates to:
  /// **'Feedback rates the setup you rode. Record {bike}\'s setup first.'**
  String feedbackFormNoSetupsSubtitle(String bike);

  /// Subtitle of the empty state when the bike has no setup and its name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Feedback rates the setup you rode. Record this bike\'s setup first.'**
  String get feedbackFormNoSetupsSubtitleGeneric;

  /// Title of the card shown when no setup was active at the chosen time.
  ///
  /// In en, this message translates to:
  /// **'No setup at this time'**
  String get feedbackFormNoSetupNowTitle;

  /// Body of the card shown when no setup was active at the chosen time.
  ///
  /// In en, this message translates to:
  /// **'Feedback rates the setup that was active when you rode. Pick a later date or add a setup first.'**
  String get feedbackFormNoSetupNowBody;

  /// Title of the warning when the rated setup is no longer the stored one.
  ///
  /// In en, this message translates to:
  /// **'Setup link changed'**
  String get feedbackFormDriftTitle;

  /// Body of the setup link warning.
  ///
  /// In en, this message translates to:
  /// **'Originally \'{stored}\', now resolves to \'{current}\'. Ranking follows the current resolution.'**
  String feedbackFormDriftBody(String stored, String current);

  /// Button of the setup link warning that links the feedback to the current setup.
  ///
  /// In en, this message translates to:
  /// **'Relink'**
  String get feedbackFormRelink;

  /// Section title of the comparisons in the feedback form and overline of a comparison card.
  ///
  /// In en, this message translates to:
  /// **'Compared to'**
  String get feedbackFormComparedTo;

  /// Button that adds another comparison card.
  ///
  /// In en, this message translates to:
  /// **'Compare with another run'**
  String get feedbackFormCompareAnother;

  /// Heading above the follow-up rows for the open issues of the reference.
  ///
  /// In en, this message translates to:
  /// **'Did its open issues change?'**
  String get feedbackFormOpenIssuesChanged;

  /// Heading above the follow-up rows for the goal of a test session.
  ///
  /// In en, this message translates to:
  /// **'Did your goal improve?'**
  String get feedbackFormGoalImproved;

  /// Button that shows the follow-up rows of the other aspects.
  ///
  /// In en, this message translates to:
  /// **'Something else changed'**
  String get feedbackFormSomethingElse;

  /// Section title of the problem chips and title of the problems card.
  ///
  /// In en, this message translates to:
  /// **'Anything stand out?'**
  String get feedbackFormAnythingTitle;

  /// Info text of the problems section.
  ///
  /// In en, this message translates to:
  /// **'Optional. Flagged problems show on the setup as open issues until a later ride says otherwise.'**
  String get feedbackFormAnythingInfo;

  /// Section title of the notes, place and weather of the feedback form.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get feedbackFormDetailsTitle;

  /// Title shown when the feedback of the details sheet no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Feedback not found'**
  String get feedbackDetailsNotFoundTitle;

  /// Subtitle shown when the feedback of the details sheet no longer exists.
  ///
  /// In en, this message translates to:
  /// **'This feedback was deleted or is no longer available.'**
  String get feedbackDetailsNotFoundSubtitle;

  /// Subtitle of the setup row when the rated setup differs from the stored one.
  ///
  /// In en, this message translates to:
  /// **'Originally \'{name}\''**
  String feedbackDetailsOriginally(String name);

  /// Shown when the Strava ride of a feedback is not on this device.
  ///
  /// In en, this message translates to:
  /// **'Strava ride not synced'**
  String get feedbackDetailsStravaNotSynced;

  /// Shown on the problems card when the question was skipped.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get feedbackDetailsNotAnswered;

  /// Stands in for the name of a setup that no longer exists, as a title.
  ///
  /// In en, this message translates to:
  /// **'A deleted setup'**
  String get feedbackDeletedSetupTitle;

  /// Line on a feedback tile when the rated setup differs from the stored one.
  ///
  /// In en, this message translates to:
  /// **'Originally \'{stored}\', now \'{current}\''**
  String feedbackOriginallyNow(String stored, String current);

  /// Tooltip of the menu button of a feedback tile.
  ///
  /// In en, this message translates to:
  /// **'Feedback actions'**
  String get feedbackActionsTooltip;

  /// Count of the hidden lines of a list. {count} is the number of hidden lines.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String plusMore(int count);

  /// Snackbar after deleting feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback moved to trash.'**
  String get feedbackMovedToTrash;

  /// Snackbar after restoring feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback restored from trash.'**
  String get feedbackRestoredFromTrash;

  /// Title of the dialog that renames a rider-defined problem.
  ///
  /// In en, this message translates to:
  /// **'Rename issue'**
  String get customIssueRenameTitle;

  /// Snackbar after renaming a problem to the name of another one.
  ///
  /// In en, this message translates to:
  /// **'Merged into \"{label}\".'**
  String customIssueMerged(String label);

  /// Snackbar after renaming a rider-defined problem.
  ///
  /// In en, this message translates to:
  /// **'Issue renamed.'**
  String get customIssueRenamed;

  /// Title of the dialog that confirms removing a rider-defined problem.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{label}\"?'**
  String customIssueRemoveTitle(String label);

  /// Body of the dialog that confirms removing a rider-defined problem.
  ///
  /// In en, this message translates to:
  /// **'It is removed from every feedback and test session goal, including the trash. This cannot be undone.'**
  String get customIssueRemoveBody;

  /// Snackbar after removing a rider-defined problem.
  ///
  /// In en, this message translates to:
  /// **'Issue removed.'**
  String get customIssueRemoved;

  /// Title of the sheet with the rider-defined problems.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get customIssuesTitle;

  /// Info line of the sheet with the rider-defined problems.
  ///
  /// In en, this message translates to:
  /// **'Your own problems, beside the built-in ones. Long-press an issue to rename or remove it.'**
  String get customIssuesInfo;

  /// Validation error when adding a problem without a name.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get customIssueEnterName;

  /// Tooltip of the plus button that starts adding a tag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTagTooltip;

  /// Hint of the inline field that adds a tag.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get addTagHint;

  /// Hint of the inline field that adds a rider-defined problem.
  ///
  /// In en, this message translates to:
  /// **'New issue'**
  String get addIssueHint;

  /// Tooltip of the check button of the inline add field.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addTagConfirm;

  /// Name shown for a test session without a name.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Test Session'**
  String get testSessionUnnamed;

  /// Name given to a run of a test session. {number} counts the runs.
  ///
  /// In en, this message translates to:
  /// **'Run {number}'**
  String testSessionRunName(int number);

  /// Line added to the notes of a run that was copied from another run.
  ///
  /// In en, this message translates to:
  /// **'Copy of \'{name}\' ({date})'**
  String testSessionCopyLine(String name, String date);

  /// Name of a session goal: the end of the bike and the quality, e.g. Front · Calm.
  ///
  /// In en, this message translates to:
  /// **'{end} · {attribute}'**
  String testSessionGoalLabel(String end, String attribute);

  /// Test session method that polls one adjustment at a time.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune'**
  String get testSessionMethodFineTune;

  /// Test session method that changes all adjustments in a pattern.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get testSessionMethodExplore;

  /// Test session method that rides existing setups against each other.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get testSessionMethodCompare;

  /// Test session method without proposals.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get testSessionMethodFree;

  /// Description of the fine-tune method.
  ///
  /// In en, this message translates to:
  /// **'Move one knob at a time around your best run, in smaller and smaller steps.'**
  String get testSessionMethodFineTuneInfo;

  /// Description of the explore method.
  ///
  /// In en, this message translates to:
  /// **'Change all knobs together in a planned pattern to learn what each one does.'**
  String get testSessionMethodExploreInfo;

  /// Description of the compare method.
  ///
  /// In en, this message translates to:
  /// **'Ride 2–4 setups you already have against each other to find the best.'**
  String get testSessionMethodCompareInfo;

  /// Description of the free method.
  ///
  /// In en, this message translates to:
  /// **'Record the runs and compare them yourself. Nothing is proposed.'**
  String get testSessionMethodFreeInfo;

  /// Rough number of runs a session takes.
  ///
  /// In en, this message translates to:
  /// **'about {count} runs'**
  String testSessionExpectedRuns(int count);

  /// Sentence that names the expected number of runs. {runs} is e.g. "about 8 runs".
  ///
  /// In en, this message translates to:
  /// **'Expect {runs}.'**
  String testSessionExpect(String runs);

  /// Number of runs of a test session.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 run} other{{count} runs}}'**
  String testSessionRunsCount(int count);

  /// App bar title of the form that edits a test session.
  ///
  /// In en, this message translates to:
  /// **'Edit Test Session'**
  String get testSessionEditTitle;

  /// Tooltip of the check button of the form that starts a test session.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get testSessionStartTooltip;

  /// Snackbar when starting a session on a bike that has a running one.
  ///
  /// In en, this message translates to:
  /// **'A test session is already running on this bike.'**
  String get testSessionErrAlreadyRunning;

  /// Snackbar when starting a session on a bike without a setup.
  ///
  /// In en, this message translates to:
  /// **'Record a setup first. The first run starts from the bike’s current setup.'**
  String get testSessionErrRecordSetup;

  /// Title of the sheet that picks the adjustments of a test session.
  ///
  /// In en, this message translates to:
  /// **'Adjustments to test'**
  String get testSessionPickAdjustmentsTitle;

  /// Shown in the adjustment picker when the bike has none.
  ///
  /// In en, this message translates to:
  /// **'This bike has no adjustments.'**
  String get testSessionNoAdjustments;

  /// Warning when many adjustments are picked.
  ///
  /// In en, this message translates to:
  /// **'More than {max} adjustments make it hard to tell which one helped. 1–3 work best.'**
  String testSessionTooManyAdjustments(int max);

  /// Warning when many setups are picked to compare.
  ///
  /// In en, this message translates to:
  /// **'Every setup is compared with every other one, so {count} setups take about {comparisons} comparisons. {max} or fewer work best.'**
  String testSessionTooManySetups(int count, int comparisons, int max);

  /// Title of the sheet that picks the setups of a compare session.
  ///
  /// In en, this message translates to:
  /// **'Setups to compare'**
  String get testSessionPickSetupsTitle;

  /// Shown in the setup picker when the bike has none.
  ///
  /// In en, this message translates to:
  /// **'This bike has no setups yet'**
  String get testSessionNoSetups;

  /// Shown for an adjustment of a session that no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Adjustment not found'**
  String get testSessionAdjustmentNotFound;

  /// Shown in red for an adjustment of a session that no longer exists.
  ///
  /// In en, this message translates to:
  /// **'ADJUSTMENT NOT FOUND'**
  String get testSessionAdjustmentNotFoundCaps;

  /// Shown when a session has no goal.
  ///
  /// In en, this message translates to:
  /// **'No goal'**
  String get testSessionNoGoal;

  /// Validation error of the adjustments of a session.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one adjustment to test.'**
  String get testSessionPickAtLeastOne;

  /// Subtitle of the empty adjustments of a session.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Add Adjustment\' to pick what you want to test'**
  String get testSessionAdjustmentsEmptySubtitle;

  /// Tooltip of the button that removes an adjustment from a session.
  ///
  /// In en, this message translates to:
  /// **'Remove adjustment'**
  String get testSessionRemoveAdjustment;

  /// Validation error of the setups of a compare session.
  ///
  /// In en, this message translates to:
  /// **'Pick at least {count} setups to compare.'**
  String testSessionPickAtLeastSetups(int count);

  /// Validation error when the picked setups do not differ.
  ///
  /// In en, this message translates to:
  /// **'These setups have the same values. Pick setups that differ.'**
  String get testSessionSameValues;

  /// Subtitle of the empty setups of a compare session.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Add Setups\' to pick at least {count} setups to compare'**
  String testSessionSetupsEmptySubtitle(int count);

  /// Subtitle of the empty setups of a compare session when validation failed.
  ///
  /// In en, this message translates to:
  /// **'Tap here to add the setups'**
  String get testSessionSetupsEmptyError;

  /// Tooltip of the button that removes a setup from a compare session.
  ///
  /// In en, this message translates to:
  /// **'Remove setup'**
  String get testSessionRemoveSetup;

  /// Line under the picked setups of a compare session.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 adjustment differs between them.} other{{count} adjustments differ between them.}}'**
  String testSessionDifferingCount(int count);

  /// Button that picks the setups of a compare session.
  ///
  /// In en, this message translates to:
  /// **'Add Setups'**
  String get testSessionAddSetups;

  /// Button that changes the picked setups of a compare session.
  ///
  /// In en, this message translates to:
  /// **'Change Setups'**
  String get testSessionChangeSetups;

  /// Section title of the method of a test session.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get testSessionSectionMethod;

  /// Info text of the method section.
  ///
  /// In en, this message translates to:
  /// **'How the app helps you choose the next run. You can always change values by hand.'**
  String get testSessionSectionMethodInfo;

  /// Section title of the setups of a compare session.
  ///
  /// In en, this message translates to:
  /// **'Setups'**
  String get testSessionSectionSetups;

  /// Info text of the adjustments section of a session.
  ///
  /// In en, this message translates to:
  /// **'The adjustments you want to test, in the order to try them. Every other value stays as it is. Fewer is better: 1–3 tell you most.'**
  String get testSessionSectionAdjustmentsInfo;

  /// Section title of the goal of a test session.
  ///
  /// In en, this message translates to:
  /// **'Goal (optional)'**
  String get testSessionSectionGoal;

  /// Explanation under the goal section title.
  ///
  /// In en, this message translates to:
  /// **'What should get better? Each run asks if it did.'**
  String get testSessionGoalPrompt;

  /// Label of the name field of a test session.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get testSessionNameLabel;

  /// Shown in the session sheet when the session was removed.
  ///
  /// In en, this message translates to:
  /// **'This test session no longer exists.'**
  String get testSessionGone;

  /// Meta line of a test session that has ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get testSessionEnded;

  /// Hint below the adjustments title of a running session.
  ///
  /// In en, this message translates to:
  /// **'Tap an adjustment to lock it at its value in the latest run, so the next runs keep it and you can tell what made the difference.'**
  String get testSessionLockInfo;

  /// Section title of the runs of a test session.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get testSessionRunsTitle;

  /// Section title of the table that shows the runs of a test session side by side.
  ///
  /// In en, this message translates to:
  /// **'Run overview'**
  String get testSessionRunTableTitle;

  /// Column of the run table: the problems flagged in the feedbacks on a run.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get testSessionRunTableIssues;

  /// Column of the run table: how the feedbacks on a run compare it with other setups, e.g. 'Better than Run 1'.
  ///
  /// In en, this message translates to:
  /// **'Evaluation'**
  String get testSessionRunTableEvaluation;

  /// Column of the run table: the notes of the feedbacks on a run. Distinct from the notes of the setup, which can be shown beside it.
  ///
  /// In en, this message translates to:
  /// **'Feedback notes'**
  String get testSessionRunTableNotes;

  /// Heading above the adjustments in which the compared setups differ.
  ///
  /// In en, this message translates to:
  /// **'The adjustments your setups differ in:'**
  String get testSessionDiffering;

  /// Tooltip of a locked adjustment chip.
  ///
  /// In en, this message translates to:
  /// **'Locked at its value. Tap to unlock.'**
  String get testSessionLockedTooltip;

  /// Tooltip of an unlocked adjustment chip.
  ///
  /// In en, this message translates to:
  /// **'Tap to lock it at its value in the latest run.'**
  String get testSessionLockTooltip;

  /// Shown when a test session has no run.
  ///
  /// In en, this message translates to:
  /// **'No runs yet.'**
  String get testSessionNoRuns;

  /// Title of the empty state of the runs of a test session.
  ///
  /// In en, this message translates to:
  /// **'No runs yet'**
  String get testSessionNoRunsTitle;

  /// Call to action of the empty state of the runs of a running test session.
  ///
  /// In en, this message translates to:
  /// **'Record a run to start comparing'**
  String get testSessionNoRunsSubtitle;

  /// Button of the timeline that reveals earlier runs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 earlier} other{Show {count} earlier}}'**
  String testSessionShowEarlier(int count);

  /// Next step text of a session without runs.
  ///
  /// In en, this message translates to:
  /// **'This session has no runs. Record one to go on.'**
  String get testSessionStepNoRuns;

  /// Next step text when the latest run has feedback.
  ///
  /// In en, this message translates to:
  /// **'{name} is rated. Ready for the next run.'**
  String testSessionStepRated(String name);

  /// Next step text when the latest run waits for feedback.
  ///
  /// In en, this message translates to:
  /// **'Ride {name}, then tell how it went.'**
  String testSessionStepRide(String name);

  /// Button that records the next run of a session.
  ///
  /// In en, this message translates to:
  /// **'Next run'**
  String get testSessionNextRun;

  /// Button that ends a test session.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get testSessionEndSession;

  /// Tooltip of the menu button of a test session.
  ///
  /// In en, this message translates to:
  /// **'Test session actions'**
  String get testSessionActionsTooltip;

  /// Snackbar when starting a session without a bike.
  ///
  /// In en, this message translates to:
  /// **'A bike is required to start a test session'**
  String get testSessionBikeRequired;

  /// Snackbar when starting a session without any adjustment.
  ///
  /// In en, this message translates to:
  /// **'Add an adjustment to a component first'**
  String get testSessionAdjustmentRequired;

  /// Title of the sheet that picks the setup of the next run of a compare session.
  ///
  /// In en, this message translates to:
  /// **'Which setup for the next run?'**
  String get testSessionPickNextSetup;

  /// Snackbar when locking an adjustment that has no value.
  ///
  /// In en, this message translates to:
  /// **'The latest run has no value to lock for this adjustment.'**
  String get testSessionNoValueToLock;

  /// Snackbar after ending a test session.
  ///
  /// In en, this message translates to:
  /// **'Test session \'{name}\' ended.'**
  String testSessionEndedSnack(String name);

  /// Menu option that lets an ended test session run again.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get testSessionResume;

  /// Why an ended test session can't be resumed, shown below the disabled menu option.
  ///
  /// In en, this message translates to:
  /// **'Only the latest session on a bike can be resumed, and only if no setup was added since.'**
  String get testSessionResumeBlocked;

  /// Snackbar after deleting a test session.
  ///
  /// In en, this message translates to:
  /// **'Test session \'{name}\' moved to trash.'**
  String testSessionMovedToTrash(String name);

  /// Snackbar after restoring a test session.
  ///
  /// In en, this message translates to:
  /// **'Test session \'{name}\' restored from trash.'**
  String testSessionRestoredFromTrash(String name);

  /// Title of the dialog shown when recording a setup during a running session.
  ///
  /// In en, this message translates to:
  /// **'End the session first?'**
  String get testSessionEndFirstTitle;

  /// Body of the dialog shown when recording a setup during a running session.
  ///
  /// In en, this message translates to:
  /// **'\'{name}\' is running on this bike. A setup recorded now would confuse its runs. Use Next run to continue the session.'**
  String testSessionEndFirstBody(String name);

  /// Summary of a finished fine-tune session.
  ///
  /// In en, this message translates to:
  /// **'Fine-tuning converged. Nothing left to try.'**
  String get testSessionConvergedFineTune;

  /// Summary of a finished explore session.
  ///
  /// In en, this message translates to:
  /// **'Exploring converged. Nothing left to try.'**
  String get testSessionConvergedExplore;

  /// Summary of a finished compare session.
  ///
  /// In en, this message translates to:
  /// **'Comparing converged. Nothing left to try.'**
  String get testSessionConvergedCompare;

  /// Title of the proposed next run.
  ///
  /// In en, this message translates to:
  /// **'{name} · Suggested'**
  String testSessionSuggestedName(String name);

  /// Name shown when the best run no longer exists.
  ///
  /// In en, this message translates to:
  /// **'The best run'**
  String get testSessionBestRunName;

  /// Label of the winner card of a compare session.
  ///
  /// In en, this message translates to:
  /// **'Best setup'**
  String get testSessionBestSetup;

  /// Label of the winner card of a session.
  ///
  /// In en, this message translates to:
  /// **'Best run'**
  String get testSessionBestRun;

  /// Warning on the winner card when a repeat run lost.
  ///
  /// In en, this message translates to:
  /// **'Ridden again, it lost against a run it had beaten: the trail or you may have changed.'**
  String get testSessionDrift;

  /// Badge of a test session that is running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get badgeRunning;

  /// Badge of the setup that is currently active on its bike.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get badgeCurrentSetup;

  /// Error under the backup list when the local backups could not be listed. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Getting local backups failed: {detail}'**
  String dataErrorGetLocalBackups(String detail);

  /// Error when a local backup file could not be read. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Reading backup failed: {detail}'**
  String dataErrorReadLocalBackup(String detail);

  /// Error when a file picked for import could not be read. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {detail}'**
  String dataErrorImportFile(String detail);

  /// Message when the file picker was closed without choosing a file.
  ///
  /// In en, this message translates to:
  /// **'No file was selected.'**
  String get dataErrorNoFileSelected;

  /// Error when an attachment bundle (ZIP) has no data.json. Keep the file name.
  ///
  /// In en, this message translates to:
  /// **'No data.json found in bundle.'**
  String get dataErrorBundleWithoutData;

  /// Error under the backup list when Google Drive can not be reached.
  ///
  /// In en, this message translates to:
  /// **'Getting Google Drive backups failed: No internet connection. Please connect to a network.'**
  String get dataErrorDriveNoInternet;

  /// Error under the backup list when the Google Drive API refused the request. {detail} is the reason Google gave.
  ///
  /// In en, this message translates to:
  /// **'Google Drive error: {detail}'**
  String dataErrorDriveApi(String detail);

  /// Error under the backup list when loading the Google Drive backups failed for an unknown reason.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get dataErrorDriveUnexpected;

  /// Error when a Google Drive backup could not be downloaded or read. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Reading Google Drive backup failed: {detail}'**
  String dataErrorReadDriveBackup(String detail);

  /// Snackbar after the error report file was written. {path} is the file path.
  ///
  /// In en, this message translates to:
  /// **'Debug file saved to: {path}'**
  String debugFileSaved(String path);

  /// Google Drive sheet error when the Google sign-in could not be set up. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in setup failed: {detail}'**
  String driveErrorSetupFailed(String detail);

  /// Google Drive sheet error for an unexpected failure. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Unknown error: {detail}'**
  String driveErrorUnknown(String detail);

  /// Google Drive sheet message when the person closed the Google sign-in.
  ///
  /// In en, this message translates to:
  /// **'Sign in canceled by user'**
  String get driveErrorSignInCanceled;

  /// Google Drive sheet error when the Google sign-in was interrupted.
  ///
  /// In en, this message translates to:
  /// **'Sign in interrupted'**
  String get driveErrorSignInInterrupted;

  /// Google Drive sheet error when the Google sign-in failed. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Sign in error: {detail}'**
  String driveErrorSignInFailed(String detail);

  /// Google Drive sheet error on a platform without Google sign-in.
  ///
  /// In en, this message translates to:
  /// **'This platform does not support sign-in.'**
  String get driveErrorPlatformUnsupported;

  /// Google Drive sheet error when Google needs the person to allow access again.
  ///
  /// In en, this message translates to:
  /// **'Drive access requires re-authorization.'**
  String get driveErrorReauthRequired;

  /// Google Drive sheet error when the sync failed again after the person allowed access again. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Error after re-authorization: {detail}'**
  String driveErrorReauthFailed(String detail);

  /// Google Drive sheet error when the Drive API refused the request. {detail} is the reason Google gave.
  ///
  /// In en, this message translates to:
  /// **'API error: {detail}'**
  String driveErrorApi(String detail);

  /// Google Drive sheet error when the sync can not reach Google.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please connect to a network.'**
  String get driveErrorNoInternet;

  /// Google Drive sheet error for a failed sync. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Sync error: {detail}'**
  String driveErrorSyncFailed(String detail);

  /// Google Drive sheet error when the saved access expired. 'Sync' is the label of the sync button (driveSheetSync).
  ///
  /// In en, this message translates to:
  /// **'Sync failed: Authorization expired. Please tap \'Sync\' to re-authorize.'**
  String get driveErrorAuthExpired;

  /// Error when the backup could not be uploaded to Google Drive. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Error backing up to Google Drive: {detail}'**
  String driveErrorBackupFailed(String detail);

  /// Snackbar after a backup was uploaded to Google Drive.
  ///
  /// In en, this message translates to:
  /// **'Successfully created Google Drive Backup'**
  String get driveBackupCreated;

  /// Title of the Google Drive sync sheet.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync'**
  String get driveSheetTitle;

  /// Button that signs out of Google Drive.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get driveSheetSignOut;

  /// Button that syncs with Google Drive now.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get driveSheetSync;

  /// Button that starts the Google sign-in.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Google Drive'**
  String get driveSheetSignIn;

  /// Name shown when the Google account has no display name.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get driveSheetUnknownUser;

  /// Title of the account row while signed out.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get driveSheetNotSignedIn;

  /// Subtitle of the account row while signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data'**
  String get driveSheetSignInHint;

  /// Title of the row that explains the automatic sync.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync is active'**
  String get driveSheetAutoSyncTitle;

  /// Subtitle of the row that explains the automatic sync.
  ///
  /// In en, this message translates to:
  /// **'Changes automatically sync with Google Drive.'**
  String get driveSheetAutoSyncSubtitle;

  /// Tooltip that explains the Google Drive sync. 'Import Data -> Backup' names the import menu entry and its backup step (homeMenuImport, importRestoreBackup).
  ///
  /// In en, this message translates to:
  /// **'Bike Setup Tracker automatically syncs changes with your private Google Drive Cloud. Additionally daily backups are created which can be restored via \'Import Data -> Backup\'. Backups are permanently deleted after 30 days. You can also trigger a manual sync.'**
  String get driveSheetInfo;

  /// Date and time of the last Google Drive sync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {date} {time}'**
  String driveSheetLastSync(String date, String time);

  /// Shown when no Google Drive sync has happened yet.
  ///
  /// In en, this message translates to:
  /// **'No sync history found.'**
  String get driveSheetNoSyncHistory;

  /// Tooltip of the app bar Google Drive button while connected.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get driveButtonSyncNow;

  /// Tooltip of the app bar Google Drive button while not connected.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Drive'**
  String get driveButtonConnect;

  /// Tip jar error when the store connection could not be set up. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Tip purchase initialization failed: {detail}'**
  String tipErrorInitFailed(String detail);

  /// Tip jar error when the tip amounts could not be loaded. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Could not load tips: {detail}'**
  String tipErrorLoadFailed(String detail);

  /// Tip jar error when some tip amounts are missing in the store.
  ///
  /// In en, this message translates to:
  /// **'Tips are not fully available. Please try again later.'**
  String get tipErrorTipsUnavailable;

  /// Tip jar error when a tip is tapped before the store answered.
  ///
  /// In en, this message translates to:
  /// **'Tip not loaded yet — try again in a moment.'**
  String get tipErrorTipNotLoaded;

  /// Tip jar error when the purchase failed. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Tip purchase failed: {detail}'**
  String tipErrorPurchaseFailed(String detail);

  /// Title of the tip jar sheet.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get tipJarTitle;

  /// Headline of the tip jar sheet.
  ///
  /// In en, this message translates to:
  /// **'Bike Setup Tracker is free — and stays that way.'**
  String get tipJarHeadline;

  /// Paragraph of the tip jar sheet written by the developer in the first person.
  ///
  /// In en, this message translates to:
  /// **'Building and maintaining it takes a lot of work, and the costs add up — store fees, servers, and more total over €100 a year. I\'m grateful for any support, big or small.'**
  String get tipJarCosts;

  /// Paragraph of the tip jar sheet written by the developer in the first person.
  ///
  /// In en, this message translates to:
  /// **'Feedback and feature wishes are very welcome too — I try to implement them as soon as I can.'**
  String get tipJarFeedback;

  /// Note under the tip amounts.
  ///
  /// In en, this message translates to:
  /// **'A one-time tip — no subscription.'**
  String get tipJarOneTime;

  /// Title shown after a tip was sent.
  ///
  /// In en, this message translates to:
  /// **'Thank you so much! ❤️'**
  String get tipJarThanksTitle;

  /// Text shown after a tip was sent.
  ///
  /// In en, this message translates to:
  /// **'Your support genuinely helps keep Bike Setup Tracker going.'**
  String get tipJarThanksBody;

  /// Title of the confirmation dialog before the settings are reset.
  ///
  /// In en, this message translates to:
  /// **'Reset settings?'**
  String get dataResetSettingsTitle;

  /// Body of the confirmation dialog before the settings are reset.
  ///
  /// In en, this message translates to:
  /// **'All preferences, features and filters are restored to their defaults. Your data is not affected.'**
  String get dataResetSettingsBody;

  /// Confirm button of the reset settings dialog.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get dataResetSettingsConfirm;

  /// Snackbar after the settings were reset.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults.'**
  String get dataResetSettingsDone;

  /// Snackbar when resetting the settings failed. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Resetting settings failed: {error}'**
  String dataResetSettingsFailed(String error);

  /// Title of the confirmation dialog before all local backups are deleted.
  ///
  /// In en, this message translates to:
  /// **'Delete all backups?'**
  String get dataDeleteBackupsTitle;

  /// Body of the confirmation dialog before all local backups are deleted.
  ///
  /// In en, this message translates to:
  /// **'All automatic backups stored on this device are deleted. This action cannot be undone.'**
  String get dataDeleteBackupsBody;

  /// Confirm button of the delete all backups dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dataDeleteBackupsConfirm;

  /// Snackbar after local backups were deleted. {count} is the number of deleted backups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 backup.} other{Deleted {count} backups.}}'**
  String dataDeleteBackupsDone(int count);

  /// Snackbar when deleting the backups failed. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Deleting backups failed: {error}'**
  String dataDeleteBackupsFailed(String error);

  /// Title of the confirmation dialog before all data is deleted.
  ///
  /// In en, this message translates to:
  /// **'Clear database?'**
  String get dataClearDatabaseTitle;

  /// Body of the confirmation dialog before all data is deleted.
  ///
  /// In en, this message translates to:
  /// **'All bikes, components, setups, riders, tasks and attachments are deleted. A backup is saved first. This action cannot be undone.'**
  String get dataClearDatabaseBody;

  /// Confirm button of the clear database dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get dataClearDatabaseConfirm;

  /// Snackbar when the safety backup failed, so nothing was deleted.
  ///
  /// In en, this message translates to:
  /// **'Could not save a backup. Database was not cleared.'**
  String get dataClearDatabaseNoBackup;

  /// Snackbar after all data was deleted.
  ///
  /// In en, this message translates to:
  /// **'Database cleared.'**
  String get dataClearDatabaseDone;

  /// Snackbar when clearing the database failed. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Clearing database failed: {error}'**
  String dataClearDatabaseFailed(String error);

  /// Error text when a request failed because the device is offline. Used by the Strava and subscription errors.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your connection and try again.'**
  String get errorNoInternetRetry;

  /// Strava sheet error when a sync failed without a known reason.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get stravaErrorSyncFailed;

  /// Strava sheet error when a sync failed. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {detail}'**
  String stravaErrorSyncFailedDetail(String detail);

  /// Strava sheet error when the connection to the Strava account could not be verified.
  ///
  /// In en, this message translates to:
  /// **'Connection verify failed'**
  String get stravaErrorConnectionVerifyFailed;

  /// Strava sheet error when the live import of activities stopped.
  ///
  /// In en, this message translates to:
  /// **'Background sync error'**
  String get stravaErrorBackgroundSyncFailed;

  /// Strava sheet error when the app server can not be reached.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach our servers. Check your connection and try again.'**
  String get stravaErrorServerUnreachable;

  /// Strava sheet error when no browser can open the Strava sign-in link.
  ///
  /// In en, this message translates to:
  /// **'Could not find a program to launch the link.'**
  String get stravaErrorNoBrowser;

  /// Strava sheet error when starting the sign-in failed. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {detail}'**
  String stravaErrorLoginFailed(String detail);

  /// Strava sheet error when the person has no active Strava Sync subscription.
  ///
  /// In en, this message translates to:
  /// **'An active Strava Sync subscription is required.'**
  String get stravaErrorSubscriptionRequired;

  /// Strava sheet error when the Strava sign-in failed. {detail} is the error code Strava returned.
  ///
  /// In en, this message translates to:
  /// **'Strava sign-in failed: {detail}'**
  String stravaErrorSignInFailed(String detail);

  /// Strava sheet error when the Strava sign-in failed without a reason.
  ///
  /// In en, this message translates to:
  /// **'Strava sign-in failed. Please try again.'**
  String get stravaErrorSignInFailedGeneric;

  /// Strava sheet error when disconnecting Strava failed. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Disconnection failed: {detail}'**
  String stravaErrorDisconnectFailed(String detail);

  /// Strava sheet error when the full history sync failed. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Full history sync failed: {detail}'**
  String stravaErrorFullSyncFailed(String detail);

  /// Strava sheet error when the app could not authenticate with the server.
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Please try again or reconnect to Strava.'**
  String get stravaErrorAuthentication;

  /// Strava sheet error when the server limits the requests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get stravaErrorRateLimited;

  /// Error when the app store reports a failure while listening for purchases. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Purchase stream error: {detail}'**
  String storeErrorStreamFailed(String detail);

  /// Error when the app store can not be used on this device.
  ///
  /// In en, this message translates to:
  /// **'Store is not available on this device.'**
  String get storeErrorUnavailable;

  /// Paywall error after restoring purchases found nothing.
  ///
  /// In en, this message translates to:
  /// **'No previous purchase found for this account. Make sure you are signed in to the same Google/Apple account that bought the subscription.'**
  String get subscriptionErrorNoPreviousPurchase;

  /// Paywall error when the subscription could not be set up. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Subscription init failed: {detail}'**
  String subscriptionErrorInitFailed(String detail);

  /// Paywall error when the subscription status could not be read. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Entitlement stream error: {detail}'**
  String subscriptionErrorEntitlementStreamFailed(String detail);

  /// Paywall error when the plans could not be loaded from the store. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Could not load plans: {detail}'**
  String subscriptionErrorPlansLoadFailed(String detail);

  /// Paywall error when a plan is missing in the store.
  ///
  /// In en, this message translates to:
  /// **'Subscription plans are not fully available. Please try again later.'**
  String get subscriptionErrorPlansUnavailable;

  /// Paywall error when a plan is chosen before the store answered.
  ///
  /// In en, this message translates to:
  /// **'Plan not loaded yet — try again in a moment.'**
  String get subscriptionErrorPlanNotLoaded;

  /// Paywall error when the purchase failed. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {detail}'**
  String subscriptionErrorPurchaseFailed(String detail);

  /// Paywall error when restoring a purchase failed. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {detail}'**
  String subscriptionErrorRestoreFailed(String detail);

  /// Paywall error when the App Store did not return a transaction id.
  ///
  /// In en, this message translates to:
  /// **'Missing transaction id for iOS purchase.'**
  String get subscriptionErrorMissingTransactionId;

  /// Paywall error when the store reports the subscription as ended.
  ///
  /// In en, this message translates to:
  /// **'This subscription is no longer active on your store account. If you renewed recently, try again in a moment.'**
  String get subscriptionErrorInactive;

  /// Paywall error when the server could not confirm the purchase. {detail} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Could not verify purchase: {detail}'**
  String subscriptionErrorVerifyFailed(String detail);

  /// Paywall error when the app could not authenticate with the server.
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Please try again.'**
  String get subscriptionErrorAuthentication;

  /// Title of the Strava sheets. Strava Sync is the name of the feature.
  ///
  /// In en, this message translates to:
  /// **'Strava Sync'**
  String get stravaSheetTitle;

  /// Title of the Strava sheet shown when the app server can not be reached.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get stravaOfflineTitle;

  /// Text of the Strava sheet shown when the app server can not be reached.
  ///
  /// In en, this message translates to:
  /// **'We can\'t reach our servers to check Strava availability. Connect to the internet and try again.'**
  String get stravaOfflineBody;

  /// Button that checks the Strava availability again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get stravaTryAgain;

  /// Button that closes a sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Title of the Strava sheet shown when no new subscriptions are accepted.
  ///
  /// In en, this message translates to:
  /// **'Strava Sync is at capacity'**
  String get stravaWaitlistTitle;

  /// Text of the Strava sheet shown when no new subscriptions are accepted.
  ///
  /// In en, this message translates to:
  /// **'Strava\'s API limits how many active users we can sync at once. We\'re temporarily not accepting new subscriptions to keep sync reliable for current users. We\'ll open new spots as soon as we can.'**
  String get stravaWaitlistBody;

  /// Title after a free trial of Strava Sync was started.
  ///
  /// In en, this message translates to:
  /// **'Your trial has started.'**
  String get stravaSuccessTrialTitle;

  /// Title after Strava Sync was subscribed.
  ///
  /// In en, this message translates to:
  /// **'You\'re in.'**
  String get stravaSuccessTitle;

  /// Text after a free trial of Strava Sync was started.
  ///
  /// In en, this message translates to:
  /// **'Strava Sync is fully active for 7 days. Connect your Strava login next to import your history. Cancel in your store settings before the trial ends to avoid a charge.'**
  String get stravaSuccessTrialBody;

  /// Text after Strava Sync was subscribed.
  ///
  /// In en, this message translates to:
  /// **'Strava Sync is active on this account. Connect your Strava login next so we can start importing activities.'**
  String get stravaSuccessBody;

  /// Title of the Strava sheet that asks to sign in to Strava.
  ///
  /// In en, this message translates to:
  /// **'Connect to Strava'**
  String get stravaConnectTitle;

  /// Text of the Strava sheet that asks to sign in to Strava.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Strava account to sync activities.'**
  String get stravaConnectBody;

  /// Button that starts the Strava sign-in.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Strava'**
  String get stravaSignIn;

  /// Button that closes the Strava sign-in prompt.
  ///
  /// In en, this message translates to:
  /// **'Connect later'**
  String get stravaConnectLater;

  /// Headline of the Strava Sync paywall.
  ///
  /// In en, this message translates to:
  /// **'Pair every setup with the ride you actually rode.'**
  String get paywallHeroTitle;

  /// Subline of the Strava Sync paywall headline.
  ///
  /// In en, this message translates to:
  /// **'Connect Strava and your activities flow in automatically.'**
  String get paywallHeroSubtitle;

  /// Section title above the plans of the paywall. Shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get paywallChoosePlan;

  /// Badge of the yearly plan. {percent} is the saving against the monthly plan.
  ///
  /// In en, this message translates to:
  /// **'SAVE {percent}%'**
  String paywallSavePercent(int percent);

  /// Note under the price of a plan that has a free trial.
  ///
  /// In en, this message translates to:
  /// **'7 days free'**
  String get paywallTrialBadge;

  /// Title of the first benefit of Strava Sync.
  ///
  /// In en, this message translates to:
  /// **'Activities as context'**
  String get paywallFeature1Title;

  /// Text of the first benefit of Strava Sync.
  ///
  /// In en, this message translates to:
  /// **'See which setup you ran on every ride — automatically linked by date and gear.'**
  String get paywallFeature1Body;

  /// Title of the second benefit of Strava Sync.
  ///
  /// In en, this message translates to:
  /// **'Setups on the map'**
  String get paywallFeature2Title;

  /// Text of the second benefit of Strava Sync.
  ///
  /// In en, this message translates to:
  /// **'Activity start points and saved setups together, so you can revisit what worked at a spot.'**
  String get paywallFeature2Body;

  /// Title of the third benefit of Strava Sync.
  ///
  /// In en, this message translates to:
  /// **'Real-time auto-sync'**
  String get paywallFeature3Title;

  /// Text of the third benefit of Strava Sync.
  ///
  /// In en, this message translates to:
  /// **'New, updated and deleted Strava activities import within seconds.'**
  String get paywallFeature3Body;

  /// Section title of the notes card of the paywall. Shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'How this works'**
  String get paywallHowItWorks;

  /// First note of the paywall about the trademark. Keep the company name.
  ///
  /// In en, this message translates to:
  /// **'Strava is a third-party service. Strava and the Strava logo are registered trademarks of Strava, Inc. — Bike Setup Tracker is not affiliated with or endorsed by Strava.'**
  String get paywallNoteAffiliation;

  /// Second note of the paywall.
  ///
  /// In en, this message translates to:
  /// **'Your subscription covers the server costs of syncing activities between Strava and your device.'**
  String get paywallNoteCosts;

  /// Third note of the paywall.
  ///
  /// In en, this message translates to:
  /// **'We only store the activity fields needed to match a ride to a setup (date, name, location, gear). You can disconnect Strava at any time.'**
  String get paywallNoteData;

  /// Link text to the subscription settings on iOS. Used inside paywallLegalTrial and paywallLegalAuto.
  ///
  /// In en, this message translates to:
  /// **'App Store settings'**
  String get paywallStoreSettingsIos;

  /// Link text to the subscription settings on Android. Used inside paywallLegalTrial and paywallLegalAuto.
  ///
  /// In en, this message translates to:
  /// **'Google Play settings'**
  String get paywallStoreSettingsAndroid;

  /// Legal note under the plans when a free trial is available. The tags <store>, <terms> and <privacy> mark the links and must stay around the same words. {price} is the store price and {period} the billing period, e.g. "/ year".
  ///
  /// In en, this message translates to:
  /// **'7 days free, then {price}{period}. Cancel before the trial ends to avoid a charge. Manage or cancel anytime in your <store>{store}</store>. By subscribing you agree to <terms>Terms of Use</terms> and <privacy>Privacy Policy</privacy>.'**
  String paywallLegalTrial(String price, String period, String store);

  /// Legal note under the plans when no free trial is available. The tags <store>, <terms> and <privacy> mark the links and must stay around the same words.
  ///
  /// In en, this message translates to:
  /// **'Auto-renewable subscription. Manage or cancel anytime in your <store>{store}</store>. By subscribing you agree to <terms>Terms of Use</terms> and <privacy>Privacy Policy</privacy>.'**
  String paywallLegalAuto(String store);

  /// Label of the subscribe button while the store price is loading.
  ///
  /// In en, this message translates to:
  /// **'Loading store price…'**
  String get paywallLoadingPrice;

  /// Label of the subscribe button when a free trial is available.
  ///
  /// In en, this message translates to:
  /// **'Start 7-day free trial'**
  String get paywallStartTrial;

  /// Label of the subscribe button. {price} is the store price and {period} the billing period, e.g. "/year".
  ///
  /// In en, this message translates to:
  /// **'Subscribe — {price}{period}'**
  String paywallSubscribe(String price, String period);

  /// Button that restores a purchase made earlier with the same store account.
  ///
  /// In en, this message translates to:
  /// **'Restore previous purchase'**
  String get paywallRestore;

  /// Row shown while Strava is syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get stravaSyncing;

  /// Row shown while Strava is being disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting...'**
  String get stravaDisconnecting;

  /// Title of the account row while Strava is not connected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get stravaNotConnected;

  /// Subtitle of the account row while Strava is not connected.
  ///
  /// In en, this message translates to:
  /// **'Connect to sync your rides'**
  String get stravaNotConnectedHint;

  /// Subtitle of the account row with the Strava athlete number.
  ///
  /// In en, this message translates to:
  /// **'Athlete ID: {id}'**
  String stravaAthleteId(int id);

  /// Title of the row that explains the automatic Strava import.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync is active'**
  String get stravaAutoSyncTitle;

  /// Subtitle of the row that explains the automatic Strava import.
  ///
  /// In en, this message translates to:
  /// **'Activities import automatically after your ride.'**
  String get stravaAutoSyncSubtitle;

  /// Tooltip that explains the Strava sync.
  ///
  /// In en, this message translates to:
  /// **'Bike Setup Tracker automatically imports new, updated, or deleted Strava activities in real-time. While most updates are instant, a full background sync also runs weekly to catch any missed changes. You can also trigger a manual sync once per hour.'**
  String get stravaSyncInfo;

  /// Date and time of the last full Strava sync.
  ///
  /// In en, this message translates to:
  /// **'Last full sync: {date} {time}'**
  String stravaLastFullSync(String date, String time);

  /// Shown when no full Strava sync has happened yet.
  ///
  /// In en, this message translates to:
  /// **'No full sync yet'**
  String get stravaNoFullSync;

  /// Date and time of the next automatic full Strava sync.
  ///
  /// In en, this message translates to:
  /// **'Next scheduled sync: {date} {time}'**
  String stravaNextScheduledSync(String date, String time);

  /// Date and time from which a manual Strava sync is possible again.
  ///
  /// In en, this message translates to:
  /// **'Next manual sync available: {date} {time}'**
  String stravaNextManualSync(String date, String time);

  /// Label of the sync button while a sync runs.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get stravaSyncButtonSyncing;

  /// Label of the button that starts a manual Strava sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get stravaSyncButtonSync;

  /// Label of the sync button while the next manual sync is not available yet. {time} is the remaining time, e.g. 12 min.
  ///
  /// In en, this message translates to:
  /// **'In {time}'**
  String stravaSyncButtonIn(String time);

  /// Developer button that syncs the full Strava history.
  ///
  /// In en, this message translates to:
  /// **'Full Sync'**
  String get stravaFullSync;

  /// Section title above the latest Strava activities.
  ///
  /// In en, this message translates to:
  /// **'Latest Activities:'**
  String get stravaLatestActivities;

  /// Title of the empty state of the latest Strava activities.
  ///
  /// In en, this message translates to:
  /// **'No activities synced yet.'**
  String get stravaNoActivitiesTitle;

  /// Text of the empty state of the latest Strava activities.
  ///
  /// In en, this message translates to:
  /// **'Connect Strava and sync your rides to see activities here.'**
  String get stravaNoActivitiesHint;

  /// Section title above the Strava gear that can be linked to bikes.
  ///
  /// In en, this message translates to:
  /// **'Strava Gear:'**
  String get stravaGearSectionTitle;

  /// Button that expands the list of Strava gear.
  ///
  /// In en, this message translates to:
  /// **'Show all ({count})'**
  String stravaGearShowAll(int count);

  /// Button that collapses the list of Strava gear.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get stravaGearShowLess;

  /// Subtitle of a Strava gear that no bike uses.
  ///
  /// In en, this message translates to:
  /// **'Not linked to a bike'**
  String get stravaGearNotLinked;

  /// Tooltip of the menu of a linked Strava gear. {name} is the gear name.
  ///
  /// In en, this message translates to:
  /// **'Options for \'{name}\''**
  String stravaGearOptionsTooltip(String name);

  /// Tooltip of the link button of an unlinked Strava gear. {name} is the gear name.
  ///
  /// In en, this message translates to:
  /// **'Link \'{name}\' to a bike'**
  String stravaGearLinkTooltip(String name);

  /// Button that links a Strava gear to a bike.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get stravaGearLink;

  /// Menu entry that removes the link between a Strava gear and a bike. {name} is the bike name.
  ///
  /// In en, this message translates to:
  /// **'Unlink Bike \'{name}\''**
  String stravaGearUnlinkBike(String name);

  /// Menu entry that links a Strava gear to a bike. {name} is the bike name.
  ///
  /// In en, this message translates to:
  /// **'Link to \'{name}\''**
  String stravaGearLinkToBike(String name);

  /// Menu entry that creates a bike from a Strava gear.
  ///
  /// In en, this message translates to:
  /// **'Add as new Bike'**
  String get stravaGearAddAsBike;

  /// Title of the subscription card. Shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Strava Sync'**
  String get stravaCardTitle;

  /// Badge of the subscription card without a subscription. Shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Not subscribed'**
  String get stravaCardNotSubscribed;

  /// Badge of the subscription card during the free trial. Shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get stravaCardTrial;

  /// Badge of the subscription card with an active subscription. Shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get stravaCardActive;

  /// Badge of the subscription card after the subscription ended. Shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get stravaCardExpired;

  /// Text of the subscription card without a subscription.
  ///
  /// In en, this message translates to:
  /// **'Automatically link your Strava rides to your setups and see them on the map.'**
  String get stravaCardPitch;

  /// Price line of the subscription card without a subscription. {price} is the monthly store price.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String stravaCardFromPrice(String price);

  /// Label of the date of the first payment after a free trial.
  ///
  /// In en, this message translates to:
  /// **'First charge'**
  String get stravaCardFirstCharge;

  /// Label of the date a free trial ends without renewal.
  ///
  /// In en, this message translates to:
  /// **'Trial ends'**
  String get stravaCardTrialEnds;

  /// Label of the date a subscription renews.
  ///
  /// In en, this message translates to:
  /// **'Renews'**
  String get stravaCardRenews;

  /// Label of the date a subscription ends.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get stravaCardExpires;

  /// Label of the row that names the store that bills the subscription.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get stravaCardBilling;

  /// Title of the Strava activity page.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get stravaActivityTitle;

  /// Name shown when the athlete of an activity is unknown.
  ///
  /// In en, this message translates to:
  /// **'Strava Athlete'**
  String get stravaActivityAthleteFallback;

  /// Short label of the elevation gain figure of an activity.
  ///
  /// In en, this message translates to:
  /// **'Elev Gain'**
  String get stravaActivityElevGain;

  /// Short label of the average speed figure of an activity.
  ///
  /// In en, this message translates to:
  /// **'Avg Speed'**
  String get stravaActivityAvgSpeed;

  /// Short label of the average power figure of an activity. Tapping switches to Energy.
  ///
  /// In en, this message translates to:
  /// **'Avg Power'**
  String get stravaActivityAvgPower;

  /// Short label of the energy figure (kilojoules) of an activity. Tapping switches to Avg Power.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get stravaActivityEnergy;

  /// Title when no bike uses the Strava gear of an activity.
  ///
  /// In en, this message translates to:
  /// **'No Bike linked to this Strava gear'**
  String get stravaActivityNoBikeLinked;

  /// Hint when no bike uses the Strava gear and no bike is free to link.
  ///
  /// In en, this message translates to:
  /// **'Add a new bike to link this gear automatically'**
  String get stravaActivityAddBikeHint;

  /// Hint when no bike uses the Strava gear and bikes are free to link.
  ///
  /// In en, this message translates to:
  /// **'Link an existing bike or add a new bike for this gear'**
  String get stravaActivityLinkBikeHint;

  /// Button that opens the list of bikes to link to the Strava gear.
  ///
  /// In en, this message translates to:
  /// **'Link Bike'**
  String get stravaActivityLinkBike;

  /// Button that creates a bike for the Strava gear.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get stravaActivityAddNew;

  /// Title of the section with the setups of an activity.
  ///
  /// In en, this message translates to:
  /// **'Setups ({count})'**
  String stravaActivitySetupsTitle(int count);

  /// Subtitle of the setups section with the number of feedbacks of the ride.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 feedback} other{{count} feedbacks}}'**
  String stravaActivityFeedbackCount(int count);

  /// Title when no setup belongs to an activity.
  ///
  /// In en, this message translates to:
  /// **'No setups for this activity'**
  String get stravaActivityNoSetupsTitle;

  /// Hint when no setup belongs to an activity.
  ///
  /// In en, this message translates to:
  /// **'Add a setup to record your bike configuration'**
  String get stravaActivityNoSetupsSubtitle;

  /// Hint that no setup can be added while a test session runs. {name} is the session name.
  ///
  /// In en, this message translates to:
  /// **'Test session \'{name}\' is running on this bike. End it to add a setup.'**
  String stravaActivitySessionRunning(String name);

  /// Tooltip of the menu button of the Strava activity page.
  ///
  /// In en, this message translates to:
  /// **'Activity actions'**
  String get stravaActivityActionsTooltip;

  /// Note under a disabled map entry of the activity menu.
  ///
  /// In en, this message translates to:
  /// **'Start location not available'**
  String get stravaActivityNoStartLocation;

  /// Snackbar after an exported file was saved.
  ///
  /// In en, this message translates to:
  /// **'File saved'**
  String get exportFileSaved;

  /// Snackbar when saving an export failed. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// Snackbar when the latest backup was requested but none exists.
  ///
  /// In en, this message translates to:
  /// **'No backup found yet.'**
  String get exportNoBackup;

  /// Message that is sent along with the shared JSON file.
  ///
  /// In en, this message translates to:
  /// **'Here is my bike setup data!'**
  String get shareMessageJson;

  /// Message that is sent along with the shared Excel file.
  ///
  /// In en, this message translates to:
  /// **'Here is my bike setup data in Excel format!'**
  String get shareMessageExcel;

  /// Message that is sent along with the shared CSV file.
  ///
  /// In en, this message translates to:
  /// **'Here is my bike setup data in CSV format!'**
  String get shareMessageCsv;

  /// Start of the snackbar when sharing a file failed. The technical reason follows after a colon.
  ///
  /// In en, this message translates to:
  /// **'Error sharing file'**
  String get shareErrorFile;

  /// Start of the snackbar when sharing the Excel file failed. The technical reason follows after a colon.
  ///
  /// In en, this message translates to:
  /// **'Error sharing Excel file'**
  String get shareErrorExcel;

  /// Start of the snackbar when sharing the CSV file failed. The technical reason follows after a colon.
  ///
  /// In en, this message translates to:
  /// **'Error sharing CSV file'**
  String get shareErrorCsv;

  /// Start of the snackbar when sharing text failed. The technical reason follows after a colon.
  ///
  /// In en, this message translates to:
  /// **'Error sharing text'**
  String get shareErrorText;

  /// Snackbar when the JSON file for sharing could not be created. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Error preparing JSON: {error}'**
  String sharePrepareJsonFailed(String error);

  /// Snackbar when the Excel file for sharing could not be created. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Error preparing Excel: {error}'**
  String sharePrepareExcelFailed(String error);

  /// Snackbar when the CSV file for sharing could not be created. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Error preparing CSV: {error}'**
  String sharePrepareCsvFailed(String error);

  /// Snackbar after a local backup was written. {path} is the file path.
  ///
  /// In en, this message translates to:
  /// **'Saved backup at {path}'**
  String backupSaved(String path);

  /// Snackbar when writing a local backup failed. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Error saving backup: {error}'**
  String backupSaveFailed(String error);

  /// Title of the export sheet.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportSheetTitle;

  /// Entry of the export sheet that saves a JSON file.
  ///
  /// In en, this message translates to:
  /// **'Save File'**
  String get exportSaveFile;

  /// Subtitle of the entry that saves a JSON file.
  ///
  /// In en, this message translates to:
  /// **'Choose where to save the JSON file'**
  String get exportSaveFileSubtitle;

  /// Entry of the export sheet that saves a local backup.
  ///
  /// In en, this message translates to:
  /// **'Save Backup'**
  String get exportSaveBackup;

  /// Subtitle of the entry that saves a local backup.
  ///
  /// In en, this message translates to:
  /// **'Save current state as a local backup'**
  String get exportSaveBackupSubtitle;

  /// Entry of the export sheet that saves a backup to Google Drive.
  ///
  /// In en, this message translates to:
  /// **'Save Google Drive Backup'**
  String get exportSaveDriveBackup;

  /// Subtitle of the entry that saves a backup to Google Drive.
  ///
  /// In en, this message translates to:
  /// **'Save current state as Backup in Google Drive'**
  String get exportSaveDriveBackupSubtitle;

  /// Entry of the export sheet that saves data and attachments as a ZIP file.
  ///
  /// In en, this message translates to:
  /// **'Export Attachment Bundle'**
  String get exportAttachmentBundle;

  /// Subtitle of the entry that saves data and attachments as a ZIP file.
  ///
  /// In en, this message translates to:
  /// **'Export data and attachments as a ZIP bundle'**
  String get exportAttachmentBundleSubtitle;

  /// Progress text while a JSON file is created, in the export and share sheets.
  ///
  /// In en, this message translates to:
  /// **'Preparing JSON file…'**
  String get exportProgressFile;

  /// Progress text while a local backup is saved.
  ///
  /// In en, this message translates to:
  /// **'Saving backup…'**
  String get exportProgressBackup;

  /// Progress text while a backup is uploaded to Google Drive.
  ///
  /// In en, this message translates to:
  /// **'Uploading backup to Google Drive…'**
  String get exportProgressDrive;

  /// Progress text while a ZIP bundle is created.
  ///
  /// In en, this message translates to:
  /// **'Packing data and attachments…'**
  String get exportProgressBundle;

  /// Title of the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share Data'**
  String get shareSheetTitle;

  /// Title of the step that chooses the format to share.
  ///
  /// In en, this message translates to:
  /// **'Share Format'**
  String get shareFormatTitle;

  /// Share format JSON.
  ///
  /// In en, this message translates to:
  /// **'JSON File'**
  String get shareFormatJson;

  /// Explanation of the JSON share format.
  ///
  /// In en, this message translates to:
  /// **'Best for moving data to another device or saving a full backup.'**
  String get shareFormatJsonSubtitle;

  /// Share format Excel.
  ///
  /// In en, this message translates to:
  /// **'Excel Spreadsheet'**
  String get shareFormatExcel;

  /// Explanation of the Excel share format.
  ///
  /// In en, this message translates to:
  /// **'Best for analysis in Excel or Google Sheets (XLSX).'**
  String get shareFormatExcelSubtitle;

  /// Share format CSV.
  ///
  /// In en, this message translates to:
  /// **'CSV File'**
  String get shareFormatCsv;

  /// Explanation of the CSV share format.
  ///
  /// In en, this message translates to:
  /// **'Simple tabular format (Comma Separated Values).'**
  String get shareFormatCsvSubtitle;

  /// Share format plain text.
  ///
  /// In en, this message translates to:
  /// **'Plain Text'**
  String get shareFormatText;

  /// Explanation of the plain text share format.
  ///
  /// In en, this message translates to:
  /// **'Best for sharing setup details in chats or notes.'**
  String get shareFormatTextSubtitle;

  /// Progress text while the text to share is created.
  ///
  /// In en, this message translates to:
  /// **'Preparing text…'**
  String get shareProgressText;

  /// Progress text while the CSV file to share is created.
  ///
  /// In en, this message translates to:
  /// **'Preparing CSV file…'**
  String get shareProgressCsv;

  /// Progress text while the Excel file to share is created.
  ///
  /// In en, this message translates to:
  /// **'Preparing Excel file…'**
  String get shareProgressExcel;

  /// Title of the import sheets.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importSheetTitle;

  /// Entry of the import sheet that reads a file.
  ///
  /// In en, this message translates to:
  /// **'Import File'**
  String get importFile;

  /// Subtitle of the entry that reads a file.
  ///
  /// In en, this message translates to:
  /// **'Select json file which contains data to import'**
  String get importFileSubtitle;

  /// Entry of the import sheet that restores a backup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get importRestoreBackup;

  /// Subtitle of the entry that restores a backup.
  ///
  /// In en, this message translates to:
  /// **'Restore local or cloud Backup'**
  String get importRestoreBackupSubtitle;

  /// Entry of the import sheet that reads a ZIP bundle.
  ///
  /// In en, this message translates to:
  /// **'Import Attachment Bundle'**
  String get importAttachmentBundle;

  /// Subtitle of the entry that reads a ZIP bundle.
  ///
  /// In en, this message translates to:
  /// **'Restore data and attachments from a ZIP bundle'**
  String get importAttachmentBundleSubtitle;

  /// Progress text while the picked file is read.
  ///
  /// In en, this message translates to:
  /// **'Reading file…'**
  String get importReadingFile;

  /// Progress text while a ZIP bundle is unpacked.
  ///
  /// In en, this message translates to:
  /// **'Unpacking data and attachments…'**
  String get importUnpackingBundle;

  /// Import method that overwrites local items with the imported ones.
  ///
  /// In en, this message translates to:
  /// **'Overwrite data'**
  String get importMethodOverwrite;

  /// Explanation of the overwrite import method.
  ///
  /// In en, this message translates to:
  /// **'Overwrite your local data with the imported data. Unique local data will remain.'**
  String get importMethodOverwriteSubtitle;

  /// Import method that adds new items and updates newer ones.
  ///
  /// In en, this message translates to:
  /// **'Merge data'**
  String get importMethodMerge;

  /// Explanation of the merge import method.
  ///
  /// In en, this message translates to:
  /// **'Add new items and update existing items when the imported version is newer (based on modification date).'**
  String get importMethodMergeSubtitle;

  /// Import method that deletes the local data first.
  ///
  /// In en, this message translates to:
  /// **'Replace data'**
  String get importMethodReplace;

  /// Explanation of the replace import method.
  ///
  /// In en, this message translates to:
  /// **'Replace your local data with the imported data. This will permanently delete all existing data and cannot be undone.'**
  String get importMethodReplaceSubtitle;

  /// Progress text while data is merged.
  ///
  /// In en, this message translates to:
  /// **'Merging data…'**
  String get importProgressMerge;

  /// Progress text while data is overwritten.
  ///
  /// In en, this message translates to:
  /// **'Overwriting data…'**
  String get importProgressOverwrite;

  /// Progress text while data is replaced.
  ///
  /// In en, this message translates to:
  /// **'Replacing data…'**
  String get importProgressReplace;

  /// Snackbar after data was merged.
  ///
  /// In en, this message translates to:
  /// **'Data merged successfully'**
  String get importDoneMerge;

  /// Snackbar after data was overwritten.
  ///
  /// In en, this message translates to:
  /// **'Data overwritten successfully'**
  String get importDoneOverwrite;

  /// Snackbar after data was replaced.
  ///
  /// In en, this message translates to:
  /// **'Data replaced successfully'**
  String get importDoneReplace;

  /// Snackbar when merging failed. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Merge failed: {error}'**
  String importFailedMerge(String error);

  /// Snackbar when overwriting failed. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Overwriting failed: {error}'**
  String importFailedOverwrite(String error);

  /// Snackbar when replacing failed. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Replacing failed: {error}'**
  String importFailedReplace(String error);

  /// Title of the sheet that lists the backups.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get backupSheetTitle;

  /// Note at the top of the backup list.
  ///
  /// In en, this message translates to:
  /// **'Backups are created once per day. To restore a backup, you can choose to overwrite current data or merge backup data into existing data.'**
  String get backupInfoDaily;

  /// Note at the top of the backup list.
  ///
  /// In en, this message translates to:
  /// **'Backups older than 30 days are permanently deleted and cannot be restored.'**
  String get backupInfoRetention;

  /// Name of a backup stored on this device.
  ///
  /// In en, this message translates to:
  /// **'Local Backup'**
  String get backupLocal;

  /// Name of a backup stored in Google Drive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Backup'**
  String get backupGoogleDrive;

  /// Subtitle of a local backup while it is read.
  ///
  /// In en, this message translates to:
  /// **'Reading backup…'**
  String get backupReading;

  /// Subtitle of a Google Drive backup while it is downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloading backup…'**
  String get backupDownloading;

  /// Subtitle of a backup. {time} is the date and time of the backup.
  ///
  /// In en, this message translates to:
  /// **'Created at: {time}'**
  String backupCreatedAt(String time);

  /// Tooltip of the button that restores a backup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get backupRestoreTooltip;

  /// Shown when the backup list could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Error loading backups'**
  String get backupLoadError;

  /// Shown when there are no backups.
  ///
  /// In en, this message translates to:
  /// **'No backups found.'**
  String get backupNone;

  /// Title of the step that chooses between all data and specific items.
  ///
  /// In en, this message translates to:
  /// **'Select Data'**
  String get dataSelectTitle;

  /// Entry that uses all items.
  ///
  /// In en, this message translates to:
  /// **'Entire dataset'**
  String get dataSelectAll;

  /// Subtitle of the entry that uses all items.
  ///
  /// In en, this message translates to:
  /// **'Use all items from the provided data'**
  String get dataSelectAllSubtitle;

  /// Entry that opens the item selection.
  ///
  /// In en, this message translates to:
  /// **'Choose specific items'**
  String get dataSelectChoose;

  /// Subtitle of the entry that opens the item selection.
  ///
  /// In en, this message translates to:
  /// **'Pick which items to include'**
  String get dataSelectChooseSubtitle;

  /// Title of the step that picks single items.
  ///
  /// In en, this message translates to:
  /// **'Select Data Items'**
  String get dataSelectItemsTitle;

  /// Section title with the number of selected bikes.
  ///
  /// In en, this message translates to:
  /// **'Bikes ({selected} / {total})'**
  String dataSelectBikes(int selected, int total);

  /// Section title with the number of selected components.
  ///
  /// In en, this message translates to:
  /// **'Components ({selected} / {total})'**
  String dataSelectComponents(int selected, int total);

  /// Section title with the number of selected setups.
  ///
  /// In en, this message translates to:
  /// **'Setups ({selected} / {total})'**
  String dataSelectSetups(int selected, int total);

  /// Section title with the number of selected riders.
  ///
  /// In en, this message translates to:
  /// **'Riders ({selected} / {total})'**
  String dataSelectRiders(int selected, int total);

  /// Section title with the number of selected tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks ({selected} / {total})'**
  String dataSelectTasks(int selected, int total);

  /// Section title with the number of selected task entries.
  ///
  /// In en, this message translates to:
  /// **'Task Entries ({selected} / {total})'**
  String dataSelectTaskEntries(int selected, int total);

  /// Section title with the number of selected feedbacks.
  ///
  /// In en, this message translates to:
  /// **'Feedback ({selected} / {total})'**
  String dataSelectFeedback(int selected, int total);

  /// Section title with the number of selected test sessions.
  ///
  /// In en, this message translates to:
  /// **'Test Sessions ({selected} / {total})'**
  String dataSelectTestSessions(int selected, int total);

  /// Button that confirms the selection. Shows how many items are selected.
  ///
  /// In en, this message translates to:
  /// **'Confirm Selection ({selected} / {total})'**
  String dataSelectConfirm(int selected, int total);

  /// Note next to the Strava gear title with how many gear items are linked to a bike.
  ///
  /// In en, this message translates to:
  /// **'{linked} of {total} linked'**
  String stravaGearLinkedCount(int linked, int total);

  /// Sheet name of the Excel export when there is nothing to export.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get exportNoDataSheet;

  /// Message in the only sheet of the Excel export when there are no bikes.
  ///
  /// In en, this message translates to:
  /// **'No bikes found or data is empty.'**
  String get exportNoBikes;

  /// Spreadsheet export: heading above the general setup columns.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get exportGroupGeneral;

  /// Spreadsheet export: heading above the weather columns.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get exportGroupWeather;

  /// Spreadsheet export: label of the merged heading above the rider columns.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get exportGroupRider;

  /// Spreadsheet export: heading above the rider columns. {name} is the rider name.
  ///
  /// In en, this message translates to:
  /// **'Rider: {name}'**
  String exportGroupRiderName(String name);

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get exportColName;

  /// Spreadsheet export: column header for date and time.
  ///
  /// In en, this message translates to:
  /// **'DateTime'**
  String get exportColDateTime;

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get exportColTags;

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get exportColNotes;

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get exportColPlace;

  /// Spreadsheet export: column header. The unit is appended in brackets.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get exportColAltitude;

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get exportColBookmarked;

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get exportColBike;

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Weather Code'**
  String get exportColWeatherCode;

  /// Spreadsheet export: column header. The unit is appended in brackets.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get exportColTemperature;

  /// Spreadsheet export: column header. The unit is appended in brackets.
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get exportColPrecipitation;

  /// Spreadsheet export: column header. The unit is appended in brackets.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get exportColHumidity;

  /// Spreadsheet export: column header. The unit is appended in brackets.
  ///
  /// In en, this message translates to:
  /// **'Windspeed'**
  String get exportColWindspeed;

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Soil Moisture'**
  String get exportColSoilMoisture;

  /// Spreadsheet export: column header for the ground condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get exportColCondition;

  /// Spreadsheet export: column header for what a task entry is linked to.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get exportColLink;

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Task Rule'**
  String get exportColTaskRule;

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Task Rule Notes'**
  String get exportColTaskRuleNotes;

  /// Spreadsheet export: column header for what the task rule is linked to.
  ///
  /// In en, this message translates to:
  /// **'Task Rule Link'**
  String get exportColTaskRuleLink;

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get exportColPriority;

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get exportColInterval;

  /// Spreadsheet export: column header. The unit is appended in brackets.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get exportColDistance;

  /// Spreadsheet export: column header. The unit is appended in brackets.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get exportColElevation;

  /// Spreadsheet export: column header. The unit is appended in brackets.
  ///
  /// In en, this message translates to:
  /// **'Moving Time'**
  String get exportColMovingTime;

  /// Spreadsheet export: column header for the number of activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get exportColActivities;

  /// Spreadsheet export: column header.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get exportColSetup;

  /// Spreadsheet export: column header for the reference setup of a feedback.
  ///
  /// In en, this message translates to:
  /// **'Compared to'**
  String get exportColComparedTo;

  /// Spreadsheet export: column header for the overall outcome of a feedback.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get exportColOutcome;

  /// Spreadsheet export: column header for the flagged problems of a feedback.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get exportColIssues;

  /// Spreadsheet and text export: what a task is linked to. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'Component: {name}'**
  String exportLinkComponent(String name);

  /// Spreadsheet and text export: what a task is linked to. {name} is the bike name.
  ///
  /// In en, this message translates to:
  /// **'Bike: {name}'**
  String exportLinkBike(String name);

  /// Spreadsheet export: a task that is linked to neither a component nor a bike.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get exportLinkGeneral;

  /// Text export: section heading. Shown in capitals, followed by a colon.
  ///
  /// In en, this message translates to:
  /// **'Riders'**
  String get exportSectionRiders;

  /// Text export: section heading. Shown in capitals, followed by a colon.
  ///
  /// In en, this message translates to:
  /// **'Bikes'**
  String get exportSectionBikes;

  /// Text export: section heading. Shown in capitals, followed by a colon.
  ///
  /// In en, this message translates to:
  /// **'Setups'**
  String get exportSectionSetups;

  /// Name of the task log: sheet name and CSV title of the spreadsheet export, and the section heading of the text export (shown in capitals, followed by a colon).
  ///
  /// In en, this message translates to:
  /// **'Task Log'**
  String get exportSectionTaskLog;

  /// Name of the feedback list: sheet name and CSV title of the spreadsheet export, and the section heading of the text export (shown in capitals, followed by a colon).
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get exportSectionFeedback;

  /// Text export: marker after the name of a deleted item.
  ///
  /// In en, this message translates to:
  /// **'[DELETED]'**
  String get exportDeleted;

  /// Text export: heading above the rider attributes of a setup. {name} is the rider name.
  ///
  /// In en, this message translates to:
  /// **'{name} Attributes:'**
  String exportRiderAttributes(String name);

  /// Text export: humidity in the weather line of a setup. {value} is a whole number.
  ///
  /// In en, this message translates to:
  /// **'{value} % Humidity'**
  String exportWeatherHumidity(int value);

  /// Text export: wind speed in the weather line of a setup. {speed} is a whole number, {unit} the wind speed unit.
  ///
  /// In en, this message translates to:
  /// **'{speed} {unit} Wind'**
  String exportWeatherWind(int speed, String unit);

  /// Title of the confirmation before attachments are deleted. {count} is the number of attachments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete attachment?} other{Delete {count} attachments?}}'**
  String attachmentDeleteTitle(int count);

  /// Body of the confirmation before attachments are deleted.
  ///
  /// In en, this message translates to:
  /// **'The attachments are permanently deleted and removed from their setups, bikes, components and tasks. This action cannot be undone.'**
  String get attachmentDeleteBody;

  /// Snackbar after attachments were deleted. {count} is the number of attachments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Attachment deleted.} other{{count} attachments deleted.}}'**
  String attachmentDeletedSnack(int count);

  /// Snackbar when picking attachments failed. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Could not pick attachments: {error}'**
  String attachmentPickError(String error);

  /// Title of the dialog that renames an attachment.
  ///
  /// In en, this message translates to:
  /// **'Rename Attachment'**
  String get attachmentViewerRenameTitle;

  /// Shown in the attachment viewer when the image file is missing.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get attachmentViewerImageNotFound;

  /// Shown in the attachment viewer instead of the file size when the file is missing.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get attachmentViewerFileNotFound;

  /// Button and menu entry that saves an attachment to the device's files.
  ///
  /// In en, this message translates to:
  /// **'Save to Files'**
  String get attachmentViewerSaveToFiles;

  /// Menu entry that shares an attachment.
  ///
  /// In en, this message translates to:
  /// **'Share…'**
  String get attachmentViewerShareMenu;

  /// Snackbar after an attachment was saved to the device's files.
  ///
  /// In en, this message translates to:
  /// **'File saved'**
  String get attachmentViewerFileSaved;

  /// Snackbar when saving an attachment failed. {error} is the technical reason.
  ///
  /// In en, this message translates to:
  /// **'Could not save file: {error}'**
  String attachmentViewerSaveError(String error);

  /// Tooltip of the button that opens the setup an attachment belongs to.
  ///
  /// In en, this message translates to:
  /// **'Show Setup'**
  String get attachmentViewerShowSetup;

  /// Tooltip of the button that opens the bike an attachment belongs to.
  ///
  /// In en, this message translates to:
  /// **'Show Bike'**
  String get attachmentViewerShowBike;

  /// Tooltip of the button that opens the component an attachment belongs to.
  ///
  /// In en, this message translates to:
  /// **'Show Component'**
  String get attachmentViewerShowComponent;

  /// Tooltip of the button that opens the task an attachment belongs to.
  ///
  /// In en, this message translates to:
  /// **'Show Task'**
  String get attachmentViewerShowTask;

  /// Option that picks an image from the photo gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get attachmentSourceGallery;

  /// Option that takes a photo with the camera.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get attachmentSourcePhoto;

  /// Option that picks any file from the device.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get attachmentSourceFile;

  /// Screen reader label of the activity histogram. {summary} lists the bars.
  ///
  /// In en, this message translates to:
  /// **'Activity distribution. {summary}'**
  String chartActivityDistribution(String summary);

  /// Screen reader text of one histogram bar. {label} is the value range, {count} the number of activities, {current} and {recommended} are 'true' or 'false'.
  ///
  /// In en, this message translates to:
  /// **'{label}: {count, plural, =1{1 activity} other{{count} activities}}{current, select, true{ (current)} other{}}{recommended, select, true{ (recommended)} other{}}'**
  String chartHistogramBarSemantics(String label, int count, String current, String recommended);

  /// Tooltip of one histogram bar. {label} is the value range, {count} the number of activities, {current} and {recommended} are 'true' or 'false'.
  ///
  /// In en, this message translates to:
  /// **'{label}\n{count, plural, =1{1 activity} other{{count} activities}}{current, select, true{\nCurrent value} other{}}{recommended, select, true{\nRecommended value} other{}}'**
  String chartHistogramBarTooltip(String label, int count, String current, String recommended);

  /// Label of the vertical axis of the activity histogram.
  ///
  /// In en, this message translates to:
  /// **'Activity count'**
  String get chartHistogramCountAxis;

  /// Empty state of the activity histogram when no adjustment column is shown.
  ///
  /// In en, this message translates to:
  /// **'Select adjustment columns to visualize the activity distribution'**
  String get chartHistogramNoColumnsSubtitle;

  /// Empty state title of the activity histogram when no Strava activity exists.
  ///
  /// In en, this message translates to:
  /// **'No activities'**
  String get chartHistogramNoActivitiesTitle;

  /// Empty state subtitle of the activity histogram when no Strava activity exists.
  ///
  /// In en, this message translates to:
  /// **'Sync Strava activities to see which values you rode most'**
  String get chartHistogramNoActivitiesSubtitle;

  /// Error state title of the activity histogram.
  ///
  /// In en, this message translates to:
  /// **'Could not load activities'**
  String get chartHistogramLoadErrorTitle;

  /// Error state subtitle of the activity histogram.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while linking activities to setups'**
  String get chartHistogramLoadErrorSubtitle;

  /// Empty state title of the activity histogram when the chosen column has no linked activity.
  ///
  /// In en, this message translates to:
  /// **'No activities linked'**
  String get chartHistogramNoLinkedTitle;

  /// Empty state subtitle of the activity histogram. {column} is the name of the chosen column.
  ///
  /// In en, this message translates to:
  /// **'None of the setups with a \'{column}\' value were used on an activity'**
  String chartHistogramNoLinkedSubtitle(String column);

  /// Empty state title of a chart when no adjustment column is shown.
  ///
  /// In en, this message translates to:
  /// **'No adjustments selected'**
  String get chartNoAdjustmentsTitle;

  /// Empty state subtitle of the line and radial chart when no suitable column is shown.
  ///
  /// In en, this message translates to:
  /// **'Select numerical or step adjustment columns to visualize trends'**
  String get chartTrendNoColumnsSubtitle;

  /// Empty state title of a chart without setups.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get chartNoDataTitle;

  /// Empty state subtitle of a chart without setups.
  ///
  /// In en, this message translates to:
  /// **'No setup data available'**
  String get chartNoDataSubtitle;

  /// Empty state title of a chart when no setup row is selected.
  ///
  /// In en, this message translates to:
  /// **'No setups selected'**
  String get chartNoSetupsSelectedTitle;

  /// Empty state subtitle of a chart when no setup row is selected.
  ///
  /// In en, this message translates to:
  /// **'Select setups in the table above to visualize the chart'**
  String get chartNoSetupsSelectedSubtitle;

  /// Empty state title of a chart when the chosen columns hold no numbers.
  ///
  /// In en, this message translates to:
  /// **'No numerical data'**
  String get chartNoNumericalTitle;

  /// Empty state subtitle of a chart when the chosen columns hold no numbers.
  ///
  /// In en, this message translates to:
  /// **'The selected columns do not contain numerical data to plot'**
  String get chartNoNumericalSubtitle;

  /// Empty state title of the line chart with fewer than two setups.
  ///
  /// In en, this message translates to:
  /// **'Not enough setups'**
  String get chartLineNotEnoughTitle;

  /// Empty state subtitle of the line chart with fewer than two setups.
  ///
  /// In en, this message translates to:
  /// **'Select at least two setups in the table to visualize a trend'**
  String get chartLineNotEnoughSubtitle;

  /// Empty state title of the radial chart with fewer than three columns.
  ///
  /// In en, this message translates to:
  /// **'Not enough columns'**
  String get chartRadialNotEnoughTitle;

  /// Empty state subtitle of the radial chart with fewer than three columns.
  ///
  /// In en, this message translates to:
  /// **'At least 3 numerical columns are required to generate a radar chart'**
  String get chartRadialNotEnoughSubtitle;

  /// Label of the energy figure in the component stats card.
  ///
  /// In en, this message translates to:
  /// **'Kilojoules'**
  String get componentStatsKilojoules;

  /// Snackbar when a link could not be opened. {url} is the link.
  ///
  /// In en, this message translates to:
  /// **'Failed to open link: {url}'**
  String urlOpenFailed(String url);

  /// Snackbar when no app can open a link.
  ///
  /// In en, this message translates to:
  /// **'Could not find a program to launch the link.'**
  String get urlNoProgram;

  /// Snackbar when the email app could not be opened. {email} is the address.
  ///
  /// In en, this message translates to:
  /// **'Failed to open email client for: {email}'**
  String urlEmailFailed(String email);

  /// Snackbar when no email app is installed.
  ///
  /// In en, this message translates to:
  /// **'Could not find an email app on your device.'**
  String get urlNoEmailApp;

  /// Snackbar when no maps app is installed.
  ///
  /// In en, this message translates to:
  /// **'No maps app found. Please install Apple Maps, Google Maps, or another maps application.'**
  String get urlNoMapsApp;

  /// Snackbar when a picked file exceeds the size limit. {name} is the file name, {size} the limit in megabytes.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is larger than {size} MB and was not attached.'**
  String attachmentTooLarge(String name, int size);

  /// Snackbar when a picked file could not be attached. {name} is the file name.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" could not be attached.'**
  String attachmentImportFailed(String name);

  /// Link that expands a long note.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get notesShowMore;

  /// Shown by the metric weight field when the metric does not count.
  ///
  /// In en, this message translates to:
  /// **'Not included in the score'**
  String get metricWeightNotScored;

  /// Label of the metric weight field.
  ///
  /// In en, this message translates to:
  /// **'Scoring weight'**
  String get metricWeightTitle;

  /// Tooltip of the button that lowers the metric weight.
  ///
  /// In en, this message translates to:
  /// **'Decrease weight'**
  String get metricWeightDecrease;

  /// Tooltip of the button that raises the metric weight.
  ///
  /// In en, this message translates to:
  /// **'Increase weight'**
  String get metricWeightIncrease;

  /// Hint under the metric weight field while it is empty.
  ///
  /// In en, this message translates to:
  /// **'Set how this metric affects the score'**
  String get metricWeightHintUnset;

  /// Hint under the metric weight field for a positive weight.
  ///
  /// In en, this message translates to:
  /// **'Higher values improve the score'**
  String get metricWeightHintPositive;

  /// Hint under the metric weight field for a negative weight.
  ///
  /// In en, this message translates to:
  /// **'Lower values improve the score'**
  String get metricWeightHintNegative;

  /// Hint under the metric weight field for a weight of zero.
  ///
  /// In en, this message translates to:
  /// **'Not counted in the score'**
  String get metricWeightHintZero;

  /// Column heading of the soil moisture legend table. The unit stays as is.
  ///
  /// In en, this message translates to:
  /// **'Soil Moisture [m³/m³]'**
  String get soilMoistureLegendColumn;

  /// Screen reader label of a task priority badge. {priority} is the priority name.
  ///
  /// In en, this message translates to:
  /// **'{priority} priority'**
  String taskPrioritySemantics(String priority);

  /// Heading of the value migration preview with one example.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get valueTransitionExample;

  /// Heading of the value migration preview with several examples.
  ///
  /// In en, this message translates to:
  /// **'Examples'**
  String get valueTransitionExamples;

  /// Shown in the value migration preview for a value that is cleared.
  ///
  /// In en, this message translates to:
  /// **'No value'**
  String get valueTransitionCleared;

  /// Badge on the suggested setup in the setup picker.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get pickSetupSuggested;

  /// Title of the sheet that chooses how a dial adjuster is drawn.
  ///
  /// In en, this message translates to:
  /// **'Dial style'**
  String get dialStyleTitle;

  /// Hint under a progress message in a sheet.
  ///
  /// In en, this message translates to:
  /// **'This can take a moment for large datasets.'**
  String get sheetProgressHint;

  /// Suggestion above the custom unit field. {unit} is the suggested unit, {quantity} its quantity such as pressure.
  ///
  /// In en, this message translates to:
  /// **'Did you mean \"{unit}\" ({quantity})?'**
  String unitPickerDidYouMean(String unit, String quantity);

  /// Line in the weather card with the trail condition. {condition} is the condition name.
  ///
  /// In en, this message translates to:
  /// **'Condition: {condition}'**
  String contextCondition(String condition);

  /// Bike name in the setup day list when the bike no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Unknown bike'**
  String get setupDayUnknownBike;

  /// Default empty state title of the adjustment picker.
  ///
  /// In en, this message translates to:
  /// **'No adjustments yet'**
  String get pickAdjustmentsEmptyTitle;

  /// Name of the example bike in the subcomponents hint sheet.
  ///
  /// In en, this message translates to:
  /// **'Trail bike'**
  String get subcomponentsExampleBike;

  /// Screen reader label of a page dot in a hint deck. {label} names the deck, {index} is the page, {total} the number of pages.
  ///
  /// In en, this message translates to:
  /// **'{label} {index} of {total}'**
  String hintPageDot(String label, int index, int total);

  /// Tooltip of a button that collapses a card.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// Tooltip of a button that expands a card.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// Headline of the pressure check card when at least one pressure is off.
  ///
  /// In en, this message translates to:
  /// **'Worth getting the pump out'**
  String get pressureCheckWorthPump;

  /// Headline of the pressure check card when every pressure is fine.
  ///
  /// In en, this message translates to:
  /// **'No need to get the pump out'**
  String get pressureCheckNoPump;

  /// Current conditions in the pressure check card. {conditions} is the temperature and altitude.
  ///
  /// In en, this message translates to:
  /// **'Now {conditions}'**
  String pressureCheckNow(String conditions);

  /// Footer of the pressure check card when at least one pressure is off.
  ///
  /// In en, this message translates to:
  /// **'On the right is what your pump would read now. Pump back to the value you last set for the same feel.'**
  String get pressureCheckFooterDrifted;

  /// Footer of the pressure check card when every pressure is fine. {threshold} is the threshold, such as 3 %.
  ///
  /// In en, this message translates to:
  /// **'Every pressure stays within {threshold} of the value you last set.'**
  String pressureCheckFooterOk(String threshold);

  /// Tooltip of the info button on the pressure check card.
  ///
  /// In en, this message translates to:
  /// **'How this is calculated'**
  String get pressureCheckInfoTooltip;

  /// Row of the pressure check card: the value that was last set. {value} is the pressure, {unit} its unit, {date} the setup date, {conditions} the temperature and altitude then.
  ///
  /// In en, this message translates to:
  /// **'Set {value} {unit} on {date} · {conditions}'**
  String pressureCheckSetOn(String value, String unit, String date, String conditions);

  /// A pressure in psi in the pressure check explanation. {value} is the formatted number.
  ///
  /// In en, this message translates to:
  /// **'{value} psi'**
  String pressureCheckPsi(String value);

  /// Introduction of the pressure check info sheet.
  ///
  /// In en, this message translates to:
  /// **'A pressure you set at home doesn\'t read the same on the trail, even if no air escaped. This card shows what your pump would read right now.'**
  String get pressureCheckInfoIntro;

  /// Heading in the pressure check info sheet.
  ///
  /// In en, this message translates to:
  /// **'Why the reading changes'**
  String get pressureCheckInfoWhyHeading;

  /// Explanation of the temperature effect in the pressure check info sheet.
  ///
  /// In en, this message translates to:
  /// **'Colder air shrinks the air in the chamber: the reading drops.'**
  String get pressureCheckInfoCold;

  /// Explanation of the altitude effect in the pressure check info sheet.
  ///
  /// In en, this message translates to:
  /// **'Thinner air higher up pushes back less: the same chamber reads higher.'**
  String get pressureCheckInfoThin;

  /// Remark after the temperature and altitude effects in the pressure check info sheet.
  ///
  /// In en, this message translates to:
  /// **'The two often partly cancel each other out.'**
  String get pressureCheckInfoCancel;

  /// Heading of the example card in the pressure check info sheet.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get pressureCheckInfoExampleHeading;

  /// Heading in the pressure check info sheet.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get pressureCheckInfoWhatToDoHeading;

  /// Advice in the pressure check info sheet. {value} is the example pressure.
  ///
  /// In en, this message translates to:
  /// **'The feel follows what your pump reads. So the value you last set is still the right target: pump the fork back to {value} psi and it feels the same as at home.'**
  String pressureCheckInfoWhatToDo(String value);

  /// Heading of the status legend in the pressure check info sheet.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pressureCheckInfoStatusHeading;

  /// Legend entry for a pressure within the threshold. {threshold} is the threshold, such as 3 %.
  ///
  /// In en, this message translates to:
  /// **'Less than {threshold} off. Fine to ride as is.'**
  String pressureCheckInfoStatusOk(String threshold);

  /// Legend entry for a pressure beyond the threshold. {threshold} is the threshold, such as 3 %.
  ///
  /// In en, this message translates to:
  /// **'{threshold} or more off. Worth getting the pump out.'**
  String pressureCheckInfoStatusDrift(String threshold);

  /// Pointer to the pressure check settings. The menu names must match the app's own labels.
  ///
  /// In en, this message translates to:
  /// **'Change the threshold or skip component types in Settings › Features › Pressure Check.'**
  String get pressureCheckInfoSettingsHint;

  /// Heading in the pressure check info sheet.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get pressureCheckInfoGoodToKnowHeading;

  /// Note in the pressure check info sheet.
  ///
  /// In en, this message translates to:
  /// **'Each value is compared with the setup that last changed it, which is not always your previous setup.'**
  String get pressureCheckInfoCompared;

  /// Note in the pressure check info sheet.
  ///
  /// In en, this message translates to:
  /// **'Both setups need a temperature and an altitude; pressures without them are left out.'**
  String get pressureCheckInfoNeedsConditions;

  /// Note in the pressure check info sheet.
  ///
  /// In en, this message translates to:
  /// **'Not included: how the spring curve changes at a different pressure, oil viscosity, and the air the pump hose takes when you connect it.'**
  String get pressureCheckInfoNotIncluded;

  /// Example card of the pressure check info sheet: the first place.
  ///
  /// In en, this message translates to:
  /// **'At home'**
  String get pressureCheckExampleHome;

  /// Example card: the pressure that was set at home.
  ///
  /// In en, this message translates to:
  /// **'You set'**
  String get pressureCheckExampleYouSet;

  /// Example card: the second place.
  ///
  /// In en, this message translates to:
  /// **'At the trailhead'**
  String get pressureCheckExampleTrailhead;

  /// Example card: the pressure the pump would read at the trailhead.
  ///
  /// In en, this message translates to:
  /// **'Pump reads'**
  String get pressureCheckExamplePumpReads;

  /// Example card: the share of the drift that comes from the temperature.
  ///
  /// In en, this message translates to:
  /// **'Colder'**
  String get pressureCheckExampleColder;

  /// Example card: the share of the drift that comes from the altitude.
  ///
  /// In en, this message translates to:
  /// **'Higher up'**
  String get pressureCheckExampleHigherUp;

  /// Example card: the total drift. {value} is the signed pressure.
  ///
  /// In en, this message translates to:
  /// **'Total {value} psi'**
  String pressureCheckExampleTotal(String value);

  /// Summary of the component types the pressure check covers, when none is skipped.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get pressureCheckTypesAll;

  /// Summary of the component types the pressure check covers when many are skipped. {count} is the number covered, {total} the number of types.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total}'**
  String pressureCheckTypesCount(int count, int total);

  /// Summary of the component types the pressure check covers when a few are skipped. {types} is a comma separated list.
  ///
  /// In en, this message translates to:
  /// **'All except {types}'**
  String pressureCheckTypesAllExcept(String types);

  /// Introduction of the pressure check settings sheet.
  ///
  /// In en, this message translates to:
  /// **'When adding a setup, checks whether your pump would still read the pressures you last set. Colder or thinner air makes the same sealed chamber read differently.'**
  String get pressureCheckSettingIntro;

  /// Switch in the pressure check settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get pressureCheckEnabled;

  /// Section title in the pressure check settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get pressureCheckThresholdTitle;

  /// Explanation of the threshold in the pressure check settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Flag a pressure once the pump would read this much more or less than the value you last set.'**
  String get pressureCheckThresholdHint;

  /// Section title in the pressure check settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Component Types'**
  String get pressureCheckTypesTitle;

  /// Explanation of the component type list in the pressure check settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Skip types you check before every ride anyway, like tires.'**
  String get pressureCheckTypesHint;

  /// Title of the setup guide card, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Setup guide'**
  String get guideCardTitle;

  /// Tooltip of the info button on the setup guide card.
  ///
  /// In en, this message translates to:
  /// **'About recommended values'**
  String get guideCardInfoTooltip;

  /// Headline of the setup guide card.
  ///
  /// In en, this message translates to:
  /// **'Recommended first values'**
  String get guideCardHeadline;

  /// Footnote of the setup guide card.
  ///
  /// In en, this message translates to:
  /// **'A starting point, check your manual.'**
  String get guideCardStartingPoint;

  /// Button that applies every recommended value of the setup guide card.
  ///
  /// In en, this message translates to:
  /// **'Apply all'**
  String get guideCardApplyAll;

  /// Label of the riding weight field of the setup guide card.
  ///
  /// In en, this message translates to:
  /// **'Riding weight'**
  String get guideCardRidingWeight;

  /// Button that stores the typed riding weight with the rider, used when no rider name is known.
  ///
  /// In en, this message translates to:
  /// **'Add riding weight to rider'**
  String get guideCardAddWeightDefault;

  /// Line under a component name in the setup guide card. {guide} is the name of the guide.
  ///
  /// In en, this message translates to:
  /// **'Based on: {guide}'**
  String guideCardBasedOn(String guide);

  /// Current value of an adjustment in the setup guide card. {value} is the formatted value.
  ///
  /// In en, this message translates to:
  /// **'Now {value}'**
  String guideCardNow(String value);

  /// Part of the status line of a setup guide row. {band} is the range such as 72–80 psi.
  ///
  /// In en, this message translates to:
  /// **'in range {band}'**
  String guideCardInRange(String band);

  /// Hint of the setup guide card when no riding weight is known. The tab name must match the app's own label.
  ///
  /// In en, this message translates to:
  /// **'Enter a riding weight on the Rider tab for weight-based values'**
  String get guideCardEnterWeight;

  /// Line of the setup guide card with the riding weight in use. {weight} is the number, {unit} its unit.
  ///
  /// In en, this message translates to:
  /// **'Recommended values for {weight} {unit}'**
  String guideCardValuesFor(String weight, String unit);

  /// Part of the detail line of a setup guide row: the value was worked out between two weight steps.
  ///
  /// In en, this message translates to:
  /// **'interpolated'**
  String get guideDetailInterpolated;

  /// Part of the detail line of a setup guide row: the clicks were counted from the other end.
  ///
  /// In en, this message translates to:
  /// **'converted to your dial'**
  String get guideDetailConverted;

  /// Detail line of a setup guide row whose value does not depend on any input.
  ///
  /// In en, this message translates to:
  /// **'Fixed value'**
  String get guideDetailFixed;

  /// Reason a setup guide row has no value.
  ///
  /// In en, this message translates to:
  /// **'Needs your riding weight'**
  String get guideIssueNeedsWeight;

  /// Reason a setup guide row has no value.
  ///
  /// In en, this message translates to:
  /// **'Needs your riding style'**
  String get guideIssueNeedsStyle;

  /// Reason a setup guide row has no value. {name} is the name of the adjustment it depends on.
  ///
  /// In en, this message translates to:
  /// **'Needs a value for {name}'**
  String guideIssueNeedsAdjuster(String name);

  /// Reason a setup guide row has no value. {spec} is the name of a catalog property such as wheel size.
  ///
  /// In en, this message translates to:
  /// **'Needs the component\'s {spec}'**
  String guideIssueNeedsSpec(String spec);

  /// Reason a setup guide row has no value.
  ///
  /// In en, this message translates to:
  /// **'Needs more information'**
  String get guideIssueNeedsMore;

  /// Reason a setup guide row has no value.
  ///
  /// In en, this message translates to:
  /// **'Outside the published range'**
  String get guideIssueOutsideRange;

  /// Reason a setup guide row can't be applied.
  ///
  /// In en, this message translates to:
  /// **'Enter your dial\'s click count (max) first'**
  String get guideIssuePlaceholderMax;

  /// Reason a setup guide row can't be applied.
  ///
  /// In en, this message translates to:
  /// **'Above this adjuster\'s maximum'**
  String get guideIssueAboveMax;

  /// Reason a setup guide row can't be applied.
  ///
  /// In en, this message translates to:
  /// **'Below this adjuster\'s minimum'**
  String get guideIssueBelowMin;

  /// Reason a setup guide row can't be applied.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t fit this adjuster\'s type or unit'**
  String get guideIssueIncompatible;

  /// Reason a setup guide row can't be applied.
  ///
  /// In en, this message translates to:
  /// **'Counted on the catalog\'s dial; set this adjuster\'s dial direction to apply'**
  String get guideIssueDirectionUnknown;

  /// Upper end of a rider weight range, without unit. {value} is the weight.
  ///
  /// In en, this message translates to:
  /// **'up to {value}'**
  String guideWeightUpTo(String value);

  /// Tooltip line with the recommended value of an adjustment. {value} is the formatted value.
  ///
  /// In en, this message translates to:
  /// **'Recommended: {value}'**
  String guideRecommended(String value);

  /// Tooltip line with a recommended value that can't be applied. {value} is the formatted value or a dash, {reason} says why.
  ///
  /// In en, this message translates to:
  /// **'Recommended: {value} · {reason}'**
  String guideRecommendedWithIssue(String value, String reason);

  /// Status pill: the value is the recommended value.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get guideStatusMatches;

  /// Status pill: the value is close to the recommendation.
  ///
  /// In en, this message translates to:
  /// **'In range'**
  String get guideStatusInRange;

  /// Status pill: no value entered yet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get guideStatusNotSet;

  /// Status pill: the recommendation doesn't fit the adjuster.
  ///
  /// In en, this message translates to:
  /// **'Can\'t apply'**
  String get guideStatusCantApply;

  /// Status pill: the value is off and no distance can be shown.
  ///
  /// In en, this message translates to:
  /// **'Differs'**
  String get guideStatusDiffers;

  /// Detail under a status pill that is off. {band} is the range such as 72–80 psi.
  ///
  /// In en, this message translates to:
  /// **'In range: {band}'**
  String guideStatusInRangeDetail(String band);

  /// Title of the setup guide info sheet.
  ///
  /// In en, this message translates to:
  /// **'Recommended values'**
  String get guideInfoTitle;

  /// Introduction of the setup guide info sheet.
  ///
  /// In en, this message translates to:
  /// **'Each value comes from the manufacturer\'s setup guide for your exact model and riding weight. It is a starting point, check your manual.'**
  String get guideInfoIntro;

  /// Heading in the setup guide info sheet.
  ///
  /// In en, this message translates to:
  /// **'How values are found'**
  String get guideInfoHowHeading;

  /// Explanation in the setup guide info sheet.
  ///
  /// In en, this message translates to:
  /// **'Manuals list settings per weight step, for example 70–80 kg and 80–90 kg. If your weight falls between two steps, the value is worked out in between. Outside the weights a manual covers, there is no recommendation.'**
  String get guideInfoHowSteps;

  /// Explanation in the setup guide info sheet.
  ///
  /// In en, this message translates to:
  /// **'Clicks are counted from the end the manual counts from. If your adjuster counts the other way, the value is converted to your dial.'**
  String get guideInfoClicks;

  /// Heading of the status legend in the setup guide info sheet.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get guideInfoStatusHeading;

  /// Legend entry for the Matches status.
  ///
  /// In en, this message translates to:
  /// **'Your value is the recommended value.'**
  String get guideLegendMatches;

  /// Legend entry for the In range status.
  ///
  /// In en, this message translates to:
  /// **'Close to the recommendation: inside the range the manual gives, or less than halfway to the next weight step.'**
  String get guideLegendInRange;

  /// Legend entry for a status that shows a distance.
  ///
  /// In en, this message translates to:
  /// **'Further off. Shows how far your value is from the recommendation.'**
  String get guideLegendOff;

  /// Legend entry for the Not set status.
  ///
  /// In en, this message translates to:
  /// **'No value entered yet. Tap the row to use the recommendation.'**
  String get guideLegendNotSet;

  /// Legend entry for the Can't apply status.
  ///
  /// In en, this message translates to:
  /// **'The recommendation doesn\'t fit your adjuster, e.g. it is beyond its range. Edit the adjuster first.'**
  String get guideLegendUnavailable;

  /// Heading above the one guide behind the recommendations.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get guideInfoSource;

  /// Heading above the guides behind the recommendations.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get guideInfoSources;

  /// Subtitle of a guide in the info sheet. {components} is a comma separated list of component names.
  ///
  /// In en, this message translates to:
  /// **'For {components}'**
  String guideInfoFor(String components);

  /// Title of the component tree preview. {count} is the number of subcomponents.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 subcomponent} other{{count} subcomponents}}'**
  String subcomponentCount(int count);

  /// Title of the carry over sheet when some values can move.
  ///
  /// In en, this message translates to:
  /// **'Apply values to current components?'**
  String get carryOverTitleApply;

  /// Title of the carry over sheet when no value can move.
  ///
  /// In en, this message translates to:
  /// **'Values can\'t be applied'**
  String get carryOverTitleCant;

  /// Body of the carry over sheet when some values can move. {setup} is the setup name.
  ///
  /// In en, this message translates to:
  /// **'\'{setup}\' was recorded with components that are no longer on the bike. Their values can go to the components in the same position now.'**
  String carryOverBodyApply(String setup);

  /// Body of the carry over sheet when no value can move. {setup} is the setup name.
  ///
  /// In en, this message translates to:
  /// **'\'{setup}\' was recorded with components that are no longer on the bike, and their values don\'t fit the components in the same position now.'**
  String carryOverBodyCant(String setup);

  /// Section title in the carry over sheet, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Will be applied'**
  String get carryOverWillApply;

  /// Section title in the carry over sheet, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be applied'**
  String get carryOverCantApply;

  /// Subtitle of a value that moves. {source} is the replaced component, {target} the component it moves to.
  ///
  /// In en, this message translates to:
  /// **'From \'{source}\' to \'{target}\''**
  String carryOverFromTo(String source, String target);

  /// Reason a value can't move. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'\'{name}\' is no longer on the bike.'**
  String carryOverReasonGone(String name);

  /// Reason a value can't move. {name} is the component name.
  ///
  /// In en, this message translates to:
  /// **'\'{name}\' has no matching adjustment.'**
  String carryOverReasonNoMatch(String name);

  /// Reason a value can't move. {adjustment} is the adjustment name, {component} the component name.
  ///
  /// In en, this message translates to:
  /// **'Not allowed by \'{adjustment}\' on \'{component}\'.'**
  String carryOverReasonNotAllowed(String adjustment, String component);

  /// Note at the bottom of the carry over sheet.
  ///
  /// In en, this message translates to:
  /// **'Values that are not applied stay in the setup, but belong to components that are no longer on the bike.'**
  String get carryOverNote;

  /// Button that leaves the values where they are.
  ///
  /// In en, this message translates to:
  /// **'Don\'t apply'**
  String get carryOverDontApply;

  /// Button that moves the values. {count} is the number of values.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Apply 1 value} other{Apply {count} values}}'**
  String carryOverApplyCount(int count);

  /// Title of the value migration sheet.
  ///
  /// In en, this message translates to:
  /// **'Update recorded values'**
  String get valueMigrationTitle;

  /// Intro of the value migration sheet. {name} is the adjustment name, {records} the affected setups, {decide} and {replaces} are 'true' or 'false'.
  ///
  /// In en, this message translates to:
  /// **'Your change to \'{name}\' affects {records}.{decide, select, true{ Choose what happens to their values.} other{}}{replaces, select, true{ This replaces the change you confirmed earlier.} other{}}'**
  String valueMigrationIntro(String name, String records, String decide, String replaces);

  /// Hint under the choices of the value migration sheet.
  ///
  /// In en, this message translates to:
  /// **'Need different values in different setups? Cancel, change those setups first, then make this edit.'**
  String get valueMigrationNeedDifferent;

  /// Confirm button of the value migration sheet. {count} is the number of setups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Update 1 setup} other{Update {count} setups}}'**
  String valueMigrationUpdate(int count);

  /// Confirm button of the value migration sheet when only deleted setups are affected. {count} is their number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Update 1 deleted setup} other{Update {count} deleted setups}}'**
  String valueMigrationUpdateDeleted(int count);

  /// Number of affected setups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 setup} other{{count} setups}}'**
  String affectedSetups(int count);

  /// Number of affected setups that are all deleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 deleted setup} other{{count} deleted setups}}'**
  String affectedDeletedSetups(int count);

  /// Number of affected setups, with the number of deleted ones in addition.
  ///
  /// In en, this message translates to:
  /// **'{live, plural, =1{1 setup} other{{live} setups}} (+{deleted} deleted)'**
  String affectedSetupsWithDeleted(int live, int deleted);

  /// Name of the missing unit in the value migration sheet.
  ///
  /// In en, this message translates to:
  /// **'no unit'**
  String get valueMigrationNoUnit;

  /// Title of a unit change in the value migration sheet. {before} and {after} are unit names.
  ///
  /// In en, this message translates to:
  /// **'Unit changed from {before} to {after}'**
  String valueMigrationUnitChanged(String before, String after);

  /// Title of renamed options in the value migration sheet.
  ///
  /// In en, this message translates to:
  /// **'Renamed options'**
  String get valueMigrationRenamedOptions;

  /// Title of a deleted option in the value migration sheet.
  ///
  /// In en, this message translates to:
  /// **'\'{option}\' was deleted'**
  String valueMigrationDeletedOption(String option);

  /// Title when options became unique in the value migration sheet.
  ///
  /// In en, this message translates to:
  /// **'Each option can be picked only once now'**
  String get valueMigrationDuplicateOptions;

  /// Title when a combination of options is no longer allowed. {combination} lists the options.
  ///
  /// In en, this message translates to:
  /// **'Only one option can be picked now: {combination}'**
  String valueMigrationCombination(String combination);

  /// Title when values do not fit a step adjustment any more.
  ///
  /// In en, this message translates to:
  /// **'Values off the new steps or range'**
  String get valueMigrationOutOfStep;

  /// Title when values do not fit a numerical adjustment any more.
  ///
  /// In en, this message translates to:
  /// **'Values outside the new range'**
  String get valueMigrationOutOfRange;

  /// Label of the dropdown that picks the replacement of a deleted option.
  ///
  /// In en, this message translates to:
  /// **'Replace \'{option}\' with'**
  String valueMigrationReplaceDeleted(String option);

  /// Label of the dropdown that picks the replacement of an option combination.
  ///
  /// In en, this message translates to:
  /// **'Replace {combination} with'**
  String valueMigrationReplaceCombination(String combination);

  /// Dropdown entry that removes a deleted option from a multi-selection.
  ///
  /// In en, this message translates to:
  /// **'Remove \'{option}\' from the selection'**
  String valueMigrationRemoveFromSelection(String option);

  /// Choice that converts values to the new unit.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get valueMigrationConvert;

  /// Choice that keeps the numbers and only changes the unit.
  ///
  /// In en, this message translates to:
  /// **'Keep numbers'**
  String get valueMigrationKeepNumbers;

  /// Choice that moves values to the nearest step.
  ///
  /// In en, this message translates to:
  /// **'Snap'**
  String get valueMigrationSnap;

  /// Choice that moves values to the nearest limit.
  ///
  /// In en, this message translates to:
  /// **'Clamp'**
  String get valueMigrationClamp;

  /// Choice that clears the values.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get valueMigrationClear;

  /// Hint under the Convert choice. {records} names the affected setups, {one} is 'true' for a single setup, {unit} the new unit.
  ///
  /// In en, this message translates to:
  /// **'{records} {one, select, true{is} other{are}} converted to {unit}.'**
  String valueMigrationHintConvert(String records, String one, String unit);

  /// Hint under the Keep numbers choice when the new unit is empty. {records} names the affected setups, {one} is 'true' for a single setup.
  ///
  /// In en, this message translates to:
  /// **'{records} {one, select, true{keeps its} other{keep their}} numbers, now without a unit.'**
  String valueMigrationHintKeepNoUnit(String records, String one);

  /// Hint under the Keep numbers choice. {records} names the affected setups, {one} is 'true' for a single setup, {unit} the new unit.
  ///
  /// In en, this message translates to:
  /// **'{records} {one, select, true{keeps its} other{keep their}} numbers, now read in {unit}.'**
  String valueMigrationHintKeepUnit(String records, String one, String unit);

  /// Hint under the Snap choice. {records} names the affected setups, {one} is 'true' for a single setup.
  ///
  /// In en, this message translates to:
  /// **'{records} {one, select, true{snaps} other{snap}} to the nearest step.'**
  String valueMigrationHintSnap(String records, String one);

  /// Hint under the Clamp choice. {records} names the affected setups, {one} is 'true' for a single setup.
  ///
  /// In en, this message translates to:
  /// **'{records} {one, select, true{moves} other{move}} to the nearest limit.'**
  String valueMigrationHintClamp(String records, String one);

  /// Hint when a deleted option's text is taken by a renamed option. {records} names the affected setups, {one} is 'true' for a single setup.
  ///
  /// In en, this message translates to:
  /// **'{records} {one, select, true{keeps} other{keep}} \'{option}\', now the option renamed from \'{origin}\'.'**
  String valueMigrationHintKeepRenamed(String records, String one, String option, String origin);

  /// Hint when a deleted option is removed from a multi-selection. {records} names the affected setups.
  ///
  /// In en, this message translates to:
  /// **'\'{option}\' is removed from {records}.'**
  String valueMigrationHintRemoveOption(String option, String records);

  /// Hint under the Clear choice. {records} names the affected setups, {one} is 'true' for a single setup.
  ///
  /// In en, this message translates to:
  /// **'{records} {one, select, true{loses its} other{lose their}} value.'**
  String valueMigrationHintClear(String records, String one);

  /// Hint when a deleted option is replaced. {records} names the affected setups.
  ///
  /// In en, this message translates to:
  /// **'\'{option}\' becomes \'{replacement}\' in {records}.'**
  String valueMigrationHintBecomes(String option, String replacement, String records);

  /// Hint when an option is replaced. {records} names the affected setups, {one} is 'true' for a single setup.
  ///
  /// In en, this message translates to:
  /// **'{records} {one, select, true{changes} other{change}} to \'{replacement}\'.'**
  String valueMigrationHintChanges(String records, String one, String replacement);

  /// Line under an adjustment with a confirmed value migration. {records} names the affected setups.
  ///
  /// In en, this message translates to:
  /// **'Updates {records} on save'**
  String valueMigrationPendingUpdates(String records);

  /// Line under an adjustment whose confirmed migration clears values. {records} names the affected setups, {one} is 'true' for a single setup.
  ///
  /// In en, this message translates to:
  /// **'{records} {one, select, true{loses its} other{lose their}} value'**
  String valueMigrationPendingClears(String records, String one);

  /// Badge on a result card of the preset merge sheet: the adjustment was merged with a preset adjustment.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get presetMergeStatusMerged;

  /// Badge on a result card of the preset merge sheet: the adjustment stays as it is.
  ///
  /// In en, this message translates to:
  /// **'Unchanged'**
  String get presetMergeStatusUnchanged;

  /// Badge on a result card of the preset merge sheet: the preset adjustment is added.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get presetMergeStatusNew;

  /// Badge and heading in the preset merge sheet for preset adjustments that are left out.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get presetMergeStatusNotAdded;

  /// Title of the preset merge sheet.
  ///
  /// In en, this message translates to:
  /// **'Merge adjustments'**
  String get presetMergeTitle;

  /// Introduction of the preset merge sheet. {product} is the catalog product name.
  ///
  /// In en, this message translates to:
  /// **'Your component already has adjustments. Choose how the ones of {product} combine with them.'**
  String presetMergeIntro(String product);

  /// Mode and button that merge the preset adjustments into the existing ones.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get presetMergeModeMerge;

  /// Explanation of the merge mode in the preset merge sheet.
  ///
  /// In en, this message translates to:
  /// **'Merged adjustments keep their name and recorded values and get linked to the preset. Tap a badge to change it.'**
  String get presetMergeMergedHint;

  /// Heading above the result cards of the preset merge sheet. {summary} counts the outcomes.
  ///
  /// In en, this message translates to:
  /// **'Result · {summary}'**
  String presetMergeResult(String summary);

  /// Summary in replace mode. {preset} is the number of preset adjustments, {removed} the number of existing ones that are removed.
  ///
  /// In en, this message translates to:
  /// **'{preset} from the preset · {removed} of yours removed'**
  String presetMergeSummaryReplace(int preset, int removed);

  /// Part of the merge summary.
  ///
  /// In en, this message translates to:
  /// **'{count} merged'**
  String presetMergeSummaryMerged(int count);

  /// Part of the merge summary.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String presetMergeSummaryNew(int count);

  /// Part of the merge summary.
  ///
  /// In en, this message translates to:
  /// **'{count} unchanged'**
  String presetMergeSummaryUnchanged(int count);

  /// Notice in replace mode when no recorded values are at stake.
  ///
  /// In en, this message translates to:
  /// **'Your adjustments are removed and the preset\'s are used instead. None of yours has recorded values yet, so nothing is lost.'**
  String get presetReplaceNoValues;

  /// Warning in replace mode when recorded values are at stake. {withValues} is the number of adjustments with values, {valueCount} the number of values.
  ///
  /// In en, this message translates to:
  /// **'{withValues, plural, =1{1 of your adjustments has} other{{withValues} of your adjustments have}} {valueCount, plural, =1{1 recorded value} other{{valueCount} recorded values}}. Replacing removes them from this component: the values stay in your setups, but no longer belong to an adjustment. Merge keeps them.'**
  String presetReplaceWarning(int withValues, int valueCount);

  /// Line on a merged result card. {own} is the existing adjustment, {catalog} the preset adjustment.
  ///
  /// In en, this message translates to:
  /// **'{own} + {catalog} (preset)'**
  String presetMergeLine(String own, String catalog);

  /// Line on a merged result card whose range was not replaced.
  ///
  /// In en, this message translates to:
  /// **'Keeps your range: recorded values lie outside the preset\'s'**
  String get presetMergeKeptRange;

  /// Menu entry that merges a preset adjustment into an existing one. {name} is the existing adjustment.
  ///
  /// In en, this message translates to:
  /// **'Merge into \"{name}\"'**
  String presetMergeChoiceMergeInto(String name);

  /// Menu entry that merges an existing adjustment with a preset one. {name} is the preset adjustment.
  ///
  /// In en, this message translates to:
  /// **'Merge with \"{name}\" (preset)'**
  String presetMergeChoiceMergeWith(String name);

  /// Menu entry that leaves a preset adjustment out.
  ///
  /// In en, this message translates to:
  /// **'Don\'t add'**
  String get presetMergeChoiceDontAdd;

  /// Menu entry that adds a left out preset adjustment as a new one.
  ///
  /// In en, this message translates to:
  /// **'Add as new'**
  String get presetMergeChoiceAddNew;

  /// Menu entry that undoes a merge and keeps both adjustments.
  ///
  /// In en, this message translates to:
  /// **'Separate again'**
  String get presetMergeChoiceSeparate;

  /// Menu entry that undoes a merge and drops the preset adjustment.
  ///
  /// In en, this message translates to:
  /// **'Separate, drop preset\'s'**
  String get presetMergeChoiceSeparateDrop;

  /// Title of the catalog picker at the brand level, and the call to action of the catalog card.
  ///
  /// In en, this message translates to:
  /// **'Choose from catalog'**
  String get catalogPickerTitle;

  /// Title of the catalog picker for a level. {thing} is the lowercase level name from the catalog, such as trim.
  ///
  /// In en, this message translates to:
  /// **'Select {thing}'**
  String catalogPickerSelect(String thing);

  /// Title of the catalog picker when the level has no name.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get catalogPickerSelectGeneric;

  /// Title of the catalog picker for the optional axes.
  ///
  /// In en, this message translates to:
  /// **'Optional details'**
  String get catalogPickerOptionalDetails;

  /// Hint of the catalog search field. {type} is the component type, lowercase in English.
  ///
  /// In en, this message translates to:
  /// **'Search {type}s…'**
  String catalogPickerSearchHint(String type);

  /// Empty state of the catalog picker.
  ///
  /// In en, this message translates to:
  /// **'No catalog entries available.'**
  String get catalogPickerNoEntries;

  /// Line under a catalog option for adjustments the catalog lacks. {adjustments} is a comma separated list.
  ///
  /// In en, this message translates to:
  /// **'Add by hand: {adjustments}'**
  String catalogPickerAddByHand(String adjustments);

  /// Button of the optional details step when something is chosen.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get catalogPickerApply;

  /// Button of the optional details step when nothing is chosen.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get catalogPickerSkip;

  /// Group title of the model year chips.
  ///
  /// In en, this message translates to:
  /// **'Model year'**
  String get catalogPickerModelYear;

  /// Empty search result in the catalog picker. {query} is the search text.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\".'**
  String catalogPickerNoMatches(String query);

  /// Hint under an empty search result in the catalog picker.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or search for the model name only.'**
  String get catalogPickerNoMatchesHint;

  /// Button that leaves the catalog picker without a choice.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get catalogPickerEnterManually;

  /// Button text after a product was requested.
  ///
  /// In en, this message translates to:
  /// **'Requested, thanks'**
  String get catalogPickerRequested;

  /// Button that asks for a product to be added to the catalog.
  ///
  /// In en, this message translates to:
  /// **'Request this product'**
  String get catalogPickerRequest;

  /// Error state of the catalog picker.
  ///
  /// In en, this message translates to:
  /// **'Could not load the catalog.'**
  String get catalogPickerLoadError;

  /// Title of the catalog card when the linked entry no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Catalog entry not found'**
  String get catalogCardNotFound;

  /// Subtitle of the catalog card when the linked entry no longer exists.
  ///
  /// In en, this message translates to:
  /// **'No longer in the catalog · Tap to choose another'**
  String get catalogCardNotFoundHint;

  /// Last part of the subtitle of a linked catalog card.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get catalogCardTapToChange;

  /// Teaser of the catalog card. {type} is the component type, lowercase in English.
  ///
  /// In en, this message translates to:
  /// **'Prefill from a {type} model'**
  String catalogCardPrefill(String type);

  /// Second line of the catalog card teaser.
  ///
  /// In en, this message translates to:
  /// **'Link to a catalog product to get recommended values'**
  String get catalogCardGuideHint;

  /// Tooltip of the button that unlinks a component from its catalog entry.
  ///
  /// In en, this message translates to:
  /// **'Unlink preset (keeps values)'**
  String get catalogCardUnlinkTooltip;

  /// Heading of the catalog update notice.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get catalogCardUpdateAvailable;

  /// Button that dismisses a catalog update.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get catalogCardDismiss;

  /// Button that reviews a catalog update.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get catalogCardReview;

  /// Introduction of the subcomponents sheet.
  ///
  /// In en, this message translates to:
  /// **'Install components on other components, e.g. a tire and a brake disc on a wheel. In the Garage, they are grouped with their parent.'**
  String get subcomponentsSheetIntro;

  /// Label above the first example bike of the subcomponents sheet.
  ///
  /// In en, this message translates to:
  /// **'Without subcomponents'**
  String get subcomponentsSheetWithout;

  /// Label above the second example bike of the subcomponents sheet.
  ///
  /// In en, this message translates to:
  /// **'With subcomponents'**
  String get subcomponentsSheetWith;

  /// Caption under the example bikes of the subcomponents sheet.
  ///
  /// In en, this message translates to:
  /// **'Move a wheel and its tire and brake disc come along. They are credited with the same rides.'**
  String get subcomponentsSheetCaption;

  /// Weather fetch failed because the device is offline.
  ///
  /// In en, this message translates to:
  /// **'Network Error (No Internet).'**
  String get weatherErrorNoInternet;

  /// Weather fetch failed because the request timed out.
  ///
  /// In en, this message translates to:
  /// **'Network Error (Timeout).'**
  String get weatherErrorTimeout;

  /// Weather fetch refused because of too many requests. {limit} is the number of requests per hour, {time} the time of day the limit lifts.
  ///
  /// In en, this message translates to:
  /// **'Rate limit exceeded ({limit}/h). Try again after {time}'**
  String weatherErrorRateLimit(int limit, String time);

  /// Weather fetch failed for another reason.
  ///
  /// In en, this message translates to:
  /// **'Error occurred during weather update.'**
  String get weatherErrorFailed;

  /// Why a test session strategy has nothing to propose yet.
  ///
  /// In en, this message translates to:
  /// **'Record a run first.'**
  String get suggestionRecordRunFirst;

  /// Why a test session strategy has nothing to propose yet. {run} is the name of the latest run.
  ///
  /// In en, this message translates to:
  /// **'Add feedback on {run} first.'**
  String suggestionAddFeedbackFirst(String run);

  /// Problem with the data of a test session.
  ///
  /// In en, this message translates to:
  /// **'An adjustment of this session is no longer on the bike. Lock it to go on.'**
  String get suggestionAdjustmentGone;

  /// Problem with the data of a test session. {run} is the run name, {adjustment} the adjustment name.
  ///
  /// In en, this message translates to:
  /// **'{run} has no value for \'{adjustment}\'.'**
  String suggestionNoValue(String run, String adjustment);

  /// Problem with the data of a test session. {adjustment} is the adjustment name, {run} the run name.
  ///
  /// In en, this message translates to:
  /// **'\'{adjustment}\' in {run} is outside its range.'**
  String suggestionOutOfRange(String adjustment, String run);

  /// Why a test session strategy has nothing to propose.
  ///
  /// In en, this message translates to:
  /// **'Every adjustment is locked.'**
  String get suggestionAllLocked;

  /// Problem with the data of a test session.
  ///
  /// In en, this message translates to:
  /// **'This session does not compare setups.'**
  String get suggestionNotCompare;

  /// Problem with the data of a Compare test session.
  ///
  /// In en, this message translates to:
  /// **'A setup to compare was removed. End the session or compare the rest in a new one.'**
  String get suggestionSetupRemoved;

  /// Rationale of an Explore run. {number} and {total} count the pattern runs, {move} lists the changes like 'Rebound +2, Lockout On', {base} is the run it starts from.
  ///
  /// In en, this message translates to:
  /// **'Pattern {number} of {total}: {move} from {base}. Every adjustment moves, so their effects can be told apart.'**
  String suggestionPatternStep(String number, String total, String move, String base);

  /// Rationale of an Explore run. {move} lists the changes, {base} is the run it starts from.
  ///
  /// In en, this message translates to:
  /// **'Ride the estimated best: {move} from {base}.'**
  String suggestionEstimatedBest(String move, String base);

  /// Rationale of a confirmation run. {run} is the run to ride again.
  ///
  /// In en, this message translates to:
  /// **'Ride {run} again to confirm the result.'**
  String suggestionRideAgainConfirm(String run);

  /// Rationale of a Fine-tune run. {best} is the best run, {move} lists the next changes.
  ///
  /// In en, this message translates to:
  /// **'{best} was better. Keep going: {move}.'**
  String suggestionKeepGoing(String best, String move);

  /// Rationale of a Fine-tune run. {move} lists the changes, {best} is the best run.
  ///
  /// In en, this message translates to:
  /// **'Try {move} from {best}, the best run so far.'**
  String suggestionTryFromBest(String move, String best);

  /// Rationale of a Fine-tune confirmation run. {best} is the best run.
  ///
  /// In en, this message translates to:
  /// **'Ride {best} again to check that nothing else changed.'**
  String suggestionRideAgainCheck(String best);

  /// Rationale of a Compare run. {next} is the setup to ride, {last} the latest run.
  ///
  /// In en, this message translates to:
  /// **'Ride {next} and compare it with {last}.'**
  String suggestionRideAndCompare(String next, String last);

  /// Rationale of a Compare run. {next} and {other} are the two setups that tie.
  ///
  /// In en, this message translates to:
  /// **'{next} and {other} are level. Ride {next} again to decide.'**
  String suggestionLevelRideAgain(String next, String other);

  /// Section title of the dial colors in the dial style sheet.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get dialStyleColor;

  /// Section title of the dial sizes in the dial style sheet.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get dialStyleSize;

  /// Screen reader label of the blue dial color.
  ///
  /// In en, this message translates to:
  /// **'blue'**
  String get dialColorBlue;

  /// Screen reader label of the red dial color.
  ///
  /// In en, this message translates to:
  /// **'red'**
  String get dialColorRed;

  /// Screen reader label of the green dial color.
  ///
  /// In en, this message translates to:
  /// **'green'**
  String get dialColorGreen;

  /// Screen reader label of the brown dial color.
  ///
  /// In en, this message translates to:
  /// **'brown'**
  String get dialColorBrown;

  /// Screen reader label of the orange dial color.
  ///
  /// In en, this message translates to:
  /// **'orange'**
  String get dialColorOrange;

  /// Screen reader label of the purple dial color.
  ///
  /// In en, this message translates to:
  /// **'purple'**
  String get dialColorPurple;

  /// Screen reader label of the grey dial color.
  ///
  /// In en, this message translates to:
  /// **'grey'**
  String get dialColorGrey;

  /// Screen reader label of the normal dial size.
  ///
  /// In en, this message translates to:
  /// **'normal'**
  String get dialSizeNormal;

  /// Screen reader label of the small dial size.
  ///
  /// In en, this message translates to:
  /// **'small'**
  String get dialSizeSmall;

  /// Name of the catalog property travel, in the sentence form (lowercase in English). It is capitalised where it stands alone, and it starts the note line Travel: 150 mm of a component created from the catalog.
  ///
  /// In en, this message translates to:
  /// **'travel'**
  String get catalogTermTravel;

  /// Name of the catalog property wheel size, in the sentence form.
  ///
  /// In en, this message translates to:
  /// **'wheel size'**
  String get catalogTermWheelSize;

  /// Name of the catalog property stanchion (the fork leg diameter), in the sentence form.
  ///
  /// In en, this message translates to:
  /// **'stanchion'**
  String get catalogTermStanchion;

  /// Name of the catalog property spring (air or coil), in the sentence form.
  ///
  /// In en, this message translates to:
  /// **'spring'**
  String get catalogTermSpring;

  /// Name of the catalog property eye-to-eye, the mounting length of a shock, in the sentence form.
  ///
  /// In en, this message translates to:
  /// **'eye-to-eye'**
  String get catalogTermEyeToEye;

  /// Name of the catalog property stroke of a shock, in the sentence form.
  ///
  /// In en, this message translates to:
  /// **'stroke'**
  String get catalogTermStroke;

  /// Name of the catalog property mount of a shock, and of the catalog level that offers mount variants, in the sentence form.
  ///
  /// In en, this message translates to:
  /// **'mount'**
  String get catalogTermMount;

  /// Name of the catalog choice damper (the cartridge of a fork or shock), in the sentence form.
  ///
  /// In en, this message translates to:
  /// **'damper'**
  String get catalogTermDamper;

  /// Name of the catalog choice size of a shock, in the sentence form.
  ///
  /// In en, this message translates to:
  /// **'size'**
  String get catalogTermSize;

  /// Name of the catalog level generation, in the sentence form. It completes the picker title Select generation.
  ///
  /// In en, this message translates to:
  /// **'generation'**
  String get catalogTermGeneration;

  /// Name of the catalog level model, in the sentence form. It completes the picker title Select model.
  ///
  /// In en, this message translates to:
  /// **'model'**
  String get catalogTermModel;

  /// Name of the catalog level trim (the equipment variant of a model), in the sentence form. It completes the picker title Select trim.
  ///
  /// In en, this message translates to:
  /// **'trim'**
  String get catalogTermTrim;

  /// Name of the catalog level version, in the sentence form. It completes the picker title Select version.
  ///
  /// In en, this message translates to:
  /// **'version'**
  String get catalogTermVersion;

  /// Heading of the catalog models that have no category, and of the shock sizes that have no eye-to-eye length.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catalogPickerCategoryOther;

  /// Line of the note of a component created from the catalog. It is stored with the note. {year} is a year.
  ///
  /// In en, this message translates to:
  /// **'Model year: {year}'**
  String catalogNoteModelYear(String year);

  /// Line of the note of a component created from the catalog when the model year is open. It is stored with the note. {years} is a span like 2025-2026.
  ///
  /// In en, this message translates to:
  /// **'Model years: {years}'**
  String catalogNoteModelYears(String years);

  /// Line of the note of a component created from the catalog that lists adjustments the catalog does not have. It is stored with the note. {adjustments} is a comma-separated list of names.
  ///
  /// In en, this message translates to:
  /// **'Not in the catalog yet, add by hand: {adjustments}'**
  String catalogNoteMissing(String adjustments);

  /// Last paragraph of the note of a component created from the catalog. It is stored with the note. {guide} is a link.
  ///
  /// In en, this message translates to:
  /// **'Setup guide: {guide}'**
  String catalogNoteSetupGuide(String guide);

  /// Note of a step adjustment created from the catalog whose maximum the manufacturer does not publish. It is stored with the note.
  ///
  /// In en, this message translates to:
  /// **'Click count not published. Max is a placeholder, edit it to match your component.'**
  String get stepUnknownMaxWarning;

  /// Summary of a shock that comes in several sizes, where listing them all would not fit a row. {count} is the number of sizes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 size} other{{count} sizes}}'**
  String catalogSizesCount(int count);

  /// Name of the recommended task wheel:spoke_tension. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Spoke tension check'**
  String get taskTemplateWheelSpokeTensionName;

  /// Note of the recommended task wheel:spoke_tension. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Squeeze spoke pairs and check the rim for wobble; new wheels settle during the first rides.'**
  String get taskTemplateWheelSpokeTensionNotes;

  /// Name of the recommended task wheel:hub_bearing. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Hub bearing check'**
  String get taskTemplateWheelHubBearingName;

  /// Note of the recommended task wheel:hub_bearing. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Check the hub for play and rough or notchy rotation.'**
  String get taskTemplateWheelHubBearingNotes;

  /// Name of the recommended task chain:wear_check. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Check chain wear'**
  String get taskTemplateChainWearCheckName;

  /// Note of the recommended task chain:wear_check. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Measure chain stretch with a wear gauge and replace the chain once it reaches the wear limit.'**
  String get taskTemplateChainWearCheckNotes;

  /// Name of the recommended task chain:replace. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Replace chain'**
  String get taskTemplateChainReplaceName;

  /// Name of the recommended task chain:lube. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Clean & lube chain'**
  String get taskTemplateChainLubeName;

  /// Name of the recommended task cassette:wear_check. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Check cassette wear'**
  String get taskTemplateCassetteWearCheckName;

  /// Note of the recommended task cassette:wear_check. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Look for hooked or shark-fin teeth and chain skipping under load.'**
  String get taskTemplateCassetteWearCheckNotes;

  /// Name of the recommended task fork:lower_leg_service. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Lower leg service'**
  String get taskTemplateForkLowerLegServiceName;

  /// Note of the recommended task fork:lower_leg_service. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Clean the stanchions and seals, replace the foam rings and refresh the bath oil.'**
  String get taskTemplateForkLowerLegServiceNotes;

  /// Name of the recommended task fork:full_service. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Full service'**
  String get taskTemplateForkFullServiceName;

  /// Note of the recommended task fork:full_service. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Lower leg service plus a damper and air spring rebuild, including seals and oil.'**
  String get taskTemplateForkFullServiceNotes;

  /// Name of the recommended task shock:air_can_service. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Air can service'**
  String get taskTemplateShockAirCanServiceName;

  /// Note of the recommended task shock:air_can_service. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Clean and re-grease the air can and replace its seals.'**
  String get taskTemplateShockAirCanServiceNotes;

  /// Name of the recommended task shock:full_service. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Full service'**
  String get taskTemplateShockFullServiceName;

  /// Note of the recommended task shock:full_service. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Damper rebuild including seals, oil and nitrogen charge, plus the air can service on air shocks.'**
  String get taskTemplateShockFullServiceNotes;

  /// Name of the recommended task brake_pad:wear_check. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Check pad wear'**
  String get taskTemplateBrakePadWearCheckName;

  /// Note of the recommended task brake_pad:wear_check. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Replace the pads before the friction material is worn down to the backing plate.'**
  String get taskTemplateBrakePadWearCheckNotes;

  /// Name of the recommended task brake:bleed. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Bleed brakes'**
  String get taskTemplateBrakeBleedName;

  /// Note of the recommended task brake:bleed. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Replace the brake fluid and remove air from the system.'**
  String get taskTemplateBrakeBleedNotes;

  /// Name of the recommended task tire:sealant. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Refresh tubeless sealant'**
  String get taskTemplateTireSealantName;

  /// Note of the recommended task tire:sealant. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Top up or replace the sealant before it dries out.'**
  String get taskTemplateTireSealantNotes;

  /// Name of the recommended task headset:service. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Clean & grease headset'**
  String get taskTemplateHeadsetServiceName;

  /// Name of the recommended task bb:play_check. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Check bottom bracket play'**
  String get taskTemplateBbPlayCheckName;

  /// Note of the recommended task bb:play_check. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Check the cranks for side play and the bearings for rough rotation.'**
  String get taskTemplateBbPlayCheckNotes;

  /// Name of the recommended task seatpost:service. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Dropper post service'**
  String get taskTemplateSeatpostServiceName;

  /// Name of the recommended task frame:pivot_bearings. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Check pivot bearings'**
  String get taskTemplateFramePivotBearingsName;

  /// Note of the recommended task frame:pivot_bearings. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Check the suspension linkage for play and rough bearings.'**
  String get taskTemplateFramePivotBearingsNotes;

  /// Name of the recommended task frame:bolt_torque. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Check bolt torque'**
  String get taskTemplateFrameBoltTorqueName;

  /// Note of the recommended task frame:bolt_torque. It is stored with the task rule as written.
  ///
  /// In en, this message translates to:
  /// **'Check all bolts against the torque values printed on the parts or in the manual.'**
  String get taskTemplateFrameBoltTorqueNotes;

  /// Name of the recommended task shift_cable:replace. It becomes the name of the task rule, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Replace shift cable'**
  String get taskTemplateShiftCableReplaceName;

  /// Name of the adjustment template frame:flipchip. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Flipchip'**
  String get adjustmentTemplateFlipchipName;

  /// Note of the adjustment template frame:flipchip. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Controls geometry and bottom bracket height'**
  String get adjustmentTemplateFlipchipNotes;

  /// Name of the adjustment template frame:chainstay_length. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Chainstay Length'**
  String get adjustmentTemplateChainstayLengthName;

  /// Note of the adjustment template frame:chainstay_length. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Some bikes have an adjustable chainstay length'**
  String get adjustmentTemplateChainstayLengthNotes;

  /// Option of the categorical template frame:flipchip. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get adjustmentTemplateOptionLow;

  /// Option of the categorical template frame:flipchip, frame:chainstay_length. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get adjustmentTemplateOptionMid;

  /// Option of the categorical template frame:flipchip. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get adjustmentTemplateOptionHigh;

  /// Option of the categorical template frame:chainstay_length. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get adjustmentTemplateOptionShort;

  /// Option of the categorical template frame:chainstay_length. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get adjustmentTemplateOptionLong;

  /// Name of the adjustment template fork:lockout, shock:lockout. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Lockout'**
  String get adjustmentTemplateLockoutName;

  /// Note of the adjustment template fork:lockout, shock:lockout. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Is the lockout lever enabled?'**
  String get adjustmentTemplateLockoutNotes;

  /// Name of the adjustment template fork:pressure, shock:pressure, wheel_front:pressure, tire:pressure. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get adjustmentTemplatePressureName;

  /// Note of the adjustment template fork:pressure. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Fork air pressure'**
  String get adjustmentTemplateForkPressureNotes;

  /// Note of the adjustment template shock:pressure. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Shock air pressure'**
  String get adjustmentTemplateShockPressureNotes;

  /// Name of the adjustment template shock:spring_rate. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Spring Rate'**
  String get adjustmentTemplateSpringRateName;

  /// Note of the adjustment template shock:spring_rate. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Coil spring rate'**
  String get adjustmentTemplateSpringRateNotes;

  /// Name of the adjustment template fork:sag, shock:sag. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'SAG'**
  String get adjustmentTemplateSagName;

  /// Note of the adjustment template fork:sag. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Travel used with you and your gear on the bike in riding position. Targets: XC 15%, Trail 15-20%, Enduro 20%, DH 20-25%'**
  String get adjustmentTemplateForkSagNotes;

  /// Note of the adjustment template shock:sag. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Travel used with you and your gear on the bike in riding position. Targets: XC 20-25%, Trail 25-30%, Enduro 30%, DH 30-35%'**
  String get adjustmentTemplateShockSagNotes;

  /// Name of the adjustment template fork:rebound, shock:rebound. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Rebound'**
  String get adjustmentTemplateReboundName;

  /// Note of the adjustment template fork:rebound, shock:rebound. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Rebound clicks'**
  String get adjustmentTemplateReboundNotes;

  /// Name of the adjustment template fork:compression, shock:compression. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Compression'**
  String get adjustmentTemplateCompressionName;

  /// Note of the adjustment template fork:compression, shock:compression. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Compression clicks'**
  String get adjustmentTemplateCompressionNotes;

  /// Name of the adjustment template fork:lsr, shock:lsr. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'LSR'**
  String get adjustmentTemplateLsrName;

  /// Note of the adjustment template fork:lsr, shock:lsr. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Low Speed Rebound clicks'**
  String get adjustmentTemplateLsrNotes;

  /// Name of the adjustment template fork:hsr, shock:hsr. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'HSR'**
  String get adjustmentTemplateHsrName;

  /// Note of the adjustment template fork:hsr, shock:hsr. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'High Speed Rebound clicks'**
  String get adjustmentTemplateHsrNotes;

  /// Name of the adjustment template fork:lsc, shock:lsc. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'LSC'**
  String get adjustmentTemplateLscName;

  /// Note of the adjustment template fork:lsc, shock:lsc. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Low Speed Compression clicks'**
  String get adjustmentTemplateLscNotes;

  /// Name of the adjustment template fork:hsc, shock:hsc. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'HSC'**
  String get adjustmentTemplateHscName;

  /// Note of the adjustment template fork:hsc, shock:hsc. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'High Speed Compression clicks'**
  String get adjustmentTemplateHscNotes;

  /// Name of the adjustment template fork:volume_spacers, shock:volume_spacers. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Volume Spacers'**
  String get adjustmentTemplateVolumeSpacersName;

  /// Note of the adjustment template fork:volume_spacers, shock:volume_spacers. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Number of volume spacers installed in the air spring'**
  String get adjustmentTemplateVolumeSpacersNotes;

  /// Name of the adjustment template cockpit:bar_roll. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Bar Roll'**
  String get adjustmentTemplateBarRollName;

  /// Note of the adjustment template cockpit:bar_roll. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Angle of handlebars in degrees'**
  String get adjustmentTemplateBarRollNotes;

  /// Name of the adjustment template cockpit:bar_width. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Bar Width'**
  String get adjustmentTemplateBarWidthName;

  /// Note of the adjustment template cockpit:bar_width. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Total width of handlebars'**
  String get adjustmentTemplateBarWidthNotes;

  /// Name of the adjustment template cockpit:bar_rise. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Bar Rise'**
  String get adjustmentTemplateBarRiseName;

  /// Note of the adjustment template cockpit:bar_rise. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'The vertical distance between the center of the clamp area and the center of the bar ends.'**
  String get adjustmentTemplateBarRiseNotes;

  /// Name of the adjustment template stem:stem_length. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Stem Length'**
  String get adjustmentTemplateStemLengthName;

  /// Note of the adjustment template stem:stem_length. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Measured center-to-center from the fork steerer tube to the handlebar clamp.'**
  String get adjustmentTemplateStemLengthNotes;

  /// Name of the adjustment template stem:stem_angle. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Stem Angle'**
  String get adjustmentTemplateStemAngleName;

  /// Note of the adjustment template stem:stem_angle. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Angle of the stem relative to the steering column'**
  String get adjustmentTemplateStemAngleNotes;

  /// Name of the adjustment template stem:stack_spacers. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Stack Spacers'**
  String get adjustmentTemplateStackSpacersName;

  /// Note of the adjustment template stem:stack_spacers, other:stack_height. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Height of spacers under the stem'**
  String get adjustmentTemplateStackSpacersNotes;

  /// Name of the adjustment template grip:rotation. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get adjustmentTemplateGripRotationName;

  /// Note of the adjustment template grip:rotation. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Rotation angle for ergonomic or asymmetric grips'**
  String get adjustmentTemplateGripRotationNotes;

  /// Name of the adjustment template shifter:lateral_position, brake_lever:lateral_position. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Lateral Position'**
  String get adjustmentTemplateLateralPositionName;

  /// Note of the adjustment template shifter:lateral_position. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Distance from the grip to the shifter clamp'**
  String get adjustmentTemplateShifterLateralPositionNotes;

  /// Name of the adjustment template shifter:angle. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get adjustmentTemplateAngleName;

  /// Note of the adjustment template shifter:angle. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Angle of the shifter relative to the horizontal'**
  String get adjustmentTemplateShifterAngleNotes;

  /// Name of the adjustment template derailleur:clutch. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Clutch'**
  String get adjustmentTemplateClutchName;

  /// Note of the adjustment template derailleur:clutch. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Is the derailleur clutch/stabilizer enabled?'**
  String get adjustmentTemplateClutchNotes;

  /// Name of the adjustment template derailleur:clutch_tension. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Clutch Tension'**
  String get adjustmentTemplateClutchTensionName;

  /// Note of the adjustment template derailleur:clutch_tension. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Adjustable clutch tension for some derailleurs'**
  String get adjustmentTemplateClutchTensionNotes;

  /// Option of the categorical template derailleur:clutch_tension. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get adjustmentTemplateOptionSoft;

  /// Option of the categorical template derailleur:clutch_tension. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get adjustmentTemplateOptionMedium;

  /// Option of the categorical template derailleur:clutch_tension. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get adjustmentTemplateOptionHard;

  /// Name of the adjustment template pedal:spring_tension. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Clipless Spring Tension'**
  String get adjustmentTemplateClipSpringTensionName;

  /// Note of the adjustment template pedal:spring_tension. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Release tension setting for clipless pedals'**
  String get adjustmentTemplateClipSpringTensionNotes;

  /// Name of the adjustment template pedal:pin_arrangement. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Pin Arrangement'**
  String get adjustmentTemplatePinArrangementName;

  /// Note of the adjustment template pedal:pin_arrangement. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Pattern and arrangement of pins on platform pedals'**
  String get adjustmentTemplatePinArrangementNotes;

  /// Option of the categorical template pedal:pin_arrangement. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get adjustmentTemplateOptionFull;

  /// Option of the categorical template pedal:pin_arrangement. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Aggressive'**
  String get adjustmentTemplateOptionAggressive;

  /// Option of the categorical template pedal:pin_arrangement, person:riding_style. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get adjustmentTemplateOptionBalanced;

  /// Option of the categorical template pedal:pin_arrangement. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get adjustmentTemplateOptionMinimum;

  /// Name of the adjustment template pedal:pin_height. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Pin Height'**
  String get adjustmentTemplatePinHeightName;

  /// Note of the adjustment template pedal:pin_height. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Height of the pins above the pedal platform'**
  String get adjustmentTemplatePinHeightNotes;

  /// Name of the adjustment template brake_lever:lever_reach. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Lever Reach'**
  String get adjustmentTemplateLeverReachName;

  /// Note of the adjustment template brake_lever:lever_reach. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Distance from the handlebar to the lever blade'**
  String get adjustmentTemplateLeverReachNotes;

  /// Name of the adjustment template brake_lever:lever_angle. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Lever Angle'**
  String get adjustmentTemplateLeverAngleName;

  /// Note of the adjustment template brake_lever:lever_angle. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Angle of brake levers relative to horizontal (pointing down).'**
  String get adjustmentTemplateLeverAngleNotes;

  /// Note of the adjustment template brake_lever:lateral_position. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Distance from the grip to the lever clamp'**
  String get adjustmentTemplateBrakeLeverLateralPositionNotes;

  /// Name of the adjustment template brake_lever:bite_point. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Bite Point'**
  String get adjustmentTemplateBitePointName;

  /// Note of the adjustment template brake_lever:bite_point. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'The distance the lever moves before the pads engage'**
  String get adjustmentTemplateBitePointNotes;

  /// Note of the adjustment template wheel_front:pressure. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Front tire pressure'**
  String get adjustmentTemplateFrontPressureNotes;

  /// Name of the adjustment template wheel_front:insert, wheel_rear:insert. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get adjustmentTemplateInsertName;

  /// Note of the adjustment template wheel_front:insert, wheel_rear:insert. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Tire insert installed?'**
  String get adjustmentTemplateInsertNotes;

  /// Name of the adjustment template wheel_front:wear, tire:wear. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Wear'**
  String get adjustmentTemplateWearName;

  /// Note of the adjustment template wheel_front:wear, wheel_rear:tire_wear, tire:wear. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Current state of the tire tread'**
  String get adjustmentTemplateWearNotes;

  /// Option of the categorical template wheel_front:wear, wheel_rear:tire_wear, tire:wear. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get adjustmentTemplateOptionNew;

  /// Option of the categorical template wheel_front:wear, wheel_rear:tire_wear, tire:wear. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get adjustmentTemplateOptionUsed;

  /// Option of the categorical template wheel_front:wear, wheel_rear:tire_wear, tire:wear. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Worn Out'**
  String get adjustmentTemplateOptionWornOut;

  /// Name of the adjustment template wheel_rear:tire_pressure. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Tire Pressure'**
  String get adjustmentTemplateTirePressureName;

  /// Note of the adjustment template wheel_rear:tire_pressure. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Rear tire pressure'**
  String get adjustmentTemplateRearPressureNotes;

  /// Name of the adjustment template wheel_rear:tire_wear. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Tire Wear'**
  String get adjustmentTemplateTireWearName;

  /// Note of the adjustment template tire:pressure. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Tire pressure'**
  String get adjustmentTemplateTirePressureNotes;

  /// Name of the adjustment template saddle:saddle_tilt. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Saddle Tilt'**
  String get adjustmentTemplateSaddleTiltName;

  /// Note of the adjustment template saddle:saddle_tilt. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Angle of the saddle relative to horizontal'**
  String get adjustmentTemplateSaddleTiltNotes;

  /// Name of the adjustment template saddle:saddle_fore_aft. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Saddle Fore/Aft'**
  String get adjustmentTemplateSaddleForeAftName;

  /// Note of the adjustment template saddle:saddle_fore_aft. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Position of the saddle on the rails'**
  String get adjustmentTemplateSaddleForeAftNotes;

  /// Name of the adjustment template seatpost:saddle_height. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Saddle Height'**
  String get adjustmentTemplateSaddleHeightName;

  /// Note of the adjustment template seatpost:saddle_height. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Distance from Bottom Bracket to top of saddle'**
  String get adjustmentTemplateSaddleHeightNotes;

  /// Name of the adjustment template seatpost:dropper_pressure. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Dropper Pressure'**
  String get adjustmentTemplateDropperPressureName;

  /// Note of the adjustment template seatpost:dropper_pressure. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Air pressure for the dropper post return'**
  String get adjustmentTemplateDropperPressureNotes;

  /// Name of the adjustment template motor:max_power. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Max Power'**
  String get adjustmentTemplateMaxPowerName;

  /// Note of the adjustment template motor:max_power. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Maximum motor power output'**
  String get adjustmentTemplateMaxPowerNotes;

  /// Name of the adjustment template motor:max_torque. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Max Torque'**
  String get adjustmentTemplateMaxTorqueName;

  /// Note of the adjustment template motor:max_torque. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Maximum motor torque'**
  String get adjustmentTemplateMaxTorqueNotes;

  /// Name of the adjustment template motor:mode. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get adjustmentTemplateModeName;

  /// Note of the adjustment template motor:mode. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Current assistance level'**
  String get adjustmentTemplateModeNotes;

  /// Option of the categorical template motor:mode. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Eco'**
  String get adjustmentTemplateOptionEco;

  /// Option of the categorical template motor:mode. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Trail'**
  String get adjustmentTemplateOptionTrail;

  /// Option of the categorical template motor:mode. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Turbo'**
  String get adjustmentTemplateOptionTurbo;

  /// Option of the categorical template motor:mode. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get adjustmentTemplateOptionBoost;

  /// Option of the categorical template motor:mode. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get adjustmentTemplateOptionAuto;

  /// Name of the adjustment template equipment:backpack. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Backpack'**
  String get adjustmentTemplateBackpackName;

  /// Note of the adjustment template equipment:backpack. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Wearing a backpack? Yes/No'**
  String get adjustmentTemplateBackpackNotes;

  /// Name of the adjustment template equipment:upper_clothing_1. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Upper clothing layer 1'**
  String get adjustmentTemplateUpperLayer1Name;

  /// Note of the adjustment template equipment:upper_clothing_1. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'First clothing layer from inside (e.g. thermal shirt, ...)'**
  String get adjustmentTemplateUpperLayer1Notes;

  /// Name of the adjustment template equipment:upper_clothing_2. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Upper clothing layer 2'**
  String get adjustmentTemplateUpperLayer2Name;

  /// Note of the adjustment template equipment:upper_clothing_2. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Second clothing layer from inside (e.g. wind jacket, ...)'**
  String get adjustmentTemplateUpperLayer2Notes;

  /// Option of the categorical template equipment:upper_clothing_1, equipment:upper_clothing_2. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'my Clothing Item A'**
  String get adjustmentTemplateOptionClothingA;

  /// Option of the categorical template equipment:upper_clothing_1, equipment:upper_clothing_2. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'my Clothing Item B'**
  String get adjustmentTemplateOptionClothingB;

  /// Name of the adjustment template equipment:cleat_position. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Cleat Position'**
  String get adjustmentTemplateCleatPositionName;

  /// Note of the adjustment template equipment:cleat_position. It is stored with the adjustment as written.
  ///
  /// In en, this message translates to:
  /// **'Shoe cleat fore/aft or lateral position'**
  String get adjustmentTemplateCleatPositionNotes;

  /// Option of the categorical template equipment:cleat_position. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get adjustmentTemplateOptionForward;

  /// Option of the categorical template equipment:cleat_position. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get adjustmentTemplateOptionNeutral;

  /// Option of the categorical template equipment:cleat_position. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Rearward'**
  String get adjustmentTemplateOptionRearward;

  /// Name of the adjustment template other:stack_height. It becomes the name of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Stack Height'**
  String get adjustmentTemplateStackHeightName;

  /// Name of the rider attribute template person:riding_weight. It becomes the name of the rider attribute, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Riding weight'**
  String get riderTemplateRidingWeightName;

  /// Note of the rider attribute template person:riding_weight. It is stored with the rider attribute as written.
  ///
  /// In en, this message translates to:
  /// **'Weight including all gear (helmet, shoes, hydration pack).'**
  String get riderTemplateRidingWeightNotes;

  /// Name of the rider attribute template person:height. It becomes the name of the rider attribute, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get riderTemplateHeightName;

  /// Note of the rider attribute template person:height. It is stored with the rider attribute as written.
  ///
  /// In en, this message translates to:
  /// **'Body height'**
  String get riderTemplateHeightNotes;

  /// Name of the rider attribute template person:inseam. It becomes the name of the rider attribute, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Inseam'**
  String get riderTemplateInseamName;

  /// Note of the rider attribute template person:inseam. It is stored with the rider attribute as written.
  ///
  /// In en, this message translates to:
  /// **'Crotch to floor, barefoot. Helps with dropper post length and saddle height.'**
  String get riderTemplateInseamNotes;

  /// Name of the rider attribute template person:ftp. It becomes the name of the rider attribute, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'FTP'**
  String get riderTemplateFtpName;

  /// Note of the rider attribute template person:ftp. It is stored with the rider attribute as written.
  ///
  /// In en, this message translates to:
  /// **'Functional Threshold Power: the highest power you can sustain for about one hour.'**
  String get riderTemplateFtpNotes;

  /// Name of the rider attribute template person:max_heart_rate. It becomes the name of the rider attribute, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Max heart rate'**
  String get riderTemplateMaxHeartRateName;

  /// Note of the rider attribute template person:max_heart_rate. It is stored with the rider attribute as written.
  ///
  /// In en, this message translates to:
  /// **'Highest heart rate reached in an all-out effort. Basis for heart rate zones.'**
  String get riderTemplateMaxHeartRateNotes;

  /// Name of the rider attribute template person:resting_heart_rate. It becomes the name of the rider attribute, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Resting heart rate'**
  String get riderTemplateRestingHeartRateName;

  /// Note of the rider attribute template person:resting_heart_rate. It is stored with the rider attribute as written.
  ///
  /// In en, this message translates to:
  /// **'Heart rate at rest, ideally measured right after waking up.'**
  String get riderTemplateRestingHeartRateNotes;

  /// Name of the rider attribute template person:lthr. It becomes the name of the rider attribute, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'LTHR'**
  String get riderTemplateLthrName;

  /// Note of the rider attribute template person:lthr. It is stored with the rider attribute as written.
  ///
  /// In en, this message translates to:
  /// **'Lactate Threshold Heart Rate: the average heart rate you can sustain for about one hour.'**
  String get riderTemplateLthrNotes;

  /// Name of the rider attribute template person:riding_style. It becomes the name of the rider attribute, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Riding style'**
  String get riderTemplateRidingStyleName;

  /// Note of the rider attribute template person:riding_style. It is stored with the rider attribute as written.
  ///
  /// In en, this message translates to:
  /// **'Race-oriented riders usually require higher support (more compression damping).'**
  String get riderTemplateRidingStyleNotes;

  /// Option of the categorical template person:riding_style. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get adjustmentTemplateOptionComfort;

  /// Option of the categorical template person:riding_style. It becomes an option of the adjustment, which is stored as written.
  ///
  /// In en, this message translates to:
  /// **'Race'**
  String get adjustmentTemplateOptionRace;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'it', 'pt'].contains(locale.languageCode);

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
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
