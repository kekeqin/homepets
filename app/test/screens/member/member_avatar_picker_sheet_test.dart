import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/screens/member/widgets/member_avatar_picker_sheet.dart';
import 'package:pickstarpet/widgets/user_avatar.dart';

void main() {
  testWidgets('orders avatar options by adult men women boys and girls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    showMemberAvatarPickerSheet(
                      context,
                      nickname: '自己人',
                      initialAvatarValue: userDefaultAvatarAssetPath,
                    );
                  },
                  child: const Text('打开'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    final optionAssetPaths = tester
        .widgetList<CenteredAvatarAsset>(find.byType(CenteredAvatarAsset))
        .map((widget) => widget.assetPath)
        .skip(1)
        .toList();

    expect(optionAssetPaths, <String>[
      userDefaultAvatarAssetPath,
      userDadAvatarAssetPath,
      userMomAvatarAssetPath,
      userMomYellowAvatarAssetPath,
      userBoyAvatarAssetPath,
      userBoyGreenAvatarAssetPath,
      userGirlAvatarAssetPath,
      userGirlBobAvatarAssetPath,
    ]);
  });

  testWidgets('dismisses avatar picker when tapping outside the sheet', (
    tester,
  ) async {
    String? result = 'pending';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showMemberAvatarPickerSheet(
                      context,
                      nickname: '自己人',
                      initialAvatarValue: userDefaultAvatarAssetPath,
                    );
                  },
                  child: const Text('打开'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('更换头像'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('更换头像'), findsNothing);
    expect(result, userDefaultAvatarAssetPath);
  });
}
