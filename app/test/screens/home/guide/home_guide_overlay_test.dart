import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/screens/home/guide/home_guide_controller.dart';
import 'package:pickstarpet/screens/home/guide/home_guide_overlay.dart';

void main() {
  testWidgets('renders lightweight task guide without preview content', (
    tester,
  ) async {
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
    expect(find.byKey(const ValueKey('home_guide_preview')), findsNothing);
    expect(find.byKey(const ValueKey('home_guide_arrow')), findsNothing);
    expect(
      find.byKey(const ValueKey('home_guide_background_scrim')),
      findsOneWidget,
    );
    expect(find.text('睡前阅读'), findsNothing);
    expect(find.text('+12'), findsNothing);
    expect(find.text('稍后再看'), findsNothing);
    expect(find.text('1/3'), findsNothing);
    expect(
      find.image(const AssetImage('assets/images/ui/login/bubble.webp')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home_guide_companion_pet')),
      findsNothing,
    );

    final bubbleRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble')),
    );
    final bubbleTextRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble_message')),
    );
    final fingerRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_finger')),
    );
    final glowRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_target_glow')),
    );
    final fingertip = _fingerTipFor(fingerRect);
    expect(fingertip.dx, closeTo(118, 1));
    expect(fingertip.dy, closeTo(150, 1));
    expect(glowRect, const Rect.fromLTWH(0, 0, 390, 720));
    _expectBubbleBesideFinger(bubbleRect, fingerRect);
    expect(bubbleRect.width, inInclusiveRange(184, 224));
    expect(
      _isTextCenteredInBubble(
        bubbleRect,
        bubbleTextRect,
        tailOnRight: _bubbleTailOnRight(bubbleRect, fingerRect),
      ),
      isTrue,
    );
    expect(
      _isTextInsideBubble(
        bubbleRect,
        bubbleTextRect,
        tailOnRight: _bubbleTailOnRight(bubbleRect, fingerRect),
      ),
      isTrue,
    );
    final bubbleMessage = tester.widget<RichText>(
      find.byKey(const ValueKey('home_guide_bubble_message')),
    );
    expect(bubbleMessage.softWrap, isFalse);
    expect(bubbleMessage.overflow, TextOverflow.visible);
    expect(skipped, isFalse);
  });

  testWidgets('taps highlighted family hotspot without family preview', (
    tester,
  ) async {
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
    expect(_guideBubbleText(tester), '点击这里管理\n家庭成员');
    expect(find.byKey(const ValueKey('home_guide_preview')), findsNothing);
    expect(find.byKey(const ValueKey('home_guide_finger')), findsOneWidget);
    expect(find.text('爸爸'), findsNothing);
    expect(find.text('妈妈'), findsNothing);
    expect(find.text('哥哥'), findsNothing);
    expect(find.text('妹妹'), findsNothing);
    expect(
      find.byKey(const ValueKey('home_guide_companion_pet')),
      findsNothing,
    );

    final fingerRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_finger')),
    );
    await tester.pump(const Duration(milliseconds: 230));
    final pressedFingerRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_finger')),
    );
    final fingertip = _fingerTipFor(fingerRect);
    final pressedFingertip = _fingerTipFor(pressedFingerRect);
    final bubbleRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble')),
    );
    final bubbleTextRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble_message')),
    );
    final targetSafeRect = const Rect.fromLTWH(280, 210, 64, 64).inflate(32);
    expect(fingertip.dx, closeTo(342, 1));
    expect(fingertip.dy, closeTo(272, 1));
    expect(pressedFingertip.dx, closeTo(fingertip.dx, 1));
    expect(pressedFingertip.dy, closeTo(fingertip.dy, 1));
    _expectBubbleBesideFinger(bubbleRect, fingerRect);
    expect(bubbleRect.contains(targetSafeRect.center), isFalse);
    expect(
      _isTextCenteredInBubble(
        bubbleRect,
        bubbleTextRect,
        tailOnRight: _bubbleTailOnRight(bubbleRect, fingerRect),
      ),
      isTrue,
    );
  });

  testWidgets('renders pet guide without pet-detail preview content', (
    tester,
  ) async {
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
    expect(find.byKey(const ValueKey('home_guide_preview')), findsNothing);
    expect(find.byKey(const ValueKey('home_guide_finger')), findsOneWidget);
    expect(find.textContaining('LV'), findsNothing);
    expect(find.text('最近互动'), findsNothing);
    expect(find.text('整理书包 +10'), findsNothing);
    expect(find.text('喂宠物 +8'), findsNothing);
    expect(find.text('睡前阅读 +12'), findsNothing);
    expect(
      find.byKey(const ValueKey('home_guide_companion_pet')),
      findsNothing,
    );

    final bubbleRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble')),
    );
    final bubbleTextRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_bubble_message')),
    );
    final fingerRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_finger')),
    );
    final glowRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_target_glow')),
    );
    final fingertip = _fingerTipFor(fingerRect);
    final targetSafeRect = petAnchor.inflate(22);
    expect(bubbleRect.contains(targetSafeRect.center), isFalse);
    expect(
      _isTextCenteredInBubble(
        bubbleRect,
        bubbleTextRect,
        tailOnRight: _bubbleTailOnRight(bubbleRect, fingerRect),
      ),
      isTrue,
    );
    expect(glowRect.contains(petAnchor.topLeft), isTrue);
    expect(glowRect.contains(petAnchor.bottomRight), isTrue);
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
    _expectBubbleBesideFinger(bubbleRect, fingerRect);

    await tester.tapAt(const Offset(250, 520));
    expect(tapped, isFalse);
    await tester.tapAt(Offset(petAnchor.center.dx, petAnchor.bottom - 8));
    expect(tapped, isTrue);
    tapped = false;
    await tester.tapAt(petAnchor.center);
    expect(tapped, isTrue);
  });

  testWidgets('keeps full-screen scrim layer available during guide', (
    tester,
  ) async {
    _setSurface(tester, const Size(390, 720));

    Future<void> pumpGuide(
      HomeGuideStep step,
      Rect anchorRect,
      String targetAssetPath,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 720,
              child: HomeGuideOverlay(
                step: step,
                anchorRect: anchorRect,
                screenSize: const Size(390, 720),
                targetAssetPath: targetAssetPath,
                onHotspotTap: () {},
                onSkip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    await pumpGuide(
      HomeGuideStep.taskSticker,
      const Rect.fromLTWH(40, 80, 80, 72),
      'assets/images/ui/home/home_task_sticker_add.webp',
    );
    await pumpGuide(
      HomeGuideStep.familyFrame,
      const Rect.fromLTWH(280, 210, 64, 64),
      'assets/images/ui/home/home_family_photo_frame.webp',
    );
    await pumpGuide(
      HomeGuideStep.petArea,
      const Rect.fromLTWH(92, 452, 110, 90),
      'assets/images/pets/grow/turtle/baby/sleeping.webp',
    );

    expect(
      find.byKey(const ValueKey('home_guide_target_glow')),
      findsOneWidget,
    );
  });

  testWidgets('keeps full-screen guide scrim when target asset is provided', (
    tester,
  ) async {
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
              targetAssetPath:
                  'assets/images/ui/home/home_family_photo_frame.webp',
              onHotspotTap: () {},
              onSkip: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey('home_guide_target_glow')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home_guide_hotspot')), findsOneWidget);
  });

  testWidgets(
    'paints family guide scrim in full-screen bounds near right edge',
    (tester) async {
      var tapped = false;
      _setSurface(tester, const Size(390, 844));
      const familyAnchor = Rect.fromLTWH(316, 280, 47, 55);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: HomeGuideOverlay(
                step: HomeGuideStep.familyFrame,
                anchorRect: familyAnchor,
                screenSize: const Size(390, 844),
                targetAssetPath:
                    'assets/images/ui/home/home_family_photo_frame.webp',
                onHotspotTap: () => tapped = true,
                onSkip: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final glowRect = tester.getRect(
        find.byKey(const ValueKey('home_guide_target_glow')),
      );
      final hotspotRect = tester.getRect(
        find.byKey(const ValueKey('home_guide_hotspot')),
      );

      expect(glowRect, const Rect.fromLTWH(0, 0, 390, 844));
      expect(hotspotRect.contains(familyAnchor.center), isTrue);

      await tester.tapAt(familyAnchor.center);
      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'keeps family guide bubble compact on narrow real-phone viewport',
    (tester) async {
      _setSurface(tester, const Size(360, 780));
      const familyAnchor = Rect.fromLTWH(292, 258, 44, 52);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 780,
              child: HomeGuideOverlay(
                step: HomeGuideStep.familyFrame,
                anchorRect: familyAnchor,
                screenSize: const Size(360, 780),
                targetAssetPath:
                    'assets/images/ui/home/home_family_photo_frame.webp',
                onHotspotTap: () {},
                onSkip: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final bubbleRect = tester.getRect(
        find.byKey(const ValueKey('home_guide_bubble')),
      );
      final bubbleTextRect = tester.getRect(
        find.byKey(const ValueKey('home_guide_bubble_message')),
      );
      final fingerRect = tester.getRect(
        find.byKey(const ValueKey('home_guide_finger')),
      );

      expect(bubbleRect.width, lessThanOrEqualTo(224));
      expect(bubbleRect.right, lessThan(fingerRect.left));
      expect(bubbleRect.contains(familyAnchor.center), isFalse);
      expect(
        _isTextCenteredInBubble(
          bubbleRect,
          bubbleTextRect,
          tailOnRight: _bubbleTailOnRight(bubbleRect, fingerRect),
        ),
        isTrue,
      );
      expect(
        _isTextInsideBubble(
          bubbleRect,
          bubbleTextRect,
          tailOnRight: _bubbleTailOnRight(bubbleRect, fingerRect),
        ),
        isTrue,
      );
    },
  );

  testWidgets('renders shape fallback glow while target asset is unavailable', (
    tester,
  ) async {
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
              onHotspotTap: () {},
              onSkip: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    final glowRect = tester.getRect(
      find.byKey(const ValueKey('home_guide_target_glow')),
    );
    expect(glowRect, const Rect.fromLTWH(0, 0, 390, 720));
    expect(find.byKey(const ValueKey('home_guide_hotspot')), findsOneWidget);
  });
}

Offset _fingerTipFor(Rect fingerRect) {
  return fingerRect.topLeft +
      Offset(fingerRect.width * 0.235, fingerRect.height * 0.207);
}

Offset _bubbleTailPoint(Rect bubbleRect, {required bool tailOnRight}) {
  return Offset(
    tailOnRight ? bubbleRect.right : bubbleRect.left,
    bubbleRect.top + bubbleRect.height * 0.70,
  );
}

bool _bubbleTailOnRight(Rect bubbleRect, Rect fingerRect) {
  return bubbleRect.center.dx < fingerRect.center.dx;
}

void _expectBubbleBesideFinger(Rect bubbleRect, Rect fingerRect) {
  final fingertip = _fingerTipFor(fingerRect);
  final tailPoint = _bubbleTailPoint(
    bubbleRect,
    tailOnRight: _bubbleTailOnRight(bubbleRect, fingerRect),
  );
  expect(bubbleRect.contains(fingertip), isFalse);
  expect((tailPoint.dx - fingertip.dx).abs(), lessThanOrEqualTo(116));
  expect((tailPoint.dy - fingertip.dy).abs(), lessThanOrEqualTo(116));
}

String _guideBubbleText(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find.byKey(const ValueKey('home_guide_bubble_message')),
  );
  return richText.text.toPlainText();
}

bool _isTextCenteredInBubble(
  Rect bubble,
  Rect text, {
  required bool tailOnRight,
}) {
  final safeRect = _bubbleTextSafeRect(bubble, tailOnRight: tailOnRight);
  return (text.center.dx - safeRect.center.dx).abs() < 2 &&
      (text.center.dy - safeRect.center.dy).abs() < 2;
}

bool _isTextInsideBubble(Rect bubble, Rect text, {required bool tailOnRight}) {
  final safeRect = _bubbleTextSafeRect(bubble, tailOnRight: tailOnRight);
  return text.left >= safeRect.left - 1 &&
      text.top >= safeRect.top - 1 &&
      text.right <= safeRect.right + 1 &&
      text.bottom <= safeRect.bottom + 1;
}

Rect _bubbleTextSafeRect(Rect bubble, {required bool tailOnRight}) {
  final safeRect = Rect.fromLTRB(
    bubble.left + bubble.width * (tailOnRight ? 0.22 : 0.24),
    bubble.top + bubble.height * 0.22,
    bubble.right - bubble.width * (tailOnRight ? 0.28 : 0.22),
    bubble.bottom - bubble.height * 0.26,
  );
  return safeRect;
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
