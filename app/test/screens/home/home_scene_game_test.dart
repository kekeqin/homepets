import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/screens/home/game/home_scene_game.dart';

void main() {
  group('HomeSceneGame', () {
    test('follows mobile viewport size after resize', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      game.onGameResize(Vector2(1080, 2400));

      expect(game.camera.viewport.virtualSize.x, 1080);
      expect(game.camera.viewport.virtualSize.y, 2400);
    });

    test('follows tablet viewport size after resize', () {
      final game = HomeSceneGame(device: HomeSceneDevice.tablet);
      game.onGameResize(Vector2(2048, 2732));

      expect(game.camera.viewport.virtualSize.x, 2048);
      expect(game.camera.viewport.virtualSize.y, 2732);
    });

    test('limits tasks to twelve entries', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);

      for (var index = 0; index < HomeSceneGame.maxTaskCount; index++) {
        expect(game.addTaskItem('Task $index'), isTrue);
      }

      expect(game.taskCount, HomeSceneGame.maxTaskCount);
      expect(game.taskPageCount, 3);
      expect(game.addTaskItem('Task overflow'), isFalse);
    });

    test('caps replaced task entries at twelve', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);

      game.replaceTaskEntries(
        List<HomeSceneTaskSeed>.generate(
          HomeSceneGame.maxTaskCount + 2,
          (index) => HomeSceneTaskSeed(title: 'Task $index', points: 10),
        ),
      );

      expect(game.taskCount, HomeSceneGame.maxTaskCount);
      expect(game.taskPageCount, 3);
    });

    test('assigns unique candidate points while pets fit preset slots', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final candidateCount = game.debugPetCandidateCount;

      game.replacePetEntries(
        List<HomeScenePetSeed>.generate(
          candidateCount,
          (index) => HomeScenePetSeed(
            petId: index + 1,
            petType: index.isEven ? 'dog' : 'cat',
          ),
        ),
      );

      final assignments = game.debugPetCandidateAssignments();
      expect(assignments.length, candidateCount);
      expect(assignments.values.toSet().length, candidateCount);
    });

    test('does not assign pets to retired floor slots', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final candidateCount = game.debugPetCandidateCount;

      game.replacePetEntries(
        List<HomeScenePetSeed>.generate(
          candidateCount,
          (index) => HomeScenePetSeed(
            petId: index + 1,
            petType: index.isEven ? 'dog' : 'cat',
          ),
        ),
      );

      final assignments = game.debugPetCandidateAssignments();
      expect(assignments.values, isNot(contains(2)));
      expect(assignments.values, isNot(contains(5)));
    });

    test('keeps pet candidate assignments stable across refreshes', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final pets = <HomeScenePetSeed>[
        const HomeScenePetSeed(petId: 11, petType: 'dog'),
        const HomeScenePetSeed(petId: 22, petType: 'cat'),
        const HomeScenePetSeed(petId: 33, petType: 'dog'),
      ];

      game.replacePetEntries(pets);
      final firstAssignments = game.debugPetCandidateAssignments();

      game.replacePetEntries(pets.reversed.toList());
      final secondAssignments = game.debugPetCandidateAssignments();

      expect(secondAssignments, firstAssignments);
    });

    test(
      'cat and dog expose three home pose variants for UI-triggered switching',
      () {
        final game = HomeSceneGame(device: HomeSceneDevice.mobile);
        final petCount = game.debugPetCandidateCount;

        game.replacePetEntries(
          List<HomeScenePetSeed>.generate(
            petCount,
            (index) => HomeScenePetSeed(
              petId: index + 1,
              petType: index.isEven ? 'cat' : 'dog',
            ),
          ),
        );

        final poseVariants = game.debugPetPoseAssetVariants();
        final variantCounts = poseVariants.values
            .map((variants) => variants.length)
            .toList();

        expect(HomeSceneGame.debugUsesDynamicHomePoseSwitching('cat'), isTrue);
        expect(HomeSceneGame.debugUsesDynamicHomePoseSwitching('dog'), isTrue);
        expect(
          HomeSceneGame.debugUsesDynamicHomePoseSwitching('hamster'),
          isFalse,
        );
        expect(
          variantCounts.where((count) => count == 3).length,
          greaterThanOrEqualTo(1),
        );
        expect(
          variantCounts.where((count) => count == 1).length,
          greaterThanOrEqualTo(1),
        );
      },
    );

    test(
      'keeps current cat and dog poses stable until explicitly advanced',
      () {
        final game = HomeSceneGame(device: HomeSceneDevice.mobile);
        const pets = <HomeScenePetSeed>[
          HomeScenePetSeed(petId: 11, petType: 'cat'),
          HomeScenePetSeed(petId: 22, petType: 'dog'),
        ];

        game.replacePetEntries(pets);
        final firstAssets = game.debugCurrentPetPoseAssetPaths();

        game.replacePetEntries(pets);
        final secondAssets = game.debugCurrentPetPoseAssetPaths();

        expect(secondAssets, firstAssets);
      },
    );

    test('advances cat and dog poses only when explicitly requested', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final petCount = game.debugPetCandidateCount;

      game.replacePetEntries(
        List<HomeScenePetSeed>.generate(
          petCount,
          (index) => HomeScenePetSeed(
            petId: index + 1,
            petType: index.isEven ? 'cat' : 'dog',
          ),
        ),
      );

      final beforeAdvance = game.debugCurrentPetPoseAssetPaths();
      final changed = game.advanceDynamicHomePetPoses();
      final afterAdvance = game.debugCurrentPetPoseAssetPaths();
      final dynamicChanges = beforeAdvance.keys
          .map((petId) => afterAdvance[petId] != beforeAdvance[petId])
          .where((value) => value)
          .length;

      expect(changed, isTrue);
      expect(dynamicChanges, greaterThanOrEqualTo(1));
    });

    test('adds overflow pets with local jitter when candidates are full', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final petCount = game.debugPetCandidateCount + 2;

      game.replacePetEntries(
        List<HomeScenePetSeed>.generate(
          petCount,
          (index) => HomeScenePetSeed(
            petId: index + 1,
            petType: index.isEven ? 'dog' : 'cat',
          ),
        ),
      );

      final assignments = game.debugPetCandidateAssignments();
      final offsets = game.debugPetPlacementOffsets();

      expect(assignments.length, petCount);
      expect(offsets.length, petCount);
      expect(
        offsets.values.where((offset) => offset.dx != 0 || offset.dy != 0),
        isNotEmpty,
      );
    });

    test(
      'normalizes home pet render areas after trimming asset whitespace',
      () {
        const slotSize = Size(69, 100);
        const assetPaths = <String>[
          'images/pets/cat_lie.png',
          'images/pets/cat_sit.png',
          'images/pets/cat_sleep_clean.png',
          'images/pets/dog_lie.png',
          'images/pets/dog_sit.png',
          'images/pets/dog_sleep_clean.png',
          'images/pets/hamster_lie_.png',
          'images/pets/hamster_sit.png',
          'images/pets/hamster_sleep.png',
          'images/pets/rabbit_sit.png',
          'images/pets/rabbit_sleep.png',
          'images/pets/turtle_sleep.png',
        ];

        final renderAreas = assetPaths.map((assetPath) {
          final cropRect = HomeSceneGame.debugPetCropRectForAssetPath(
            assetPath,
          );
          expect(
            cropRect,
            isNotNull,
            reason: 'Missing crop rect for $assetPath',
          );

          final renderSize = HomeSceneGame.debugPetRenderSize(
            slotSize: slotSize,
            sourceSize: cropRect!.size,
          );
          return renderSize.width * renderSize.height;
        }).toList();

        final minArea = renderAreas.reduce(math.min);
        final maxArea = renderAreas.reduce(math.max);
        expect(maxArea / minArea, lessThan(1.01));
      },
    );

    test(
      'dynamic cat and dog pose variants stay inside the home scene bounds',
      () {
        final game = HomeSceneGame(device: HomeSceneDevice.mobile);
        final petCount = game.debugPetCandidateCount;

        game.replacePetEntries(
          List<HomeScenePetSeed>.generate(
            petCount,
            (index) => HomeScenePetSeed(
              petId: 101 + index,
              petType: index.isEven ? 'cat' : 'dog',
            ),
          ),
        );

        final poseVariantRects = game.debugPetPoseVariantRects();
        final rectVariantCounts = poseVariantRects.values
            .map((rects) => rects.length)
            .toList();
        expect(
          rectVariantCounts.where((count) => count == 3).length,
          greaterThanOrEqualTo(1),
        );
        expect(
          rectVariantCounts.where((count) => count == 1).length,
          greaterThanOrEqualTo(1),
        );

        for (final rects in poseVariantRects.values) {
          for (final rect in rects) {
            expect(rect.left, greaterThanOrEqualTo(-0.0001));
            expect(rect.top, greaterThanOrEqualTo(-0.0001));
            expect(rect.right, lessThanOrEqualTo(1.0001));
            expect(rect.bottom, lessThanOrEqualTo(1.0001));
          }
        }
      },
    );

    test('renders the floor armchair-adjacent pet above the seat front', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);

      expect(
        game.debugPetRenderPriorityForCandidate(1),
        greaterThan(HomeSceneGame.debugSeatOccluderRenderPriority),
      );
      expect(
        game.debugPetRenderPriorityForCandidate(9),
        lessThan(HomeSceneGame.debugSeatOccluderRenderPriority),
      );
    });

    test('keeps right armchair sit pets resting inside the cushion band', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final occluderRect = HomeSceneGame.debugRightArmchairFrontOccluderRect;

      for (final assetPath in const <String>[
        'images/pets/cat_sit.png',
        'images/pets/dog_sit.png',
        'images/pets/hamster_sit.png',
        'images/pets/rabbit_sit.png',
      ]) {
        final rect = game.debugPetRectForCandidate(
          candidateIndex: 9,
          assetPath: assetPath,
        );

        expect(
          rect.bottom,
          greaterThan(occluderRect.top),
          reason: '$assetPath should touch the armchair cushion.',
        );
        expect(
          rect.bottom,
          lessThan(occluderRect.bottom),
          reason: '$assetPath should not sink through the armchair front.',
        );
      }
    });

    test('limits right armchair front-edge overlap to the pet lower body', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final occluderRect = HomeSceneGame.debugRightArmchairFrontOccluderRect;

      for (final assetPath in const <String>[
        'images/pets/cat_sit.png',
        'images/pets/dog_sit.png',
        'images/pets/hamster_sit.png',
        'images/pets/rabbit_sit.png',
      ]) {
        final rect = game.debugPetRectForCandidate(
          candidateIndex: 9,
          assetPath: assetPath,
        );
        final overlapHeight = rect.bottom - occluderRect.top;

        expect(
          overlapHeight,
          greaterThan(0),
          reason: '$assetPath should still be seated behind the front edge.',
        );
        expect(
          overlapHeight,
          lessThan(rect.height * 0.25),
          reason: '$assetPath is being covered too much by the armchair front.',
        );
      }
    });

    test('keeps right armchair corner in front of the pet right flank', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final occluderRect = HomeSceneGame.debugRightArmchairSideOccluderRect;

      for (final assetPath in const <String>[
        'images/pets/cat_sit.png',
        'images/pets/dog_sit.png',
        'images/pets/hamster_sit.png',
        'images/pets/rabbit_sit.png',
      ]) {
        final rect = game.debugPetRectForCandidate(
          candidateIndex: 9,
          assetPath: assetPath,
        );
        final horizontalOverlap = rect.right - occluderRect.left;

        expect(
          horizontalOverlap,
          greaterThan(0),
          reason: '$assetPath should overlap the armchair right corner.',
        );
        expect(
          horizontalOverlap,
          lessThan(rect.width * 0.35),
          reason: '$assetPath is being covered too much at the right corner.',
        );
        expect(
          occluderRect.top,
          greaterThan(rect.top + (rect.height * 0.2)),
          reason: '$assetPath corner cover should start below the head.',
        );
        expect(
          occluderRect.top,
          lessThan(rect.bottom),
          reason: '$assetPath corner cover should intersect the pet body.',
        );
      }
    });

    test('keeps edge pets fully inside the home scene bounds', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final petCount = game.debugPetCandidateCount;

      game.replacePetEntries(
        List<HomeScenePetSeed>.generate(
          petCount,
          (index) => HomeScenePetSeed(petId: index + 1, petType: 'turtle'),
        ),
      );

      final rects = game.debugPetRects();
      expect(rects.length, petCount);

      for (final rect in rects.values) {
        expect(rect.left, greaterThanOrEqualTo(-0.0001));
        expect(rect.top, greaterThanOrEqualTo(-0.0001));
        expect(rect.right, lessThanOrEqualTo(1.0001));
        expect(rect.bottom, lessThanOrEqualTo(1.0001));
      }
    });
  });
}
