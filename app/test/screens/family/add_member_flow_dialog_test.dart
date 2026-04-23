import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/screens/family/dialogs/add_member_flow_dialog.dart';

void main() {
  testWidgets('collects nickname, pet type, and pet name in one dialog', (
    tester,
  ) async {
    AddMemberFlowResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  result = await showAddMemberFlowDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('family_add_member_nickname_field')),
      '小宝',
    );

    await tester.tap(find.byKey(const Key('family_add_member_pet_type_dog')));
    await tester.pumpAndSettle();

    final petNameField = tester.widget<TextField>(
      find.byKey(const Key('family_add_member_pet_name_field')),
    );
    expect(petNameField.controller?.text, '小狗');

    await tester.enterText(
      find.byKey(const Key('family_add_member_pet_name_field')),
      '团团',
    );

    await tester.tap(find.byKey(const Key('family_add_member_submit_button')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result?.nickname, '小宝');
    expect(result?.petType, 'dog');
    expect(result?.petName, '团团');
  });
}
