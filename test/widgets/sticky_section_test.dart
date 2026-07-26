import 'package:bike_setup_tracker/widgets/sticky_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 3 sections, each: 40px header + 20 rows x 30px = 640px per section.
  // Default test viewport is 800x600.
  const headerHeight = 40.0;
  const sectionHeight = headerHeight + 20 * 30.0;

  Widget buildList(ScrollController controller) {
    return MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          controller: controller,
          slivers: [
            SliverList.builder(
              itemCount: 3,
              itemBuilder: (context, index) => StickySection(
                header: SizedBox(
                  height: headerHeight,
                  width: double.infinity,
                  child: Text('H$index'),
                ),
                content: Column(
                  children: [
                    for (var row = 0; row < 20; row++)
                      SizedBox(
                        height: 30,
                        width: double.infinity,
                        child: Text('S$index R$row'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('header scrolls normally while its section is fully visible',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildList(controller));

    expect(tester.getTopLeft(find.text('H0')).dy, 0);

    // Section 0 still covers the viewport top after 100px: header pins at 0.
    controller.jumpTo(100);
    await tester.pump();
    expect(tester.getTopLeft(find.text('H0')).dy, 0);
    // Rows keep scrolling beneath it.
    expect(tester.getTopLeft(find.text('S0 R4')).dy,
        headerHeight + 4 * 30.0 - 100);
  });

  testWidgets('next section pushes the pinned header out', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildList(controller));

    // 620px in: only 20px of section 0 remain above section 1, so its 40px
    // header is clamped to the section end and sticks out by -20.
    controller.jumpTo(620);
    await tester.pump();
    expect(tester.getTopLeft(find.text('H0')).dy, -20);
    // Section 1 starts right below and its header pins next.
    expect(tester.getTopLeft(find.text('H1')).dy, 20);

    controller.jumpTo(sectionHeight + 100);
    await tester.pump();
    expect(find.text('H0'), findsNothing);
    expect(tester.getTopLeft(find.text('H1')).dy, 0);
  });

  testWidgets('sections stay lazy inside the SliverList', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildList(controller));

    // Section 2 starts at 1280px — outside viewport (600) + cache extent
    // (250), so it must not have been built.
    expect(find.text('H2'), findsNothing);

    controller.jumpTo(2 * sectionHeight - 100);
    await tester.pump();
    expect(find.text('H2'), findsOneWidget);
  });
}
