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

    expect(find.text('任务入口'), findsOneWidget);
    expect(find.text('点贴纸查看任务'), findsOneWidget);

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
}
