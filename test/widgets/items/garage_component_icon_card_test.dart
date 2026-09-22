import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/installation_issue.dart';
import 'package:bike_setup_tracker/widgets/items/garage_component_icon_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAppRepository extends Mock implements AppRepository {}

const _spacing = 8.0;

void main() {
  group('GarageComponentIconCard.widthFor', () {
    test('keeps one logical pixel free around column thresholds', () {
      for (var columns = 1; columns <= 16; columns++) {
        final threshold =
            columns * GarageComponentIconCard.minimumWidth +
            (columns - 1) * _spacing +
            GarageComponentIconCard.rowEndSpacing;

        for (final offset in [-0.001, 0.0, 0.001]) {
          final availableWidth = threshold + offset;
          final itemWidth = GarageComponentIconCard.widthFor(
            availableWidth,
            spacing: _spacing,
          );
          final safeAvailableWidth = availableWidth - GarageComponentIconCard.rowEndSpacing;
          final fittingCards = ((safeAvailableWidth + _spacing) / (GarageComponentIconCard.minimumWidth + _spacing))
              .floor();
          final cardsPerRow = fittingCards < 1 ? 1 : fittingCards;
          final occupiedWidth = cardsPerRow * itemWidth + (cardsPerRow - 1) * _spacing;

          expect(
            occupiedWidth,
            closeTo(safeAvailableWidth, 1e-10),
            reason: 'columns=$columns offset=$offset',
          );
          expect(occupiedWidth, lessThan(availableWidth));
        }
      }
    });
  });

  testWidgets('component and bordered plus tiles match without overflow', (
    tester,
  ) async {
    final settings = AppSettings();
    addTearDown(settings.dispose);

    for (var columns = 2; columns <= 16; columns++) {
      final threshold =
          columns * GarageComponentIconCard.minimumWidth +
          (columns - 1) * _spacing +
          GarageComponentIconCard.rowEndSpacing;

      for (final offset in [-0.001, 0.0, 0.001]) {
        await tester.pumpWidget(
          ChangeNotifierProvider<AppSettings>.value(
            value: settings,
            child: MaterialApp(
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: threshold + offset,
                    child: const _AdaptiveTileWrap(),
                  ),
                ),
              ),
            ),
          ),
        );

        final componentSize = tester.getSize(
          find.byKey(const ValueKey('component-tile')),
        );
        final plusSize = tester.getSize(
          find.byKey(const ValueKey('plus-tile')),
        );

        expect(plusSize.width, closeTo(componentSize.width, 1e-10));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('23 components do not overflow at the landscape boundary', (
    tester,
  ) async {
    final settings = AppSettings();
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 800,
                child: _AdaptiveTileWrap(componentCount: 23),
              ),
            ),
          ),
        ),
      ),
    );

    final firstTile = find.byKey(const ValueKey('component-tile'));
    final fourteenthTile = find.byKey(const ValueKey('component-tile-13'));
    final fifteenthTile = find.byKey(const ValueKey('component-tile-14'));
    final plusTile = find.byKey(const ValueKey('plus-tile'));

    expect(tester.getTopLeft(fourteenthTile).dy, tester.getTopLeft(firstTile).dy);
    expect(tester.getTopLeft(fifteenthTile).dy, greaterThan(tester.getTopLeft(firstTile).dy));
    expect(tester.getSize(plusTile).width, tester.getSize(firstTile).width);
    expect(tester.takeException(), isNull);
  });

  group('installation issue badge', () {
    final component = Component(
      id: 'component',
      name: 'Component',
      installations: [],
      componentType: ComponentType.other,
    );

    late _MockAppRepository repository;
    late AppSettings settings;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = _MockAppRepository();
      when(() => repository.componentTaskIndicatorStatus(component.id)).thenReturn(null);
      settings = AppSettings();
      addTearDown(settings.dispose);
    });

    Future<void> pumpCard(
      WidgetTester tester, {
      InstallationIssue? issue,
      bool selected = false,
    }) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppSettings>.value(value: settings),
            ChangeNotifierProvider<AppRepository>.value(value: repository),
          ],
          child: MaterialApp(
            theme: materialAppTheme,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: GarageComponentIconCard(
                  component: component,
                  componentToShowDetails: selected ? component.id : null,
                  width: GarageComponentIconCard.minimumWidth,
                  issue: issue,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Color borderColor(WidgetTester tester) {
      final container = tester.widget<Container>(find.byKey(ValueKey(component.id)));
      return ((container.decoration! as BoxDecoration).border! as Border).top.color;
    }

    ColorScheme colorScheme(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(GarageComponentIconCard))).colorScheme;

    testWidgets('healthy component shows no badge', (tester) async {
      await pumpCard(tester);

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(borderColor(tester), colorScheme(tester).outlineVariant);
      expect(tester.takeException(), isNull);
    });

    testWidgets('missing bike is badged and announced', (tester) async {
      final semantics = tester.ensureSemantics();

      await pumpCard(tester, issue: InstallationIssue.missingBike);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.bySemanticsLabel('Bike not found'), findsOneWidget);
      expect(borderColor(tester), colorScheme(tester).error);
      expect(tester.takeException(), isNull);

      semantics.dispose();
    });

    testWidgets('missing parent is badged and announced', (tester) async {
      final semantics = tester.ensureSemantics();

      await pumpCard(tester, issue: InstallationIssue.missingParent);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.bySemanticsLabel('Parent component not found'), findsOneWidget);
      expect(tester.takeException(), isNull);

      semantics.dispose();
    });

    testWidgets('selected styling stays dominant over the issue tint', (tester) async {
      await pumpCard(tester, issue: InstallationIssue.missingBike, selected: true);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(borderColor(tester), colorScheme(tester).tertiary);
      expect(tester.takeException(), isNull);
    });

    testWidgets('badge and task dot keep opposite corners', (tester) async {
      settings.enableTask = true;
      when(() => repository.componentTaskIndicatorStatus(component.id))
          .thenReturn(TaskStatusType.overdue);

      await pumpCard(tester, issue: InstallationIssue.missingBike);

      final badge = tester.getRect(find.byIcon(Icons.error_outline));
      final dot = tester.getRect(
        find.byWidgetPredicate(
          (widget) => widget is Container && widget.constraints == BoxConstraints.tight(const Size(10, 10)),
        ),
      );

      expect(badge.right, lessThan(dot.left));
      expect(tester.takeException(), isNull);
    });
  });
}

class _AdaptiveTileWrap extends StatelessWidget {
  final int componentCount;

  const _AdaptiveTileWrap({this.componentCount = 1});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = GarageComponentIconCard.widthFor(
          constraints.maxWidth,
          spacing: _spacing,
        );

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (var index = 0; index < componentCount; index++)
              GarageComponentIconCard(
                key: ValueKey(
                  index == 0 ? 'component-tile' : 'component-tile-$index',
                ),
                component: Component(
                  id: 'component-$index',
                  name: 'Component $index',
                  installations: const [],
                  componentType: ComponentType.other,
                ),
                componentToShowDetails: null,
                width: itemWidth,
              ),
            Container(
              key: const ValueKey('plus-tile'),
              width: itemWidth,
              decoration: BoxDecoration(
                border: Border.all(width: 1),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.add, size: 24)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
