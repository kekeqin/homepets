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

    expect(_guideBubbleText(tester), '点击这里打开\n任务面板');
    expect(find.text('稍后再看'), findsNothing);
    expect(find.text('1/3'), findsNothing);
    expect(find.text('2/3'), findsNothing);
    expect(find.text('3/3'), findsNothing);
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
    final bubbleTextRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble_message')),
    );
    final petRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_task_pet')),
    );
    final fingerRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_finger')),
    );
    final fingertip = _fingerTipFor(fingerRect);
    expect(find.byKey(const ValueKey('home_guide_arrow')), findsNothing);
    expect(find.text('睡前阅读'), findsOneWidget);
    expect(find.text('+12'), findsOneWidget);
    expect(previewRect.width, inInclusiveRange(255, 270));
    expect(previewRect.height, inInclusiveRange(320, 340));
    expect(previewRect.top, inInclusiveRange(150, 165));
    expect(fingertip.dx, closeTo(122, 1));
    expect(fingertip.dy, closeTo(150, 1));
    expect(bubbleRect.top, greaterThan(450));
    expect(bubbleRect.width, greaterThan(238));
    expect(_isTextCenteredInBubble(bubbleRect, bubbleTextRect), isTrue);
    expect(petRect.left, lessThan(4));
    expect(petRect.bottom, greaterThan(660));

    expect(skipped, isFalse);
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
    expect(find.byKey(const ValueKey('home_guide_arrow')), findsNothing);
    expect(find.text('爸爸'), findsOneWidget);
    expect(find.text('妈妈'), findsOneWidget);
    expect(find.text('哥哥'), findsOneWidget);
    expect(find.text('妹妹'), findsOneWidget);
    expect(_guideBubbleText(tester), '点击这里管理\n家庭成员');
    final fingerRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_finger')),
    );
    final fingertip = _fingerTipFor(fingerRect);
    final previewRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_preview')),
    );
    final bubbleRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble')),
    );
    final bubbleTextRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble_message')),
    );
    final petRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_task_pet')),
    );
    expect(previewRect.width, greaterThan(240));
    expect(previewRect.width, inInclusiveRange(255, 270));
    expect(previewRect.height, inInclusiveRange(320, 340));
    expect(previewRect.top, inInclusiveRange(150, 165));
    expect(previewRect.left, lessThan(45));
    expect(fingertip.dx, closeTo(346, 1));
    expect(fingertip.dy, closeTo(272, 1));
    expect(bubbleRect.top, greaterThan(500));
    expect(_isTextCenteredInBubble(bubbleRect, bubbleTextRect), isTrue);
    expect(petRect.left, lessThan(4));
    expect(petRect.bottom, greaterThan(660));
  });

  testWidgets('renders step-specific preview copy', (tester) async {
    var tapped = false;
    _setSurface(tester, const Size(390, 720));
    const petAnchor = Rect.fromLTWH(92, 452, 110, 90);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 720,
            child: HomeGuideOverlay(
              step: HomeGuideStep.petArea,
              anchorRect: petAnchor,
              screenSize: const Size(390, 720),
              onHotspotTap: () => tapped = true,
              onSkip: () {},
            ),
          ),
        ),
      ),
    );

    expect(_guideBubbleText(tester), '点这里查看\n宠物详情');
    expect(
      find.image(const AssetImage('assets/images/ui/login/bubble.png')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home_guide_finger')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_guide_arrow')), findsNothing);
    expect(find.text('团团'), findsOneWidget);
    expect(find.textContaining('LV'), findsWidgets);
    expect(find.text('最近互动'), findsNothing);
    expect(find.text('整理书包 +10'), findsOneWidget);
    expect(find.text('喂宠物 +8'), findsOneWidget);
    expect(find.text('睡前阅读 +12'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/ui/sprites/label_blank.png')),
      findsOneWidget,
    );
    final previewRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_preview')),
    );
    final bubbleRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble')),
    );
    final bubbleTextRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble_message')),
    );
    final petRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_task_pet')),
    );
    final fingerRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_finger')),
    );
    final fingertip = _fingerTipFor(fingerRect);
    expect(previewRect.width, inInclusiveRange(255, 270));
    expect(previewRect.height, inInclusiveRange(320, 340));
    expect(previewRect.top, inInclusiveRange(150, 165));
    expect(bubbleRect.top, greaterThan(500));
    expect(_isTextCenteredInBubble(bubbleRect, bubbleTextRect), isTrue);
    expect(petRect.left, lessThan(4));
    expect(petRect.bottom, greaterThan(660));
    expect(
      fingertip.dx,
      closeTo(petAnchor.center.dx + petAnchor.width * 0.12, 1),
    );
    expect(
      fingertip.dy,
      closeTo(petAnchor.center.dy + petAnchor.height * 0.16, 1),
    );
    expect(fingertip.dx, inInclusiveRange(petAnchor.left, petAnchor.right));
    expect(fingertip.dy, inInclusiveRange(petAnchor.top, petAnchor.bottom));

    await tester.tapAt(const Offset(250, 520));
    expect(tapped, isFalse);
    await tester.tapAt(petAnchor.center);
    expect(tapped, isTrue);
    expect(find.byType(Image), findsWidgets);
  });
}

Offset _fingerTipFor(Rect fingerRect) {
  return fingerRect.topLeft +
      Offset(fingerRect.width * 0.235, fingerRect.height * 0.207);
}

String _guideBubbleText(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find.byKey(const ValueKey('home_guide_bubble_message')),
  );
  return richText.text.toPlainText();
}

bool _isTextCenteredInBubble(Rect bubble, Rect text) {
  final safeRect = Rect.fromLTRB(
    bubble.left + bubble.width * 0.18,
    bubble.top + bubble.height * 0.18,
    bubble.right - bubble.width * 0.23,
    bubble.bottom - bubble.height * 0.26,
  );
  return (text.center.dx - safeRect.center.dx).abs() < 2 &&
      (text.center.dy - safeRect.center.dy).abs() < 2;
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
