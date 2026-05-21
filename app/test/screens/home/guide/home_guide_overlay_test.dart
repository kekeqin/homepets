import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/screens/home/guide/home_guide_controller.dart';
import 'package:homepets/screens/home/guide/home_guide_overlay.dart';

void main() {
  testWidgets('renders dynamic copy and handles skip', (tester) async {
    var skipped = false;
    _setSurface(tester, const Size(390, 720));

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

    expect(find.text('点击这里打开\n任务面板'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/ui/login/bubble.png')),
      findsOneWidget,
    );
    expect(
      find.image(
        const AssetImage('assets/images/pets/grow/dog/baby/sitting.png'),
      ),
      findsOneWidget,
    );
    expect(find.byType(Image), findsWidgets);
    final previewRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_preview')),
    );
    final bubbleRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble')),
    );
    final petRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_task_pet')),
    );
    final fingerRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_finger')),
    );
    expect(find.byKey(const ValueKey('home_guide_arrow')), findsOneWidget);
    expect(find.text('睡前阅读'), findsOneWidget);
    expect(previewRect.width, inInclusiveRange(255, 270));
    expect(previewRect.height, inInclusiveRange(320, 340));
    expect(previewRect.top, inInclusiveRange(150, 165));
    expect(fingerRect.left, greaterThanOrEqualTo(70));
    expect(fingerRect.right, lessThanOrEqualTo(170));
    expect(fingerRect.top, lessThan(100));
    expect(bubbleRect.top, greaterThan(450));
    expect(bubbleRect.width, greaterThan(238));
    expect(petRect.left, lessThan(4));
    expect(petRect.bottom, greaterThan(660));

    await tester.tap(find.text('稍后再看'));
    expect(skipped, isTrue);
  });

  testWidgets('taps highlighted hotspot', (tester) async {
    var tapped = false;
    _setSurface(tester, const Size(390, 720));

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
    expect(
      find.image(const AssetImage('assets/images/ui/login/bubble.png')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home_guide_finger')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_guide_arrow')), findsOneWidget);
    expect(find.text('妹妹'), findsOneWidget);
    expect(find.text('哥哥'), findsOneWidget);
    final previewRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_preview')),
    );
    final bubbleRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble')),
    );
    final petRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_task_pet')),
    );
    expect(previewRect.width, greaterThan(240));
    expect(previewRect.width, inInclusiveRange(255, 270));
    expect(previewRect.height, inInclusiveRange(320, 340));
    expect(previewRect.top, inInclusiveRange(150, 165));
    expect(bubbleRect.top, greaterThan(500));
    expect(petRect.left, lessThan(4));
    expect(petRect.bottom, greaterThan(660));
  });

  testWidgets('renders step-specific preview copy', (tester) async {
    _setSurface(tester, const Size(390, 720));

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
    expect(
      find.image(const AssetImage('assets/images/ui/login/bubble.png')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home_guide_finger')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_guide_arrow')), findsOneWidget);
    expect(find.text('团团'), findsOneWidget);
    expect(find.textContaining('LV'), findsWidgets);
    final previewRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_preview')),
    );
    final bubbleRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble')),
    );
    final petRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_task_pet')),
    );
    expect(previewRect.width, inInclusiveRange(255, 270));
    expect(previewRect.height, inInclusiveRange(320, 340));
    expect(previewRect.top, inInclusiveRange(150, 165));
    expect(bubbleRect.top, greaterThan(500));
    expect(petRect.left, lessThan(4));
    expect(petRect.bottom, greaterThan(660));
    expect(find.byType(Image), findsWidgets);
  });
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
