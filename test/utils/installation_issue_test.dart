import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:bike_setup_tracker/utils/installation_issue.dart';
import 'package:flutter_test/flutter_test.dart';

Component component(String id, List<Installation> installations) => Component(
  id: id,
  name: id,
  installations: installations,
  componentType: ComponentType.other,
);

Installation onBike(String componentId, String bikeId) => BikeInstallation(
  componentId: componentId,
  bikeId: bikeId,
  dateTimeUTC: DateTime.utc(2026, 1, 1),
  dateTimeLocal: DateTime(2026, 1, 1),
);

Installation onComponent(String componentId, String parentId) => ComponentInstallation(
  componentId: componentId,
  parentComponentId: parentId,
  dateTimeUTC: DateTime.utc(2026, 1, 1),
  dateTimeLocal: DateTime(2026, 1, 1),
);

Bike bike(String id) => Bike(id: id, name: id, person: null);

void main() {
  final bikes = {'bike': bike('bike')};

  InstallationIssue? issueOf(
    String componentId,
    Map<String, Component> components, {
    Set<String> deletedComponentIds = const {},
  }) => installationIssueOf(
    componentId,
    hierarchy: ComponentHierarchyResolver(
      components,
      deletedComponentIds: deletedComponentIds,
    ),
    bikes: bikes,
  );

  test('healthy component on an existing bike has no issue', () {
    final components = {
      'wheel': component('wheel', [onBike('wheel', 'bike')]),
    };

    expect(issueOf('wheel', components), isNull);
  });

  test('uninstalled component has no issue', () {
    final components = {
      'wheel': component('wheel', [
        onBike('wheel', 'bike'),
        Uninstallation(
          componentId: 'wheel',
          dateTimeUTC: DateTime.utc(2026, 1, 2),
          dateTimeLocal: DateTime(2026, 1, 2),
        ),
      ]),
    };

    expect(issueOf('wheel', components), isNull);
  });

  test('archived component has no issue', () {
    final components = {
      'wheel': component('wheel', [
        Archival(
          componentId: 'wheel',
          dateTimeUTC: DateTime.utc(2026, 1, 2),
          dateTimeLocal: DateTime(2026, 1, 2),
        ),
      ]),
    };

    expect(issueOf('wheel', components), isNull);
  });

  test('component with no installations has no issue', () {
    final components = {'wheel': component('wheel', [])};

    expect(issueOf('wheel', components), isNull);
  });

  test('installation on an unknown bike reports a missing bike', () {
    final components = {
      'wheel': component('wheel', [onBike('wheel', 'gone')]),
    };

    expect(issueOf('wheel', components), InstallationIssue.missingBike);
  });

  test('installation on an unknown component reports a missing parent', () {
    final components = {
      'tire': component('tire', [onComponent('tire', 'gone')]),
    };

    expect(issueOf('tire', components), InstallationIssue.missingParent);
  });

  test('installation on a trashed component reports a missing parent', () {
    final components = {
      'wheel': component('wheel', [onBike('wheel', 'bike')]),
      'tire': component('tire', [onComponent('tire', 'wheel')]),
    };

    expect(
      issueOf('tire', components, deletedComponentIds: {'wheel'}),
      InstallationIssue.missingParent,
    );
  });

  test('a child of a broken parent stays unreported', () {
    final components = {
      'wheel': component('wheel', [onComponent('wheel', 'gone')]),
      'tire': component('tire', [onComponent('tire', 'wheel')]),
    };

    expect(issueOf('wheel', components), InstallationIssue.missingParent);
    expect(issueOf('tire', components), isNull);
  });

  test('only the root of a two-level chain under a missing bike reports', () {
    final components = {
      'wheel': component('wheel', [onBike('wheel', 'gone')]),
      'tire': component('tire', [onComponent('tire', 'wheel')]),
      'insert': component('insert', [onComponent('insert', 'tire')]),
    };

    expect(issueOf('wheel', components), InstallationIssue.missingBike);
    expect(issueOf('tire', components), isNull);
    expect(issueOf('insert', components), isNull);
  });

  test('labels name the reason', () {
    expect(InstallationIssue.missingBike.label, 'Bike not found');
    expect(InstallationIssue.missingParent.label, 'Parent component not found');
  });
}
