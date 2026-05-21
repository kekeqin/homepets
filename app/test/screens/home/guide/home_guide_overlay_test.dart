import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/screens/home/guide/home_guide_controller.dart';
import 'package:homepets/screens/home/guide/home_guide_overlay.dart';

void main() {
  testWidgets('renders dynamic copy and handles skip', (tester) async {
    var skipped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 720,
            child: HomeGuideOverlay(
              step: HomeGuideStep.taskSticker,
              anchorRect: const Rect.fromLTWH(40, 80, 80, 72),
              screenSize: const Size(390, 720),
              onHotspotTap: () {},
              onSkip: () => skipped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('点击这里打开任务面板'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    await tester.tap(find.text('稍后再看'));
    expect(skipped, isTrue);
  });

  testWidgets('taps highlighted hotspot', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 720,
            child: HomeGuideOverlay(
              step: HomeGuideStep.familyFrame,
              anchorRect: const Rect.fromLTWH(280, 210, 64, 64),
              screenSize: const Size(390, 720),
              onHotspotTap: () => tapped = true,
              onSkip: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(312, 242));

    expect(tapped, isTrue);
  });

  testWidgets('renders step-specific preview copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 720,
            child: HomeGuideOverlay(
              step: HomeGuideStep.petArea,
              anchorRect: const Rect.fromLTWH(140, 410, 110, 90),
              screenSize: const Size(390, 720),
              onHotspotTap: () {},
              onSkip: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('点击宠物查看成长'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });
}
