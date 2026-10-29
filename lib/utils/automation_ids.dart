/// `Semantics.identifier` values for UI automation — the store-screenshot
/// flows under `tool/screenshots/flows/` select by these instead of visible
/// text, so localized labels don't break them. Flutter exposes them as the
/// Android resource-id and the iOS accessibility identifier.
///
/// Renaming a value breaks every flow that references it.
abstract final class AutomationIds {
  static const navBikes = 'nav.bikes';
  static const navSetups = 'nav.setups';
  static const navTasks = 'nav.tasks';

  static const appBarRider = 'appBar.rider';
  static const appBarStrava = 'appBar.strava';
  static const appBarOptions = 'appBar.options';

  static const addSetupFab = 'setups.add';
  static const setupListCalendar = 'setups.calendar';
  static const setupListMap = 'setups.map';
  static String setupActions(String setupId) => 'setup.actions.$setupId';
  static const setupActionsCompare = 'setup.compare';
  static const setupDetailsActions = 'setupDetails.actions';

  /// The comparison sheet's setup pickers, by side ('A' or 'B').
  static String compareSetupsSide(String side) => 'compareSetups.side.$side';
  static String compareSetupsOption(String setupId) => 'compareSetups.option.$setupId';

  static const addBikeFab = 'garage.addBike';
  static String garageBike(String bikeId) => 'garage.bike.$bikeId';
  static String garageComponent(String componentId) => 'garage.component.$componentId';
  static String garageAddComponent(String bikeId) => 'garage.addComponent.$bikeId';

  static const bikeFormSave = 'bikeForm.save';

  static const componentActions = 'component.actions';
  static const componentActionsDuplicate = 'component.actions.duplicate';

  static const componentDetailsAdjustmentHistory = 'componentDetails.adjustmentHistory';
  static const componentDetailsColumns = 'componentDetails.columns';
  static const componentDetailsLineChart = 'componentDetails.lineChart';
  static const componentDetailsRadialChart = 'componentDetails.radialChart';
  static const componentDetailsHistogram = 'componentDetails.histogram';

  /// The "Open Tasks" section header on the bike and component details pages.
  static const openTasks = 'openTasks';

  static const setupTableSelectAll = 'setupTable.selectAll';

  /// Legend entries in chart order, so a flow can pick "the first setup".
  static String radialChartLegend(int index) => 'radialChart.legend.$index';
  static String lineChartLegend(int index) => 'lineChart.legend.$index';

  static const componentFormSave = 'componentForm.save';
  static const componentFormAdditionalFields = 'componentForm.additionalFields';
  static const componentFormType = 'componentForm.type';
  static const componentFormName = 'componentForm.name';
  static const componentFormAddAdjustment = 'componentForm.addAdjustment';
  static String componentType(String typeName) => 'componentType.$typeName';
  static String adjustmentPreset(String presetKey) => 'adjustmentPreset.$presetKey';
  static const adjustmentFormSave = 'adjustmentForm.save';

  static const setupFormSave = 'setupForm.save';
  static const setupFormName = 'setupForm.name';
  static const setupFormNotes = 'setupForm.notes';
  static const setupFormAddTags = 'setupForm.addTags';
  static const setupFormCondition = 'setupForm.condition';
  static String setAdjustment(String adjustmentId) => 'setAdjustment.$adjustmentId';

  static String stravaActivity(int activityId) => 'stravaActivity.$activityId';
  static const stravaActivityActions = 'stravaActivity.actions';
  static const stravaActivityViewOnMap = 'stravaActivity.viewOnMap';
  static const stravaActivitySetups = 'stravaActivity.setups';

  static String taskRuleComplete(String taskRuleId) => 'taskRule.complete.$taskRuleId';
  static String taskRuleTitle(String taskRuleId) => 'taskRule.title.$taskRuleId';
  static const taskEntryFormSave = 'taskEntryForm.save';

  static const mapFocusActivity = 'map.focusActivity';
  static String mapSetup(String setupId) => 'map.setup.$setupId';

  static const calendarToday = 'calendar.today';

  /// A calendar appointment by its timeline entry id, e.g. `setup:<id>`.
  static String calendarEntry(String entryId) => 'calendar.entry.$entryId';
}
