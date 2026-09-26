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

  static const addSetupFab = 'setups.add';
  static const setupListCalendar = 'setups.calendar';

  static String garageBike(String bikeId) => 'garage.bike.$bikeId';
  static String garageComponent(String componentId) => 'garage.component.$componentId';

  static const componentActions = 'component.actions';
  static const componentActionsDuplicate = 'component.actions.duplicate';

  static const componentDetailsLineChart = 'componentDetails.lineChart';

  static const componentFormSave = 'componentForm.save';

  static const setupFormName = 'setupForm.name';
  static const setupFormNotes = 'setupForm.notes';
  static const setupFormAddTags = 'setupForm.addTags';
  static String setAdjustment(String adjustmentId) => 'setAdjustment.$adjustmentId';

  static String stravaActivity(int activityId) => 'stravaActivity.$activityId';
  static const stravaActivityActions = 'stravaActivity.actions';
  static const stravaActivityViewOnMap = 'stravaActivity.viewOnMap';

  static const mapFocusActivity = 'map.focusActivity';

  static const calendarToday = 'calendar.today';
}
