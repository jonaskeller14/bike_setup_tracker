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

  /// Title of the preference and sheet that picks the first day of the week.
  ///
  /// In en, this message translates to:
  /// **'First Day of Week'**
  String get preferencesFirstDayOfWeek;

  /// First day of the week choice.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get preferencesMonday;

  /// First day of the week choice.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get preferencesSunday;

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

  /// Explanation of the component presets feature.
  ///
  /// In en, this message translates to:
  /// **'When adding a fork or shock, pick the model from a built-in catalog to prefill its name, notes and adjustments (click ranges, air pressure, SAG) automatically. You can still edit everything afterwards.'**
  String get featuresComponentPresetsInfo;

  /// Subtitle of a disabled feature that depends on component presets.
  ///
  /// In en, this message translates to:
  /// **'Requires Component Presets'**
  String get featuresRequiresComponentPresets;

  /// Title of the task presets feature (developer builds).
  ///
  /// In en, this message translates to:
  /// **'Task Presets'**
  String get featuresTaskPresets;

  /// Explanation of the task presets feature.
  ///
  /// In en, this message translates to:
  /// **'Suggests recommended tasks for a component, like a chain wear check or a fork service, based on its type and catalog model. You pick each suggestion individually and can edit the created tasks freely. Requires Component Presets, Tasks and Task Intervals.'**
  String get featuresTaskPresetsInfo;

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

  /// Title of the language selection feature (developer builds).
  ///
  /// In en, this message translates to:
  /// **'Language Selection'**
  String get featuresLanguageSelection;

  /// Explanation of the language selection feature.
  ///
  /// In en, this message translates to:
  /// **'Follows the system language, or the language picked in Preferences, instead of always showing English. Translations are still being added, so some screens stay English.'**
  String get featuresLanguageSelectionInfo;

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
  /// **'Task recommendations turned off. Turn them back on in Settings › Features.'**
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

  /// Group header in the link picker for components whose bike no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Bike not found'**
  String get taskAssociationBikeMissing;

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

  /// Chip that says no problem was felt.
  ///
  /// In en, this message translates to:
  /// **'Nothing stood out'**
  String get feedbackNothingStoodOut;

  /// Summary of a feedback where nothing stood out.
  ///
  /// In en, this message translates to:
  /// **'Dialled in'**
  String get feedbackDialledIn;

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
  /// **'Test session'**
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

  /// Info text of the adjustments of a running session.
  ///
  /// In en, this message translates to:
  /// **'Tap an adjustment to lock it at its value in the latest run. The next runs keep that value.'**
  String get testSessionLockInfo;

  /// Section title of the runs of a test session.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get testSessionRunsTitle;

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
