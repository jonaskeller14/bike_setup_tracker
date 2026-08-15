import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/widgets/items/garage_component_icon_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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
