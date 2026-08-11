import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/screens/home/about_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('about dialog shows version and four action rows', (
    tester,
  ) async {
    HomeAboutAction? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    selected = await showHomeAboutDialog(context);
                  },
                  child: const Text('open_about'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open_about'));
    await tester.pumpAndSettle();

    expect(find.textContaining('拾星小宠'), findsOneWidget);
    expect(find.textContaining('版本'), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('用户协议'), findsOneWidget);
    expect(find.text('联系客服'), findsOneWidget);
    expect(find.text('删除账号'), findsOneWidget);
    expect(find.bySemanticsLabel('返回'), findsOneWidget);

    await tester.tap(find.text('用户协议'));
    await tester.pumpAndSettle();

    expect(selected, HomeAboutAction.terms);
  });

  testWidgets('about dialog back button dismisses without action', (
    tester,
  ) async {
    var completed = false;
    HomeAboutAction? selected = HomeAboutAction.privacy;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    selected = await showHomeAboutDialog(context);
                    completed = true;
                  },
                  child: const Text('open_about'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open_about'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(selected, isNull);
  });
}
