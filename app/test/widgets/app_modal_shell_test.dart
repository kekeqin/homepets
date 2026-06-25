import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/widgets/app_modal_shell.dart';

const _testLayout = AppModalLayout(
  mobileWidthFactor: 1,
  mobileMaxWidth: 390,
  mobileHeightFactor: 0.5,
  mobileMaxHeight: 300,
  tabletWidthFactor: 1,
  tabletMaxWidth: 390,
  tabletHeightFactor: 0.5,
  tabletMaxHeight: 300,
);

const _aspectBoundLayout = AppModalLayout(
  mobileWidthFactor: 1,
  mobileMaxWidth: 390,
  mobileHeightFactor: 0.5,
  mobileMaxHeight: 300,
  tabletWidthFactor: 1,
  tabletMaxWidth: 390,
  tabletHeightFactor: 0.5,
  tabletMaxHeight: 300,
  contentAspectRatio: 0.5,
);

void main() {
  testWidgets(
    'centers visible frame when sprite has asymmetric transparent insets',
    (tester) async {
      _setTestViewSize(tester);
      final panelKey = UniqueKey();

      await _pumpShell(
        tester,
        panelKey: panelKey,
        visibleFrame: const AppModalVisibleFrame(
          sourceWidth: 100,
          leftInset: 10,
          rightInset: 30,
        ),
      );

      final panelRect = tester.getRect(find.byKey(panelKey));
      final scaledLeftInset = panelRect.width * 10 / 100;
      final scaledRightInset = panelRect.width * 30 / 100;
      final visibleLeft = panelRect.left + scaledLeftInset;
      final visibleRight = panelRect.right - scaledRightInset;

      expect(visibleLeft, moreOrLessEquals(400 - visibleRight, epsilon: 0.01));
    },
  );

  testWidgets('centers visible frame when artwork overflows on the right', (
    tester,
  ) async {
    _setTestViewSize(tester);
    final panelKey = UniqueKey();

    await _pumpShell(
      tester,
      panelKey: panelKey,
      visibleFrame: const AppModalVisibleFrame(
        sourceWidth: 100,
        leftInset: 0,
        rightInset: -20,
      ),
    );

    final panelRect = tester.getRect(find.byKey(panelKey));
    final scaledRightOverflow = panelRect.width * 20 / 100;
    final visibleLeft = panelRect.left;
    final visibleRight = panelRect.right + scaledRightOverflow;

    expect(visibleLeft, moreOrLessEquals(400 - visibleRight, epsilon: 0.01));
  });

  testWidgets(
    'keeps visible frame centered when transparent insets fit inside gutters',
    (tester) async {
      _setTestViewSize(tester);
      final panelKey = UniqueKey();

      await _pumpShell(
        tester,
        panelKey: panelKey,
        visibleFrame: const AppModalVisibleFrame(
          sourceWidth: 100,
          leftInset: 2,
          rightInset: 8,
        ),
      );

      final panelRect = tester.getRect(find.byKey(panelKey));
      final scaledLeftInset = panelRect.width * 2 / 100;
      final scaledRightInset = panelRect.width * 8 / 100;
      final visibleLeft = panelRect.left + scaledLeftInset;
      final visibleRight = panelRect.right - scaledRightInset;

      expect(visibleLeft, moreOrLessEquals(400 - visibleRight, epsilon: 0.01));
    },
  );

  testWidgets('uses content aspect ratio to match the rendered modal width', (
    tester,
  ) async {
    _setTestViewSize(tester);
    final panelKey = UniqueKey();

    await _pumpShell(
      tester,
      panelKey: panelKey,
      layout: _aspectBoundLayout,
      visibleFrame: const AppModalVisibleFrame(
        sourceWidth: 100,
        leftInset: 0,
        rightInset: 0,
      ),
    );

    final panelRect = tester.getRect(find.byKey(panelKey));

    expect(panelRect.width, moreOrLessEquals(150, epsilon: 0.01));
    expect(panelRect.left, moreOrLessEquals(125, epsilon: 0.01));
    expect(panelRect.right, moreOrLessEquals(275, epsilon: 0.01));
  });
}

void _setTestViewSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Key panelKey,
  AppModalLayout layout = _testLayout,
  required AppModalVisibleFrame visibleFrame,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppModalShell(
          layout: layout,
          minimumSafeArea: const EdgeInsets.symmetric(horizontal: 20),
          visibleFrame: visibleFrame,
          child: Container(key: panelKey, height: 100, color: Colors.orange),
        ),
      ),
    ),
  );
}
