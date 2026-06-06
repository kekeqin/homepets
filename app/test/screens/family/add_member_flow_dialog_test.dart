import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/models/pet_artwork.dart';
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
      '灏忓疂',
    );

    await tester.tap(find.byKey(const Key('family_add_member_pet_type_dog')));
    await tester.pumpAndSettle();

    final petNameField = tester.widget<TextField>(
      find.byKey(const Key('family_add_member_pet_name_field')),
    );
    expect(petNameField.controller?.text, '小狗');

    await tester.enterText(
      find.byKey(const Key('family_add_member_pet_name_field')),
      '鍥㈠洟',
    );

    await tester.tap(find.byKey(const Key('family_add_member_submit_button')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result?.nickname, '灏忓疂');
    expect(result?.petType, 'dog');
    expect(result?.petName, '鍥㈠洟');
  });

  testWidgets('collects pet type and pet name for an existing member', (
    tester,
  ) async {
    SelectPetFlowResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  result = await showSelectPetFlowDialog(
                    context,
                    memberName: '瀹堕暱',
                  );
                },
                child: const Text('open-select'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-select'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('family_add_member_pet_type_cat')));
    await tester.pumpAndSettle();

    final petNameField = tester.widget<TextField>(
      find.byKey(const Key('family_select_pet_name_field')),
    );
    expect(petNameField.controller?.text, '小猫');

    await tester.enterText(
      find.byKey(const Key('family_select_pet_name_field')),
      '绫崇背',
    );

    await tester.tap(find.byKey(const Key('family_select_pet_submit_button')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result?.petType, 'cat');
    expect(result?.petName, '绫崇背');
  });
  testWidgets('lays existing member pet choices in two compact rows on phone', (
    tester,
  ) async {
    _setSurface(tester, const Size(390, 844));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showSelectPetFlowDialog(context, memberName: 'parent');
                },
                child: const Text('open-select'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-select'));
    await tester.pumpAndSettle();

    final rows = <double>[];
    for (final petType in selectablePetTypes) {
      final rect = tester.getRect(
        find.byKey(Key('family_add_member_pet_type_$petType')),
      );
      if (!rows.any((top) => (top - rect.top).abs() < 4)) {
        rows.add(rect.top);
      }
    }

    expect(rows.length, 2);
    expect(
      tester
          .getRect(find.byKey(const Key('family_select_pet_submit_button')))
          .bottom,
      lessThan(844),
    );
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
