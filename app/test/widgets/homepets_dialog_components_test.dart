import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/widgets/app_modal_shell.dart';
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

  testWidgets('modal background tap dismisses outside aspect ratio panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  await showAppModalDialog<void>(
                    context: context,
                    barrierLabel: 'aspect_ratio_test_dialog',
                    pageBuilder: (dialogContext) {
                      return AppModalShell(
                        layout: const AppModalLayout(
                          mobileWidthFactor: 1.0,
                          mobileMaxWidth: 430,
                          mobileHeightFactor: 0.90,
                          mobileMaxHeight: 700,
                          tabletWidthFactor: 0.45,
                          tabletMaxWidth: 430,
                          tabletHeightFactor: 0.90,
                          tabletMaxHeight: 700,
                          contentAspectRatio: 1,
                        ),
                        minimumSafeArea: HomePetsDialogGutter.mediumInsets,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Center(
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height: constraints.maxWidth,
                                child: const ColoredBox(
                                  color: Colors.white,
                                  child: Center(child: Text('modal-body')),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                  dismissed = true;
                },
                child: const Text('open-aspect'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-aspect'));
    await tester.pumpAndSettle();

    expect(find.text('modal-body'), findsOneWidget);

    await tester.tapAt(const Offset(195, 760));
    await tester.pumpAndSettle();

    expect(find.text('modal-body'), findsNothing);
    expect(dismissed, isTrue);
  });
}
