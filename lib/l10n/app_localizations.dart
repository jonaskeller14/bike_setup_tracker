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
