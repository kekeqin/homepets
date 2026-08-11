import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/screens/home/edit_profile_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('edit profile dialog uses wood panel with fields and actions', (
    tester,
  ) async {
    EditProfileDialogResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showEditProfileDialog(
                      context,
                      publicId: 'ABC234',
                      initialNickname: '小明',
                    );
                  },
                  child: const Text('open_edit'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open_edit'));
    await tester.pumpAndSettle();

    expect(find.text('编辑资料'), findsOneWidget);
    expect(find.text('ABC234'), findsOneWidget);
    expect(find.text('昵称'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
    expect(find.bySemanticsLabel('返回'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '小红');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(result?.nickname, '小红');
    expect(result?.familyName, isNull);
  });

  testWidgets('edit profile dialog can cancel without result', (tester) async {
    var completed = false;
    EditProfileDialogResult? result = const EditProfileDialogResult(
      nickname: 'keep',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showEditProfileDialog(
                      context,
                      publicId: 'ABC234',
                      initialNickname: '小明',
                    );
                    completed = true;
                  },
                  child: const Text('open_edit'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open_edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
  });
}
