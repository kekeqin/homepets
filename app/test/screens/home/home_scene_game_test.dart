import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/screens/home/game/home_scene_game.dart';

const _staticHomePetAssetPaths = <String>[
  'images/pets/pets/cat_lying.png',
  'images/pets/pets/cat_sit.png',
  'images/pets/pets/cat_sleep.png',
  'images/pets/pets/dog_lying.png',
  'images/pets/pets/dog_sit.png',
  'images/pets/pets/dog_sleep.png',
  'images/pets/pets/hamster_stand.png',
  'images/pets/pets/hamster_sit.png',
  'images/pets/pets/hamster_sleep.png',
  'images/pets/pets/rabbit_lying.png',
  'images/pets/pets/rabbit_sit.png',
  'images/pets/pets/rabbit_sleep.png',
  'images/pets/pets/turtle_lying.png',
  'images/pets/pets/turtle_sit.png',
  'images/pets/pets/turtle_sleep.png',
];

const _rightArmchairSitAssetPaths = <String>[
  'images/pets/pets/cat_sit.png',
  'images/pets/pets/dog_sit.png',
  'images/pets/pets/hamster_sit.png',
  'images/pets/pets/rabbit_sit.png',
  'images/pets/pets/turtle_sit.png',
];

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

    test('uses static homepage pet assets from the new asset set', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      game.replacePetEntries(const <HomeScenePetSeed>[
        HomeScenePetSeed(petId: 11, petType: 'cat'),
        HomeScenePetSeed(petId: 22, petType: 'dog'),
        HomeScenePetSeed(petId: 33, petType: 'hamster'),
        HomeScenePetSeed(petId: 44, petType: 'rabbit'),
        HomeScenePetSeed(petId: 55, petType: 'turtle'),
      ]);

      final poseVariants = game.debugPetPoseAssetVariants();
      expect(poseVariants.length, 5);

      for (final variants in poseVariants.values) {
        expect(variants, isNotEmpty);
        for (final assetPath in variants) {
          expect(assetPath, startsWith('images/pets/pets/'));
          expect(assetPath, endsWith('.png'));
        }
      }
    });

    test('keeps homepage pet asset paths stable across refreshes', () {
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
    });

    test('uses current homepage sprite asset for detail avatar', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      game.replacePetEntries(const <HomeScenePetSeed>[
        HomeScenePetSeed(petId: 11, petType: 'cat'),
        HomeScenePetSeed(petId: 22, petType: 'dog'),
        HomeScenePetSeed(petId: 33, petType: 'hamster'),
      ]);

      final currentAssets = game.debugCurrentPetPoseAssetPaths();
      final detailAssets = game.debugPetDetailAvatarAssetPaths();

      expect(detailAssets.length, currentAssets.length);
      for (final entry in currentAssets.entries) {
        expect(detailAssets[entry.key], 'assets/${entry.value}');
      }
    });

    test('keeps cat and dog homepage poses on static pet assets', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      game.replacePetEntries(const <HomeScenePetSeed>[
        HomeScenePetSeed(petId: 11, petType: 'cat'),
        HomeScenePetSeed(petId: 12, petType: 'dog'),
        HomeScenePetSeed(petId: 13, petType: 'cat'),
        HomeScenePetSeed(petId: 14, petType: 'dog'),
        HomeScenePetSeed(petId: 15, petType: 'cat'),
        HomeScenePetSeed(petId: 16, petType: 'dog'),
      ]);

      final currentAssets = game.debugCurrentPetPoseAssetPaths().values;
      for (final assetPath in currentAssets) {
        expect(assetPath, startsWith('images/pets/pets/'));
        expect(assetPath, anyOf(contains('cat_'), contains('dog_')));
      }
    });

    test('uses static sit and rest poses for preferred home slots', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      game.replacePetEntries(const <HomeScenePetSeed>[
        HomeScenePetSeed(petId: 101, petType: 'hamster'),
        HomeScenePetSeed(petId: 102, petType: 'rabbit'),
        HomeScenePetSeed(petId: 103, petType: 'turtle'),
        HomeScenePetSeed(petId: 104, petType: 'cat'),
        HomeScenePetSeed(petId: 105, petType: 'dog'),
        HomeScenePetSeed(petId: 106, petType: 'hamster'),
        HomeScenePetSeed(petId: 107, petType: 'dog'),
        HomeScenePetSeed(petId: 108, petType: 'cat'),
      ]);

      final assignments = game.debugPetCandidateAssignments();
      final currentAssets = game.debugCurrentPetPoseAssetPaths();
      final poseVariants = game.debugPetPoseAssetVariants();
      final bookshelfPetId = assignments.entries
          .singleWhere((entry) => entry.value == 8)
          .key;
      final armchairPetId = assignments.entries
          .singleWhere((entry) => entry.value == 9)
          .key;

      expect(
        currentAssets[bookshelfPetId],
        anyOf(contains('lying'), contains('sleep')),
      );
      expect(currentAssets[armchairPetId], isIn(poseVariants[armchairPetId]!));
      expect(
        poseVariants[armchairPetId],
        contains(anyOf(contains('sit'), contains('stand'))),
      );
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

    test('defines a home scale override for every homepage pose asset', () {
      for (final assetPath in _staticHomePetAssetPaths) {
        expect(HomeSceneGame.debugHasHomePetScaleOverride(assetPath), isTrue);
      }
    });

    test('uses a smaller home target area for hamster and turtle assets', () {
      expect(
        HomeSceneGame.debugHomePetTargetAreaForAssetPath(
          'images/pets/pets/hamster_sit.png',
        ),
        lessThan(
          HomeSceneGame.debugHomePetTargetAreaForAssetPath(
            'images/pets/pets/cat_sit.png',
          ),
        ),
      );
      expect(
        HomeSceneGame.debugHomePetTargetAreaForAssetPath(
          'images/pets/pets/turtle_sleep.png',
        ),
        lessThan(
          HomeSceneGame.debugHomePetTargetAreaForAssetPath(
            'images/pets/pets/rabbit_sleep.png',
          ),
        ),
      );
    });

    test('uses act sequence frames for homepage pet poses with new sheets', () {
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/pets/cat_sit.png',
        ),
        hasLength(25),
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/pets/cat_sleep.png',
        ).first,
        'images/pets/act/cat_sleep_frame_01.png',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/pets/dog_sit.png',
        ).last,
        'images/pets/act/dog_sit_frame_25.png',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/pets/dog_sleep.png',
        ),
        hasLength(25),
      );
      final List<String> hamsterStandFrames =
          HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
            'images/pets/pets/hamster_stand.png',
          );
      expect(hamsterStandFrames, hasLength(14));
      expect(
        hamsterStandFrames.first,
        'images/pets/act/hamster_stand_frame_01.png',
      );
      expect(
        hamsterStandFrames.last,
        'images/pets/act/hamster_stand_frame_24.png',
      );
      expect(
        hamsterStandFrames,
        isNot(contains('images/pets/act/hamster_stand_frame_09.png')),
      );
      expect(
        hamsterStandFrames,
        isNot(contains('images/pets/act/hamster_stand_frame_25.png')),
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/pets/hamster_sit.png',
        ).last,
        'images/pets/act/hamster_sit_frame_25.png',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/pets/rabbit_lying.png',
        ).first,
        'images/pets/act/rabbit_lying_frame_01.png',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/pets/rabbit_sit.png',
        ).last,
        'images/pets/act/rabbit_sit_frame_25.png',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/pets/rabbit_sleep.png',
        ),
        hasLength(25),
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/pets/turtle_lying.png',
        ).first,
        'images/pets/act/turtle_lying_frame_01.png',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/pets/turtle_sit.png',
        ).last,
        'images/pets/act/turtle_sit_frame_25.png',
      );
    });

    test('keeps a pause window between homepage pet act playbacks', () {
      final hamsterStandPauseRange =
          HomeSceneGame.debugAnimationPlaybackPauseRangeForAsset(
            'images/pets/pets/hamster_stand.png',
          );

      expect(hamsterStandPauseRange, hasLength(2));
      expect(hamsterStandPauseRange.first, greaterThan(3));
      expect(
        hamsterStandPauseRange.last,
        greaterThan(hamsterStandPauseRange.first),
      );
    });

    test('staggers the initial homepage pet act playback timing', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      game.replacePetEntries(const <HomeScenePetSeed>[
        HomeScenePetSeed(petId: 11, petType: 'hamster'),
        HomeScenePetSeed(petId: 22, petType: 'hamster'),
        HomeScenePetSeed(petId: 33, petType: 'rabbit'),
        HomeScenePetSeed(petId: 44, petType: 'cat'),
      ]);

      final initialDelays = game
          .debugPetInitialAnimationDelays()
          .values
          .toList();

      expect(initialDelays, hasLength(4));
      expect(initialDelays.every((delay) => delay > 0), isTrue);
      expect(
        initialDelays.map((delay) => delay.toStringAsFixed(2)).toSet().length,
        4,
      );
    });

    test('does not resize pets by slot-specific pose exceptions', () {
      expect(
        HomeSceneGame.debugPlacementScaleAdjustmentForCandidateAsset(
          candidateIndex: 8,
          assetPath: 'images/pets/pets/hamster_sleep.png',
        ),
        1,
      );
      expect(
        HomeSceneGame.debugPlacementScaleAdjustmentForCandidateAsset(
          candidateIndex: 3,
          assetPath: 'images/pets/pets/cat_sleep.png',
        ),
        1,
      );
    });

    test('keeps perspective from changing pet size between slots', () {
      expect(HomeSceneGame.debugPerspectiveScaleForCandidate(9), 1);
      expect(HomeSceneGame.debugPerspectiveScaleForCandidate(0), 1);
      expect(HomeSceneGame.debugPerspectiveScaleForCandidate(7), 1);
    });

    test('uses stronger ambient motion for near pets than far pets', () {
      final farMotion = HomeSceneGame.debugAmbientMotionValuesForDepth(0.44);
      final nearMotion = HomeSceneGame.debugAmbientMotionValuesForDepth(0.86);

      expect(farMotion.floatAmplitude, 0);
      expect(nearMotion.floatAmplitude, greaterThan(0));
      expect(
        nearMotion.breathAmplitude,
        greaterThan(farMotion.breathAmplitude),
      );
      expect(
        nearMotion.wobbleAmplitude,
        greaterThan(farMotion.wobbleAmplitude),
      );
    });

    test('uses actual source aspect ratios for home pet sizing', () {
      const slotSize = Size(69, 100);

      final rabbitSitCrop = HomeSceneGame.debugPetCropRectForAssetPath(
        'images/pets/pets/rabbit_sit.png',
      );
      final catLyingCrop = HomeSceneGame.debugPetCropRectForAssetPath(
        'images/pets/pets/cat_lying.png',
      );

      expect(rabbitSitCrop, isNotNull);
      expect(catLyingCrop, isNotNull);

      final rabbitSitSize = HomeSceneGame.debugPetRenderSize(
        assetPath: 'images/pets/pets/rabbit_sit.png',
        slotSize: slotSize,
        sourceSize: rabbitSitCrop!.size,
      );
      final catLyingSize = HomeSceneGame.debugPetRenderSize(
        assetPath: 'images/pets/pets/cat_lying.png',
        slotSize: slotSize,
        sourceSize: catLyingCrop!.size,
      );

      expect(rabbitSitSize.width, lessThan(rabbitSitSize.height));
      expect(catLyingSize.width, greaterThan(catLyingSize.height * 1.4));
    });

    test(
      'keeps regular pets similar while hamster and turtle stay slightly smaller',
      () {
        const slotSize = Size(69, 100);

        final regularAreas = <double>[];
        final compactAreas = <double>[];

        for (final assetPath in _staticHomePetAssetPaths) {
          final cropRect = HomeSceneGame.debugPetCropRectForAssetPath(
            assetPath,
          );
          expect(
            cropRect,
            isNotNull,
            reason: 'Missing crop rect for $assetPath',
          );

          final renderSize = HomeSceneGame.debugPetRenderSize(
            assetPath: assetPath,
            slotSize: slotSize,
            sourceSize: cropRect!.size,
          );
          final area = renderSize.width * renderSize.height;

          if (assetPath.contains('/hamster_') ||
              assetPath.contains('/turtle_')) {
            compactAreas.add(area);
          } else {
            regularAreas.add(area);
          }
        }

        final minRegularArea = regularAreas.reduce(math.min);
        final maxRegularArea = regularAreas.reduce(math.max);
        final averageRegularArea =
            regularAreas.reduce((left, right) => left + right) /
            regularAreas.length;
        final averageCompactArea =
            compactAreas.reduce((left, right) => left + right) /
            compactAreas.length;

        expect(maxRegularArea / minRegularArea, lessThan(1.08));
        expect(averageCompactArea, lessThan(averageRegularArea));
        expect(averageCompactArea, greaterThan(averageRegularArea * 0.72));
      },
    );

    test('static home pet poses stay inside the home scene bounds', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      game.replacePetEntries(const <HomeScenePetSeed>[
        HomeScenePetSeed(petId: 201, petType: 'cat'),
        HomeScenePetSeed(petId: 202, petType: 'dog'),
        HomeScenePetSeed(petId: 203, petType: 'hamster'),
        HomeScenePetSeed(petId: 204, petType: 'rabbit'),
        HomeScenePetSeed(petId: 205, petType: 'turtle'),
      ]);

      final poseVariantRects = game.debugPetPoseVariantRects();

      for (final rects in poseVariantRects.values) {
        expect(rects, isNotEmpty);

        for (final rect in rects) {
          expect(rect.left, greaterThanOrEqualTo(-0.0001));
          expect(rect.top, greaterThanOrEqualTo(-0.0001));
          expect(rect.right, lessThanOrEqualTo(1.0001));
          expect(rect.bottom, lessThanOrEqualTo(1.0001));
        }
      }
    });

    test('keeps lower bookshelf pets small and grounded near the rug', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final rect = game.debugPetRectForCandidate(
        candidateIndex: 8,
        assetPath: 'images/pets/pets/cat_lying.png',
      );

      expect(
        rect.width,
        greaterThan(0.10),
        reason: 'Lower bookshelf pets should still read clearly.',
      );
      expect(
        rect.bottom,
        greaterThan(0.64),
        reason: 'Lower bookshelf pets should sit down near the rug line.',
      );
      expect(
        rect.bottom,
        lessThan(0.67),
        reason: 'Lower bookshelf pets should not sink into the coffee table.',
      );
    });

    test('keeps settings gear seated on the bookshelf top', () {
      expect(
        HomeSceneGame.debugHomeSettingsGearRect,
        const Rect.fromLTWH(0.623, 0.315, 0.113, 0.043),
      );
    });

    test('keeps regular pet slots off the coffee table corner area', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final coffeeTableRect = HomeSceneGame.debugHomeCoffeeTableNoPetRect;

      for (final candidateIndex in const <int>[0, 1, 3, 4, 6, 7, 9]) {
        for (final assetPath in _staticHomePetAssetPaths) {
          final rect = game.debugPetRectForCandidate(
            candidateIndex: candidateIndex,
            assetPath: assetPath,
          );
          expect(
            coffeeTableRect.contains(rect.bottomCenter),
            isFalse,
            reason:
                '$assetPath candidate $candidateIndex should not stand on the coffee table.',
          );
        }
      }
    });

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

    test('keeps right armchair sit pets centered on the cushion band', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final cushionRect = HomeSceneGame.debugRightArmchairSeatCushionRect;
      final occluderRect = HomeSceneGame.debugRightArmchairFrontOccluderRect;

      for (final assetPath in _rightArmchairSitAssetPaths) {
        final rect = game.debugPetRectForCandidate(
          candidateIndex: 9,
          assetPath: assetPath,
        );

        expect(
          rect.center.dx,
          closeTo(cushionRect.center.dx, 0.018),
          reason:
              '$assetPath should sit in the center of the armchair cushion.',
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

    test('limits right armchair front-edge overlap to pet paws', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final occluderRect = HomeSceneGame.debugRightArmchairFrontOccluderRect;

      for (final assetPath in _rightArmchairSitAssetPaths) {
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
          lessThan(rect.height * 0.18),
          reason: '$assetPath is being covered too much by the armchair front.',
        );
      }
    });

    test('keeps right armchair corner from clipping seated pets', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final occluderRect = HomeSceneGame.debugRightArmchairSideOccluderRect;

      for (final assetPath in _rightArmchairSitAssetPaths) {
        final rect = game.debugPetRectForCandidate(
          candidateIndex: 9,
          assetPath: assetPath,
        );
        final horizontalOverlap = rect.right - occluderRect.left;

        expect(
          horizontalOverlap,
          lessThan(rect.width * 0.12),
          reason: '$assetPath should not be clipped by the armchair corner.',
        );
        expect(
          occluderRect.top,
          greaterThan(rect.top + (rect.height * 0.2)),
          reason: '$assetPath corner cover should start below the head.',
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

    test('keeps repeated rabbits assigned to clearly visible slots', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);

      game.replacePetEntries(const <HomeScenePetSeed>[
        HomeScenePetSeed(petId: 2, petType: 'turtle'),
        HomeScenePetSeed(petId: 3, petType: 'rabbit'),
        HomeScenePetSeed(petId: 7, petType: 'rabbit'),
        HomeScenePetSeed(petId: 9, petType: 'rabbit'),
        HomeScenePetSeed(petId: 11, petType: 'dog'),
        HomeScenePetSeed(petId: 13, petType: 'turtle'),
        HomeScenePetSeed(petId: 14, petType: 'hamster'),
      ]);

      final rects = game.debugPetRects();
      final assignments = game.debugPetCandidateAssignments();

      expect(rects.length, 7);
      expect(assignments.length, 7);
      expect(assignments.values.toSet().length, 7);

      for (final petId in const <int>[3, 7, 9]) {
        final rect = rects[petId]!;
        expect(
          rect.width * rect.height,
          greaterThan(0.009),
          reason: 'Repeated rabbits should stay large enough to see clearly.',
        );
        expect(
          rect.bottom,
          lessThan(0.90),
          reason: 'Repeated rabbits should stay away from the bottom edge.',
        );
      }
    });
  });
}
