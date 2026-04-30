import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/widgets/homepets_button.dart';
import 'package:homepets/widgets/homepets_dialog.dart';
import 'package:homepets/widgets/homepets_select_field.dart';

void main() {
  testWidgets('select field changes value and dialog returns selected result', (
    tester,
  ) async {
    int? result;
    int? selected = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await showHomePetsDialog<int>(
                    context: context,
                    barrierLabel: 'test_dialog',
                    title: '选择成员',
                    contentBuilder: (dialogContext) => StatefulBuilder(
                      builder: (context, setDialogState) {
                        return HomePetsSelectField<int>(
                          label: '完成成员',
                          value: selected,
                          options: const [
                            HomePetsSelectOption(value: 1, label: '温暖小家'),
                            HomePetsSelectOption(value: 2, label: '小宝'),
                          ],
                          onChanged: (value) {
                            setDialogState(() => selected = value);
                          },
                        );
                      },
                    ),
                    actionsBuilder: (dialogContext) => [
                      SizedBox(
                        width: 98,
                        child: HomePetsButton(
                          label: '取消',
                          variant: HomePetsButtonVariant.secondary,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ),
                      SizedBox(
                        width: 126,
                        child: HomePetsButton(
                          label: '确认完成',
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(selected),
                        ),
                      ),
                    ],
                  );
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

    expect(find.text('选择成员'), findsOneWidget);
    expect(find.text('完成成员'), findsOneWidget);
    expect(find.byType(HomePetsButton), findsNWidgets(2));

    await tester.tap(find.text('温暖小家'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('小宝').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('确认完成'));
    await tester.pumpAndSettle();

    expect(result, 2);
  });
}
