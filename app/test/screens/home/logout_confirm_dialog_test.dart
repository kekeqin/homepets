import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/screens/home/logout_confirm_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('logout confirm dialog shows message and actions', (
    tester,
  ) async {
    var completed = false;
    var confirmed = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    confirmed = await showLogoutConfirmDialog(context);
                    completed = true;
                  },
                  child: const Text('open_logout'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open_logout'));
    await tester.pumpAndSettle();

    expect(find.text('退出登录'), findsOneWidget);
    expect(find.textContaining('确定要退出'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确认退出'), findsOneWidget);
    expect(find.bySemanticsLabel('返回'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(confirmed, isFalse);
  });

  testWidgets('logout confirm dialog confirms exit', (tester) async {
    var confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    confirmed = await showLogoutConfirmDialog(context);
                  },
                  child: const Text('open_logout'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open_logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认退出'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });
}
