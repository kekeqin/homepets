import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/screens/family/models/family_member_view_data.dart';
import 'package:homepets/screens/family/widgets/family_member_grid.dart';

void main() {
  group('FamilyMemberGrid', () {
    testWidgets('shows four members by default and expands overflow on tap', (
      tester,
    ) async {
      final members = List<FamilyMemberViewData>.generate(
        5,
        (index) => FamilyMemberViewData(
          id: index + 1,
          nickname: '成员${index + 1}',
          role: 'member',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: FamilyMemberGrid(
                members: members,
                entryAnimation: const AlwaysStoppedAnimation<double>(1),
                onMemberTap: (_) {},
                canAddMembers: true,
                onAddMemberTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('成员1'), findsOneWidget);
      expect(find.text('成员2'), findsOneWidget);
      expect(find.text('成员3'), findsOneWidget);
      expect(find.text('成员4'), findsOneWidget);
      expect(find.text('成员5'), findsNothing);
      expect(find.text('展开剩余 1 位'), findsOneWidget);

      await tester.tap(find.text('展开剩余 1 位'));
      await tester.pumpAndSettle();

      expect(find.text('成员5'), findsOneWidget);
      expect(find.text('收起成员'), findsOneWidget);
    });

    testWidgets('does not show overflow toggle when there are four members', (
      tester,
    ) async {
      final members = List<FamilyMemberViewData>.generate(
        4,
        (index) => FamilyMemberViewData(
          id: index + 1,
          nickname: '成员${index + 1}',
          role: 'member',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: FamilyMemberGrid(
                members: members,
                entryAnimation: const AlwaysStoppedAnimation<double>(1),
                onMemberTap: (_) {},
                canAddMembers: true,
                onAddMemberTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('展开剩余 1 位'), findsNothing);
      expect(find.text('收起成员'), findsNothing);
    });
  });
}
