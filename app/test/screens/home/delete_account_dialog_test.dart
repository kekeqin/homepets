import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/screens/home/delete_account_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('delete account dialog shows risks, id field, and actions', (
    tester,
  ) async {
    var completed = false;
    var confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    confirmed = await showDeleteAccountDialog(
                      context,
                      expectedPublicId: 'ABC234',
                    );
                    completed = true;
                  },
                  child: const Text('open_delete'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open_delete'));
    await tester.pumpAndSettle();

    expect(find.text('删除账号'), findsOneWidget);
    expect(find.textContaining('无法再登录'), findsOneWidget);
    expect(find.textContaining('无法恢复'), findsOneWidget);
    expect(find.text('请输入专属 ID'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(confirmed, isFalse);
  });

  testWidgets('delete account dialog rejects mismatched public id', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    showDeleteAccountDialog(
                      context,
                      expectedPublicId: 'ABC234',
                    );
                  },
                  child: const Text('open_delete'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open_delete'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'WRONG1');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('专属 ID 不正确，请核对后再试'), findsOneWidget);
    expect(find.text('删除账号'), findsOneWidget);
  });
}
