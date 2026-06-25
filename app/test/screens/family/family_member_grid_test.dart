import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/models/pet.dart';
import 'package:pickstarpet/models/pet_artwork.dart';
import 'package:pickstarpet/screens/family/models/family_member_view_data.dart';
import 'package:pickstarpet/screens/family/widgets/family_member_card.dart';
import 'package:pickstarpet/screens/family/widgets/family_member_grid.dart';

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
      expect(find.byKey(const Key('family_member_grid_prev')), findsOneWidget);
      expect(find.byKey(const Key('family_member_grid_next')), findsOneWidget);
      expect(
        find.byKey(const Key('family_member_grid_page_dots')),
        findsOneWidget,
      );
      expect(find.text('1 / 2 页'), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('family_member_grid_swipe_area')),
        const Offset(-200, 0),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('member-5'), findsOneWidget);
      expect(find.text('邀请成员'), findsNothing);
      expect(find.text('2 / 2 页'), findsOneWidget);
    });

    testWidgets('does not show invite page when there are four members', (
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
        findsOneWidget,
      );
      expect(find.text('1 / 1 页'), findsOneWidget);
      expect(find.byKey(const Key('family_member_grid_prev')), findsNothing);
      expect(find.byKey(const Key('family_member_grid_next')), findsNothing);

      await tester.drag(
        find.byKey(const Key('family_member_grid_swipe_area')),
        const Offset(-200, 0),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.text('邀请成员'), findsNothing);
      expect(find.text('1 / 1 页'), findsOneWidget);
    });

    testWidgets('shows ascii member nicknames without replacing them', (
      tester,
    ) async {
      const members = <FamilyMemberViewData>[
        FamilyMemberViewData(id: 1, nickname: 'Alice', role: 'member'),
        FamilyMemberViewData(id: 2, nickname: 'Bob', role: 'member'),
        FamilyMemberViewData(id: 3, nickname: 'Cici', role: 'member'),
        FamilyMemberViewData(id: 4, nickname: 'Dada', role: 'member'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
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
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Cici'), findsOneWidget);
      expect(find.text('Dada'), findsOneWidget);
      expect(find.text('妈妈'), findsNothing);
      expect(find.text('小宝'), findsNothing);
      expect(find.text('爸爸'), findsNothing);
      expect(find.text('奶奶'), findsNothing);
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

    testWidgets('taps missing pet footer to trigger select pet callback', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              height: 220,
              child: FamilyMemberGrid(
                members: const <FamilyMemberViewData>[
                  FamilyMemberViewData(
                    id: 11,
                    nickname: 'owner',
                    role: 'admin',
                    needsPetSelection: true,
                  ),
                ],
                entryAnimation: const AlwaysStoppedAnimation<double>(1),
                canAddMembers: true,
                onAddMemberTap: () {},
                onMissingPetTap: (_) => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('family_member_missing_pet_button_11')),
      );
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
      final expectedAssetPath = defaultGrowthPetDetailAvatarAssetPath(
        pet.petType,
        pet.level,
        pet.id,
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
      expect(find.text('buddy'), findsOneWidget);
      expect(find.text('糯米'), findsNothing);
    });

    testWidgets('uses provided homepage pet avatar path when available', (
      tester,
    ) async {
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
      const homeAssetPath =
          'assets/images/pets/grow/rabbit/growing/sleeping.png';
      Pet? tappedPet;
      String? tappedAvatarAssetPath;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              height: 220,
              child: FamilyMemberGrid(
                members: <FamilyMemberViewData>[
                  FamilyMemberViewData(
                    id: 1,
                    nickname: 'member-1',
                    role: 'member',
                    petId: 7,
                    petType: pet.petType,
                    petForm: pet.petForm,
                    pet: pet,
                  ),
                ],
                petAvatarAssetPathsById: const <int, String>{42: homeAssetPath},
                entryAnimation: const AlwaysStoppedAnimation<double>(1),
                canAddMembers: true,
                onAddMemberTap: () {},
                onPetTap: (selectedPet, avatarAssetPath) {
                  tappedPet = selectedPet;
                  tappedAvatarAssetPath = avatarAssetPath;
                },
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

      expect(imageProvider.assetName, homeAssetPath);

      await tester.tap(find.byKey(const Key('family_member_pet_button_1')));
      await tester.pump();

      expect(tappedPet, same(pet));
      expect(tappedAvatarAssetPath, homeAssetPath);
    });

    testWidgets(
      'passes fallback pet avatar path to detail callback without homepage map',
      (tester) async {
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
        final expectedAssetPath = defaultGrowthPetDetailAvatarAssetPath(
          pet.petType,
          pet.level,
          pet.id,
        );
        Pet? tappedPet;
        String? tappedAvatarAssetPath;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 220,
                height: 220,
                child: FamilyMemberGrid(
                  members: <FamilyMemberViewData>[
                    FamilyMemberViewData(
                      id: 1,
                      nickname: 'member-1',
                      role: 'member',
                      petId: pet.id,
                      petType: pet.petType,
                      petForm: pet.petForm,
                      pet: pet,
                    ),
                  ],
                  entryAnimation: const AlwaysStoppedAnimation<double>(1),
                  canAddMembers: true,
                  onAddMemberTap: () {},
                  onPetTap: (selectedPet, avatarAssetPath) {
                    tappedPet = selectedPet;
                    tappedAvatarAssetPath = avatarAssetPath;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('family_member_pet_button_1')));
        await tester.pump();

        expect(tappedPet, same(pet));
        expect(tappedAvatarAssetPath, expectedAssetPath);
      },
    );

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
