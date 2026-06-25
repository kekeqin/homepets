import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/screens/home/guide/home_guide_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('HomeGuideController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts from family frame for a new account without setup', () async {
      final preferences = await SharedPreferences.getInstance();
      final controller = HomeGuideController(
        preferences: preferences,
        scopeId: 'user_1_family_99',
      );

      final progress = controller.readProgress(
        const HomeGuideSnapshot(
          hasFamilyMembers: false,
          hasActiveTasks: false,
          hasCurrentUserPet: false,
          hasMembersMissingPets: false,
        ),
      );

      expect(progress.shouldShow, isTrue);
      expect(progress.currentStep, HomeGuideStep.familyFrame);
    });

    test('does not interrupt old users with a complete home state', () async {
      final preferences = await SharedPreferences.getInstance();
      final controller = HomeGuideController(
        preferences: preferences,
        scopeId: 'user_1_family_99',
      );

      final progress = controller.readProgress(
        const HomeGuideSnapshot(
          hasFamilyMembers: true,
          hasActiveTasks: true,
          hasCurrentUserPet: true,
          hasMembersMissingPets: false,
        ),
      );

      expect(progress.shouldShow, isFalse);
      expect(progress.completed, isTrue);
    });

    test(
      'keeps stored progress even after earlier business steps exist',
      () async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          'home_guide_v4_user_1_family_99_current_step',
          HomeGuideStep.petArea.storageValue,
        );
        final controller = HomeGuideController(
          preferences: preferences,
          scopeId: 'user_1_family_99',
        );

        final progress = controller.readProgress(
          const HomeGuideSnapshot(
            hasFamilyMembers: true,
            hasActiveTasks: true,
            hasCurrentUserPet: true,
            hasMembersMissingPets: false,
          ),
        );

        expect(progress.shouldShow, isTrue);
        expect(progress.currentStep, HomeGuideStep.petArea);
      },
    );

    test('persists skipped state', () async {
      final preferences = await SharedPreferences.getInstance();
      final controller = HomeGuideController(
        preferences: preferences,
        scopeId: 'user_1_family_99',
      );

      final skipped = await controller.skip();
      final progress = controller.readProgress(
        const HomeGuideSnapshot(
          hasFamilyMembers: false,
          hasActiveTasks: false,
          hasCurrentUserPet: false,
          hasMembersMissingPets: false,
        ),
      );

      expect(skipped.skipped, isTrue);
      expect(progress.shouldShow, isFalse);
      expect(progress.skipped, isTrue);
    });

    test('advances through steps without requiring a created task', () async {
      final preferences = await SharedPreferences.getInstance();
      final controller = HomeGuideController(
        preferences: preferences,
        scopeId: 'user_1_family_99',
      );
      const snapshot = HomeGuideSnapshot(
        hasFamilyMembers: true,
        hasActiveTasks: false,
        hasCurrentUserPet: true,
        hasMembersMissingPets: false,
      );

      final family = await controller.advance(
        HomeGuideStep.familyFrame,
        snapshot,
      );
      final pet = await controller.advance(
        HomeGuideStep.petArea,
        const HomeGuideSnapshot(
          hasFamilyMembers: true,
          hasActiveTasks: false,
          hasCurrentUserPet: true,
          hasMembersMissingPets: false,
        ),
      );
      final done = await controller.advance(
        HomeGuideStep.taskSticker,
        const HomeGuideSnapshot(
          hasFamilyMembers: true,
          hasActiveTasks: false,
          hasCurrentUserPet: true,
          hasMembersMissingPets: false,
        ),
      );

      expect(family.currentStep, HomeGuideStep.petArea);
      expect(pet.currentStep, HomeGuideStep.taskSticker);
      expect(done.completed, isTrue);
      expect(
        controller
            .readProgress(
              const HomeGuideSnapshot(
                hasFamilyMembers: true,
                hasActiveTasks: false,
                hasCurrentUserPet: true,
                hasMembersMissingPets: false,
              ),
            )
            .shouldShow,
        isFalse,
      );
    });

    test('keeps guide state scoped to account and family', () async {
      final preferences = await SharedPreferences.getInstance();
      final oldAccount = HomeGuideController(
        preferences: preferences,
        scopeId: 'user_1_family_99',
      );
      final newAccount = HomeGuideController(
        preferences: preferences,
        scopeId: 'user_2_family_100',
      );
      const completeSnapshot = HomeGuideSnapshot(
        hasFamilyMembers: true,
        hasActiveTasks: true,
        hasCurrentUserPet: true,
        hasMembersMissingPets: false,
      );

      await oldAccount.markCompleted();

      final oldProgress = oldAccount.readProgress(completeSnapshot);
      final newProgress = newAccount.readProgress(
        const HomeGuideSnapshot(
          hasFamilyMembers: true,
          hasActiveTasks: false,
          hasCurrentUserPet: false,
          hasMembersMissingPets: true,
        ),
      );

      expect(oldProgress.shouldShow, isFalse);
      expect(newProgress.shouldShow, isTrue);
      expect(newProgress.currentStep, HomeGuideStep.familyFrame);
    });

    test('member without pet sends user back to family frame', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'home_guide_v4_user_1_family_99_current_step',
        HomeGuideStep.taskSticker.storageValue,
      );
      final controller = HomeGuideController(
        preferences: preferences,
        scopeId: 'user_1_family_99',
      );

      final progress = controller.readProgress(
        const HomeGuideSnapshot(
          hasFamilyMembers: true,
          hasActiveTasks: false,
          hasCurrentUserPet: false,
          hasMembersMissingPets: true,
        ),
      );

      expect(progress.shouldShow, isTrue);
      expect(progress.currentStep, HomeGuideStep.familyFrame);
    });

    test('starts from family frame before task and pet steps', () async {
      final preferences = await SharedPreferences.getInstance();
      final controller = HomeGuideController(
        preferences: preferences,
        scopeId: 'user_1_family_99',
      );

      final progress = controller.readProgress(
        const HomeGuideSnapshot(
          hasFamilyMembers: true,
          hasActiveTasks: false,
          hasCurrentUserPet: true,
          hasMembersMissingPets: false,
        ),
      );

      expect(progress.shouldShow, isTrue);
      expect(progress.currentStep, HomeGuideStep.familyFrame);
    });

    test(
      'keeps pet area progress after task panel was opened without tasks',
      () async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          'home_guide_v4_user_1_family_99_current_step',
          HomeGuideStep.petArea.storageValue,
        );
        final controller = HomeGuideController(
          preferences: preferences,
          scopeId: 'user_1_family_99',
        );

        final progress = controller.readProgress(
          const HomeGuideSnapshot(
            hasFamilyMembers: true,
            hasActiveTasks: false,
            hasCurrentUserPet: true,
            hasMembersMissingPets: false,
          ),
        );

        expect(progress.shouldShow, isTrue);
        expect(progress.currentStep, HomeGuideStep.petArea);
      },
    );

    test('keeps stored family frame after family setup is fixed', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'home_guide_v4_user_1_family_99_current_step',
        HomeGuideStep.familyFrame.storageValue,
      );
      final controller = HomeGuideController(
        preferences: preferences,
        scopeId: 'user_1_family_99',
      );

      final progress = controller.readProgress(
        const HomeGuideSnapshot(
          hasFamilyMembers: true,
          hasActiveTasks: false,
          hasCurrentUserPet: true,
          hasMembersMissingPets: false,
        ),
      );

      expect(progress.shouldShow, isTrue);
      expect(progress.currentStep, HomeGuideStep.familyFrame);
    });

    test('marks completion paywall due only after guide completion', () async {
      final preferences = await SharedPreferences.getInstance();
      final controller = HomeGuideController(
        preferences: preferences,
        scopeId: 'user_1_family_99',
      );

      final done = await controller.advance(
        HomeGuideStep.petArea,
        const HomeGuideSnapshot(
          hasFamilyMembers: true,
          hasActiveTasks: true,
          hasCurrentUserPet: true,
          hasMembersMissingPets: false,
        ),
      );

      expect(done.completed, isTrue);
      expect(controller.shouldShowCompletionPaywall(), isTrue);

      await controller.markCompletionPaywallShown();

      expect(controller.shouldShowCompletionPaywall(), isFalse);
    });

    test(
      'does not mark completion paywall for existing complete homes',
      () async {
        final preferences = await SharedPreferences.getInstance();
        final controller = HomeGuideController(
          preferences: preferences,
          scopeId: 'user_1_family_99',
        );

        final progress = controller.readProgress(
          const HomeGuideSnapshot(
            hasFamilyMembers: true,
            hasActiveTasks: true,
            hasCurrentUserPet: true,
            hasMembersMissingPets: false,
          ),
        );

        expect(progress.completed, isTrue);
        expect(controller.shouldShowCompletionPaywall(), isFalse);
      },
    );

    test('does not mark completion paywall when guide is skipped', () async {
      final preferences = await SharedPreferences.getInstance();
      final controller = HomeGuideController(
        preferences: preferences,
        scopeId: 'user_1_family_99',
      );

      await controller.skip();

      expect(controller.shouldShowCompletionPaywall(), isFalse);
    });
  });
}
