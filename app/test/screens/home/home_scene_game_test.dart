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

    test(
      'uses one static homepage pet asset per pet from the new asset set',
      () {
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
          expect(variants, hasLength(1));
          expect(variants.single, startsWith('images/pets/pets/'));
          expect(variants.single, endsWith('.png'));
        }
      },
    );

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

    test('keeps cat and dog off lying poses on the homepage', () {
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
      expect(
        currentAssets.where(
          (assetPath) =>
              assetPath.contains('cat_lying') ||
              assetPath.contains('dog_lying'),
        ),
        isEmpty,
      );
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
      expect(
        currentAssets[armchairPetId],
        anyOf(contains('sit'), contains('stand')),
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

    test('keeps dog sit more restrained than cat and rabbit sit poses', () {
      expect(
        HomeSceneGame.debugHomePetScaleForAssetPath(
          'images/pets/pets/dog_sit.png',
        ),
        lessThan(
          HomeSceneGame.debugHomePetScaleForAssetPath(
            'images/pets/pets/cat_sit.png',
          ),
        ),
      );
      expect(
        HomeSceneGame.debugHomePetScaleForAssetPath(
          'images/pets/pets/dog_sit.png',
        ),
        lessThan(
          HomeSceneGame.debugHomePetScaleForAssetPath(
            'images/pets/pets/rabbit_sit.png',
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

    test('boosts hamster scale when resting on the bookshelf slot', () {
      expect(
        HomeSceneGame.debugPlacementScaleAdjustmentForCandidateAsset(
          candidateIndex: 8,
          assetPath: 'images/pets/pets/hamster_sleep.png',
        ),
        greaterThan(1),
      );
      expect(
        HomeSceneGame.debugPlacementScaleAdjustmentForCandidateAsset(
          candidateIndex: 8,
          assetPath: 'images/pets/pets/rabbit_sleep.png',
        ),
        1,
      );
    });

    test('boosts sleeping cat scale on front floor slots', () {
      expect(
        HomeSceneGame.debugPlacementScaleAdjustmentForCandidateAsset(
          candidateIndex: 3,
          assetPath: 'images/pets/pets/cat_sleep.png',
        ),
        greaterThan(1),
      );
      expect(
        HomeSceneGame.debugPlacementScaleAdjustmentForCandidateAsset(
          candidateIndex: 0,
          assetPath: 'images/pets/pets/cat_sleep.png',
        ),
        1,
      );
    });

    test(
      'applies perspective scaling so near slots render larger than far slots',
      () {
        expect(
          HomeSceneGame.debugPerspectiveScaleForCandidate(9),
          lessThan(HomeSceneGame.debugPerspectiveScaleForCandidate(0)),
        );
        expect(
          HomeSceneGame.debugPerspectiveScaleForCandidate(0),
          lessThan(HomeSceneGame.debugPerspectiveScaleForCandidate(7)),
        );
      },
    );

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
      expect(catLyingSize.width, greaterThan(catLyingSize.height * 2));
    });

    test(
      'preserves varied home pet render areas after trimming whitespace',
      () {
        const slotSize = Size(69, 100);

        final renderAreas = _staticHomePetAssetPaths.map((assetPath) {
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
          return renderSize.width * renderSize.height;
        }).toList();

        final minArea = renderAreas.reduce(math.min);
        final maxArea = renderAreas.reduce(math.max);
        expect(maxArea / minArea, greaterThan(1.25));
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
        expect(rects, hasLength(1));

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
        const Rect.fromLTWH(0.642, 0.324, 0.108, 0.040),
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
        expect(
          assignments[petId],
          isNot(anyOf(8, 9)),
          reason:
              'Repeated rabbits should not use the smallest/occluded slots.',
        );
      }
    });
  });
}
