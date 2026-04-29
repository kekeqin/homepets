import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/models/pet.dart';
import 'package:homepets/models/pet_artwork.dart';
import 'package:homepets/screens/family/models/family_member_view_data.dart';
import 'package:homepets/screens/family/widgets/family_member_card.dart';
import 'package:homepets/screens/family/widgets/family_member_grid.dart';

void main() {
  group('FamilyMemberGrid', () {
    testWidgets('shows four members and switches pages on swipe', (
      tester,
    ) async {
      final members = List<FamilyMemberViewData>.generate(
        5,
        (index) => FamilyMemberViewData(
          id: index + 1,
          nickname: 'member-${index + 1}',
          role: 'member',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 390,
                child: FamilyMemberGrid(
                  members: members,
                  entryAnimation: const AlwaysStoppedAnimation<double>(1),
                  canAddMembers: true,
                  onAddMemberTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FamilyMemberCard), findsNWidgets(4));
      expect(find.text('member-1'), findsOneWidget);
      expect(find.text('member-4'), findsOneWidget);
      expect(find.text('member-5'), findsNothing);
      expect(find.byKey(const Key('family_member_grid_prev')), findsNothing);
      expect(find.byKey(const Key('family_member_grid_next')), findsNothing);
      expect(
        find.byKey(const Key('family_member_grid_page_dots')),
        findsOneWidget,
      );

      await tester.drag(
        find.byKey(const Key('family_member_grid_swipe_area')),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FamilyMemberCard), findsOneWidget);
      expect(find.text('member-1'), findsNothing);
      expect(find.text('member-2'), findsNothing);
      expect(find.text('member-4'), findsNothing);
      expect(find.text('member-5'), findsOneWidget);
    });

    testWidgets('does not show page dots when there are four members', (
      tester,
    ) async {
      final members = List<FamilyMemberViewData>.generate(
        4,
        (index) => FamilyMemberViewData(
          id: index + 1,
          nickname: 'member-${index + 1}',
          role: 'member',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 390,
                child: FamilyMemberGrid(
                  members: members,
                  entryAnimation: const AlwaysStoppedAnimation<double>(1),
                  canAddMembers: true,
                  onAddMemberTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FamilyMemberCard), findsNWidgets(4));
      expect(
        find.byKey(const Key('family_member_grid_page_dots')),
        findsNothing,
      );
    });

    testWidgets('taps pet avatar to trigger pet detail callback', (
      tester,
    ) async {
      var tapped = false;
      final pet = Pet(
        id: 10,
        name: 'buddy',
        petType: 'cat',
        petForm: 'pet',
        level: 2,
        experience: 30,
        ownerId: 1,
        familyId: 99,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              height: 220,
              child: FamilyMemberCard(
                member: FamilyMemberViewData(
                  id: 1,
                  nickname: 'member-1',
                  role: 'member',
                  petId: pet.id,
                  petType: pet.petType,
                  petForm: pet.petForm,
                  pet: pet,
                ),
                onPetTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('family_member_pet_button_1')));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('uses attached pet data for pet preview image', (tester) async {
      final pet = Pet(
        id: 42,
        name: 'buddy',
        petType: 'rabbit',
        petForm: 'pet',
        level: 2,
        experience: 30,
        ownerId: 1,
        familyId: 99,
      );
      final expectedAssetPath = petAvatarAssetPath(
        pet.petType,
        deterministicPetPoseIndex(pet.petType, pet.id),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              height: 220,
              child: FamilyMemberCard(
                member: FamilyMemberViewData(
                  id: 1,
                  nickname: 'member-1',
                  role: 'member',
                  petId: 7,
                  petType: 'dog',
                  petForm: pet.petForm,
                  pet: pet,
                ),
                onPetTap: () {},
              ),
            ),
          ),
        ),
      );

      final previewImage = tester.widget<Image>(
        find.descendant(
          of: find.byKey(const Key('family_member_pet_button_1')),
          matching: find.byType(Image),
        ),
      );
      final imageProvider = previewImage.image as AssetImage;

      expect(imageProvider.assetName, expectedAssetPath);
    });

    testWidgets('taps avatar edit badge to trigger avatar edit callback', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              height: 220,
              child: FamilyMemberCard(
                member: const FamilyMemberViewData(
                  id: 7,
                  nickname: 'member-7',
                  role: 'member',
                ),
                onAvatarEditTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('family_member_avatar_edit_button_7')),
      );
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('long presses member card to trigger delete callback', (
      tester,
    ) async {
      var triggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              height: 220,
              child: FamilyMemberCard(
                member: const FamilyMemberViewData(
                  id: 8,
                  nickname: 'member-8',
                  role: 'member',
                ),
                onLongPress: () => triggered = true,
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(FamilyMemberCard));
      await tester.pump();

      expect(triggered, isTrue);
    });
  });
}
