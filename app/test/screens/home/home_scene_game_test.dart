import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/screens/home/game/home_scene_game.dart';
import 'package:homepets/screens/home/game/home_scene_layout.dart';

const _staticHomePetAssetPaths = <String>[
  'images/pets/grow/cat/growing/lying.png',
  'images/pets/grow/cat/growing/sitting.png',
  'images/pets/grow/cat/growing/sleeping.png',
  'images/pets/grow/dog/growing/lying.png',
  'images/pets/grow/dog/growing/sitting.png',
  'images/pets/grow/dog/growing/sleeping.png',
  'images/pets/grow/hamster/growing/standing.png',
  'images/pets/grow/hamster/growing/sitting.png',
  'images/pets/grow/hamster/growing/sleeping.png',
  'images/pets/grow/rabbit/growing/lying.png',
  'images/pets/grow/rabbit/growing/sitting.png',
  'images/pets/grow/rabbit/growing/sleeping.png',
  'images/pets/grow/turtle/growing/crawling.png',
  'images/pets/grow/turtle/growing/sitting.png',
  'images/pets/grow/turtle/growing/sleeping.png',
];

const _growthHomePetAssetPaths = <String>[
  'images/pets/grow/cat/baby/lying.png',
  'images/pets/grow/cat/baby/sitting.png',
  'images/pets/grow/cat/baby/stage.png',
  'images/pets/grow/cat/growing/lying.png',
  'images/pets/grow/cat/growing/sitting.png',
  'images/pets/grow/cat/growing/sleeping.png',
  'images/pets/grow/cat/companion/sitting.png',
  'images/pets/grow/cat/companion/stage.png',
  'images/pets/grow/cat/companion/stretching.png',
  'images/pets/grow/dog/baby/lying.png',
  'images/pets/grow/dog/baby/sitting.png',
  'images/pets/grow/dog/baby/sleeping.png',
  'images/pets/grow/dog/growing/lying.png',
  'images/pets/grow/dog/growing/sitting.png',
  'images/pets/grow/dog/growing/sleeping.png',
  'images/pets/grow/dog/companion/lying.png',
  'images/pets/grow/dog/companion/sitting.png',
  'images/pets/grow/dog/companion/stage.png',
  'images/pets/grow/hamster/baby/lying.png',
  'images/pets/grow/hamster/baby/sitting.png',
  'images/pets/grow/hamster/baby/sleeping.png',
  'images/pets/grow/hamster/growing/standing.png',
  'images/pets/grow/hamster/growing/sitting.png',
  'images/pets/grow/hamster/growing/sleeping.png',
  'images/pets/grow/hamster/companion/lying.png',
  'images/pets/grow/hamster/companion/sleeping.png',
  'images/pets/grow/hamster/companion/stage.png',
  'images/pets/grow/rabbit/baby/lying.png',
  'images/pets/grow/rabbit/baby/sleeping.png',
  'images/pets/grow/rabbit/baby/stage.png',
  'images/pets/grow/rabbit/growing/lying.png',
  'images/pets/grow/rabbit/growing/sitting.png',
  'images/pets/grow/rabbit/growing/sleeping.png',
  'images/pets/grow/rabbit/companion/lying.png',
  'images/pets/grow/rabbit/companion/stage.png',
  'images/pets/grow/rabbit/companion/stretching.png',
  'images/pets/grow/turtle/baby/crawling.png',
  'images/pets/grow/turtle/baby/sleeping.png',
  'images/pets/grow/turtle/baby/stage.png',
  'images/pets/grow/turtle/growing/crawling.png',
  'images/pets/grow/turtle/growing/sitting.png',
  'images/pets/grow/turtle/growing/sleeping.png',
  'images/pets/grow/turtle/companion/crawling.png',
  'images/pets/grow/turtle/companion/sleeping.png',
  'images/pets/grow/turtle/companion/waving.png',
];

const _transparentGrowthCanvasCropRects = <String, Rect>{
  'images/pets/grow/dog/baby/sleeping.png': Rect.fromLTWH(
    0.1469,
    0.2585,
    0.7275,
    0.4510,
  ),
  'images/pets/grow/hamster/companion/lying.png': Rect.fromLTWH(
    0.0760,
    0.1853,
    0.8171,
    0.6106,
  ),
  'images/pets/grow/hamster/companion/sleeping.png': Rect.fromLTWH(
    0.1022,
    0.1887,
    0.8003,
    0.5985,
  ),
  'images/pets/grow/rabbit/baby/lying.png': Rect.fromLTWH(
    0.2217,
    0.1794,
    0.6132,
    0.5845,
  ),
};

const _rightArmchairSitAssetPaths = <String>[
  'images/pets/grow/cat/growing/sitting.png',
  'images/pets/grow/dog/growing/sitting.png',
  'images/pets/grow/hamster/growing/sitting.png',
  'images/pets/grow/rabbit/growing/sitting.png',
  'images/pets/grow/turtle/growing/sitting.png',
];

Future<void> _expectTransparentImageCorners(String flameAssetPath) async {
  final bytes = await rootBundle.load('assets/$flameAssetPath');
  final codec = await instantiateImageCodec(bytes.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    expect(data, isNotNull, reason: flameAssetPath);
    final rgba = data!.buffer.asUint8List();

    int alphaAt(int x, int y) => rgba[((y * image.width + x) * 4) + 3];

    expect(alphaAt(0, 0), 0, reason: '$flameAssetPath top-left corner');
    expect(
      alphaAt(image.width - 1, 0),
      0,
      reason: '$flameAssetPath top-right corner',
    );
    expect(
      alphaAt(0, image.height - 1),
      0,
      reason: '$flameAssetPath bottom-left corner',
    );
    expect(
      alphaAt(image.width - 1, image.height - 1),
      0,
      reason: '$flameAssetPath bottom-right corner',
    );
  } finally {
    image.dispose();
    codec.dispose();
  }
}

Future<void> _expectVisiblePixelRatioAtLeast(
  String flameAssetPath,
  double minimumRatio,
) async {
  final bytes = await rootBundle.load('assets/$flameAssetPath');
  final codec = await instantiateImageCodec(bytes.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    expect(data, isNotNull, reason: flameAssetPath);
    final rgba = data!.buffer.asUint8List();

    var visiblePixels = 0;
    for (var index = 3; index < rgba.length; index += 4) {
      if (rgba[index] > 0) {
        visiblePixels += 1;
      }
    }

    expect(
      visiblePixels / (image.width * image.height),
      greaterThanOrEqualTo(minimumRatio),
      reason: flameAssetPath,
    );
  } finally {
    image.dispose();
    codec.dispose();
  }
}

Future<void> _expectSingleVisibleImageComponent(String flameAssetPath) async {
  final bytes = await rootBundle.load('assets/$flameAssetPath');
  final codec = await instantiateImageCodec(bytes.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    expect(data, isNotNull, reason: flameAssetPath);
    final rgba = data!.buffer.asUint8List();

    bool isVisibleIndex(int index) => rgba[(index * 4) + 3] > 0;

    final visited = List<bool>.filled(image.width * image.height, false);
    var componentCount = 0;
    for (var index = 0; index < visited.length; index++) {
      if (visited[index] || !isVisibleIndex(index)) {
        continue;
      }

      componentCount += 1;
      final stack = <int>[index];
      visited[index] = true;
      while (stack.isNotEmpty) {
        final current = stack.removeLast();
        final x = current % image.width;
        final y = current ~/ image.width;
        final neighbors = <int>[
          if (x > 0) current - 1,
          if (x < image.width - 1) current + 1,
          if (y > 0) current - image.width,
          if (y < image.height - 1) current + image.width,
        ];
        for (final neighbor in neighbors) {
          if (!visited[neighbor] && isVisibleIndex(neighbor)) {
            visited[neighbor] = true;
            stack.add(neighbor);
          }
        }
      }
    }

    expect(componentCount, 1, reason: flameAssetPath);
  } finally {
    image.dispose();
    codec.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeSceneGame', () {
    test('loads homepage sprite positions from JSON using center points', () {
      final layout = HomeSceneLayout.fromJson(const <String, dynamic>{
        'profiles': <String, dynamic>{
          'mobile': <String, dynamic>{
            'sprites': <String, dynamic>{
              'taskSticker': <String, dynamic>{
                'centerX': 0.30,
                'centerY': 0.20,
                'width': 0.10,
                'height': 0.08,
              },
            },
          },
        },
        'regions': <String, dynamic>{
          'rightArmchairFrontOccluder': <String, dynamic>{
            'centerX': 0.80,
            'centerY': 0.64,
            'width': 0.14,
            'height': 0.05,
          },
        },
      });

      final taskSticker = layout.sprite('mobile', 'taskSticker');
      final occluder = layout.region('rightArmchairFrontOccluder');

      expect(taskSticker?.centerX, 0.30);
      expect(taskSticker?.centerY, 0.20);
      expect(occluder?.width, 0.14);
    });

    test('bundled homepage layout asset is valid', () async {
      final layout = await HomeSceneLayout.load(bypassCache: true);

      expect(layout.sprite('mobile', 'taskSticker')?.centerX, 0.2955);
      expect(layout.sprite('tablet', 'settings')?.centerY, 0.3365);
      expect(layout.region('rightArmchairSideOccluder')?.height, 0.088);
    });

    test('loads homepage pet positions from JSON using center points', () {
      final positions = HomePetPositions.fromJson(const <String, dynamic>{
        'candidates': <Object>[
          <String, dynamic>{
            'name': 'test_slot',
            'centerX': 0.42,
            'centerY': 0.64,
            'widthScale': 0.9,
            'heightScale': 0.8,
            'preferRestPose': true,
            'contactShadow': <String, dynamic>{
              'widthFactor': 0.7,
              'heightFactor': 0.1,
              'centerYFactor': 0.95,
            },
          },
        ],
        'assignmentOrder': <int>[0],
      });

      final candidate = positions.candidates.single;

      expect(candidate.centerX, 0.42);
      expect(candidate.centerY, 0.64);
      expect(candidate.preferRestPose, isTrue);
      expect(candidate.contactShadow?.centerYFactor, 0.95);
      expect(positions.assignmentOrder, const <int>[0]);
    });

    test('bundled homepage pet positions asset is valid', () async {
      final positions = await HomePetPositions.load(bypassCache: true);

      expect(positions.candidates, hasLength(8));
      expect(positions.candidates.first.centerX, 0.315);
      expect(
        positions.candidates.every((candidate) => candidate.placementEnabled),
        isTrue,
      );
      expect(positions.assignmentOrder, const <int>[0, 1, 2, 3, 4, 5, 6, 7]);
    });

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

    test('exposes null guide anchors before scene components are loaded', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      game.onGameResize(Vector2(390, 844));

      expect(game.taskPanelOriginRect(), isNull);
      expect(game.familyPhotoRect(), isNull);
      expect(game.primaryPetRect(), isNull);
    });

    test('debug guide sprite rects resolve to real home targets', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);

      final taskRect = game.debugTaskNoteHomeRect(const Size(390, 844));
      final familyRect = game.debugFamilyPhotoHomeRect(const Size(390, 844));

      expect(taskRect, isNotNull);
      expect(familyRect, isNotNull);
      expect(taskRect!.left, closeTo(83, 2));
      expect(taskRect.top, closeTo(111, 2));
      expect(taskRect.width, closeTo(69, 2));
      expect(taskRect.height, closeTo(76, 2));
      expect(familyRect!.left, closeTo(316, 2));
      expect(familyRect.top, closeTo(280, 2));
      expect(familyRect.width, closeTo(47, 2));
      expect(familyRect.height, closeTo(55, 2));
    });

    test(
      'keeps primary pet rect at its real home placement for guide anchors',
      () {
        final game = HomeSceneGame(device: HomeSceneDevice.mobile);
        game.onGameResize(Vector2(390, 844));
        game.replacePetEntries(const <HomeScenePetSeed>[
          HomeScenePetSeed(petId: 7, petType: 'dog'),
        ]);

        final petRect = game.debugPetRects()[7]!;

        expect(petRect.left, inInclusiveRange(0, 1));
        expect(petRect.top, inInclusiveRange(0, 1));
        expect(petRect.right, inInclusiveRange(0, 1));
        expect(petRect.bottom, inInclusiveRange(0, 1));
        expect(petRect.width, greaterThan(0));
        expect(petRect.height, greaterThan(0));
      },
    );

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

    test('assigns pets only to the eight configured home positions', () {
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
      expect(candidateCount, 8);
      expect(
        assignments.values.toSet(),
        Set<int>.from(List<int>.generate(8, (index) => index)),
      );
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

    test('uses growth-stage homepage pet assets', () {
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
          expect(assetPath, startsWith('images/pets/grow/'));
          expect(assetPath, endsWith('.png'));
        }
      }
    });

    test('maps pet levels to baby, growing, and companion assets', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      game.replacePetEntries(const <HomeScenePetSeed>[
        HomeScenePetSeed(petId: 11, petType: 'dog', level: 1),
        HomeScenePetSeed(petId: 22, petType: 'dog', level: 2),
        HomeScenePetSeed(petId: 33, petType: 'dog', level: 3),
        HomeScenePetSeed(petId: 44, petType: 'dog', level: 4),
        HomeScenePetSeed(petId: 55, petType: 'dog', level: 5),
      ]);

      final poseVariants = game.debugPetPoseAssetVariants();

      expect(
        poseVariants[11]!.every((path) => path.contains('/baby/')),
        isTrue,
      );
      expect(
        poseVariants[22]!.every((path) => path.contains('/growing/')),
        isTrue,
      );
      expect(
        poseVariants[33]!.every((path) => path.contains('/growing/')),
        isTrue,
      );
      expect(
        poseVariants[44]!.every((path) => path.contains('/companion/')),
        isTrue,
      );
      expect(
        poseVariants[55]!.every((path) => path.contains('/companion/')),
        isTrue,
      );
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

    test('keeps cat and dog homepage poses on growth-stage pet assets', () {
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
        expect(assetPath, startsWith('images/pets/grow/'));
        expect(assetPath, anyOf(contains('/cat/'), contains('/dog/')));
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
      final restPetId = assignments.entries
          .singleWhere((entry) => entry.value == 0)
          .key;
      final armchairPetId = assignments.entries
          .singleWhere((entry) => entry.value == 1)
          .key;

      expect(
        currentAssets[restPetId],
        anyOf(contains('lying'), contains('sleep')),
      );
      expect(currentAssets[armchairPetId], isIn(poseVariants[armchairPetId]!));
      expect(
        poseVariants[armchairPetId],
        contains(anyOf(contains('sit'), contains('stand'), contains('stage'))),
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
      for (final assetPath in _growthHomePetAssetPaths) {
        expect(HomeSceneGame.debugHasHomePetScaleOverride(assetPath), isTrue);
      }
    });

    test('crops transparent growth canvases to visible pet artwork', () {
      for (final entry in _transparentGrowthCanvasCropRects.entries) {
        final cropRect = HomeSceneGame.debugPetCropRectForAssetPath(entry.key);

        expect(cropRect, isNotNull);
        expect(cropRect!.left, closeTo(entry.value.left, 0.0001));
        expect(cropRect.top, closeTo(entry.value.top, 0.0001));
        expect(cropRect.width, closeTo(entry.value.width, 0.0001));
        expect(cropRect.height, closeTo(entry.value.height, 0.0001));
        expect(
          cropRect.width * cropRect.height,
          lessThan(0.51),
          reason:
              '${entry.key} should not lay out from the full transparent canvas.',
        );
      }
    });

    test('uses a smaller home target area for hamster and turtle assets', () {
      expect(
        HomeSceneGame.debugHomePetTargetAreaForAssetPath(
          'images/pets/grow/hamster/growing/sitting.png',
        ),
        lessThan(
          HomeSceneGame.debugHomePetTargetAreaForAssetPath(
            'images/pets/grow/cat/growing/sitting.png',
          ),
        ),
      );
      expect(
        HomeSceneGame.debugHomePetTargetAreaForAssetPath(
          'images/pets/grow/turtle/growing/sleeping.png',
        ),
        lessThan(
          HomeSceneGame.debugHomePetTargetAreaForAssetPath(
            'images/pets/grow/rabbit/growing/sleeping.png',
          ),
        ),
      );
    });

    test('applies fixed visual size multipliers for pet growth stages', () {
      const slotSize = Size(69, 100);

      double visibleAreaFor(String assetPath) {
        final cropRect = HomeSceneGame.debugPetCropRectForAssetPath(assetPath);
        expect(cropRect, isNotNull, reason: assetPath);

        final renderSize = HomeSceneGame.debugPetRenderSize(
          assetPath: assetPath,
          slotSize: slotSize,
          sourceSize: cropRect!.size,
        );
        return renderSize.width * renderSize.height;
      }

      final babyArea = visibleAreaFor('images/pets/grow/dog/baby/lying.png');
      final growingArea = visibleAreaFor(
        'images/pets/grow/dog/growing/lying.png',
      );
      final companionArea = visibleAreaFor(
        'images/pets/grow/dog/companion/lying.png',
      );

      expect(math.sqrt(babyArea / growingArea), closeTo(0.85, 0.01));
      expect(math.sqrt(companionArea / growingArea), closeTo(1.18, 0.01));
    });

    test('uses act sequence frames for supported homepage pet poses', () {
      void expectBabyActFrames(String assetPath, String prefix) {
        final frames = HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          assetPath,
        );
        expect(frames, hasLength(35), reason: assetPath);
        expect(frames.first, 'images/pets/act/${prefix}_frame_01.png');
        expect(frames.last, 'images/pets/act/${prefix}_frame_35.png');
      }

      expectBabyActFrames(
        'images/pets/grow/cat/baby/lying.png',
        'cat_baby_lying',
      );
      expectBabyActFrames(
        'images/pets/grow/cat/baby/sitting.png',
        'cat_baby_sitting',
      );
      expectBabyActFrames(
        'images/pets/grow/cat/baby/stage.png',
        'cat_baby_stage',
      );
      expectBabyActFrames(
        'images/pets/grow/dog/baby/lying.png',
        'dog_baby_lying',
      );
      expectBabyActFrames(
        'images/pets/grow/dog/baby/sitting.png',
        'dog_baby_sitting',
      );
      expectBabyActFrames(
        'images/pets/grow/dog/baby/sleeping.png',
        'dog_baby_sleeping',
      );
      expectBabyActFrames(
        'images/pets/grow/hamster/baby/lying.png',
        'hamster_baby_lying',
      );
      expectBabyActFrames(
        'images/pets/grow/hamster/baby/sitting.png',
        'hamster_baby_sitting',
      );
      expectBabyActFrames(
        'images/pets/grow/hamster/baby/sleeping.png',
        'hamster_baby_sleeping',
      );
      expectBabyActFrames(
        'images/pets/grow/rabbit/baby/lying.png',
        'rabbit_baby_lying',
      );
      expectBabyActFrames(
        'images/pets/grow/rabbit/baby/sleeping.png',
        'rabbit_baby_sleeping',
      );
      expectBabyActFrames(
        'images/pets/grow/rabbit/baby/stage.png',
        'rabbit_baby_stage',
      );
      expectBabyActFrames(
        'images/pets/grow/turtle/baby/crawling.png',
        'turtle_baby_crawling',
      );
      expectBabyActFrames(
        'images/pets/grow/turtle/baby/sleeping.png',
        'turtle_baby_sleeping',
      );
      expectBabyActFrames(
        'images/pets/grow/turtle/baby/stage.png',
        'turtle_baby_stage',
      );

      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/cat/growing/sitting.png',
        ),
        hasLength(25),
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/cat/growing/sleeping.png',
        ).first,
        'images/pets/act/cat_sleep_frame_01.png',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/dog/growing/sitting.png',
        ).last,
        'images/pets/act/dog_sit_frame_25.png',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/dog/growing/sleeping.png',
        ),
        hasLength(25),
      );
      final List<String> hamsterStandFrames =
          HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
            'images/pets/grow/hamster/growing/standing.png',
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
          'images/pets/grow/hamster/growing/sitting.png',
        ).last,
        'images/pets/act/hamster_sit_frame_25.png',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/rabbit/growing/lying.png',
        ).first,
        'images/pets/act/rabbit_lying_frame_01.png',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/rabbit/growing/sitting.png',
        ).last,
        'images/pets/act/rabbit_sit_frame_25.png',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/rabbit/growing/sleeping.png',
        ),
        hasLength(25),
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/turtle/growing/crawling.png',
        ).first,
        'images/pets/act/turtle_lying_frame_01.png',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/turtle/growing/sitting.png',
        ).last,
        'images/pets/act/turtle_sit_frame_25.png',
      );
    });

    test('keeps homepage pet action frames under the act directory only', () {
      for (final assetPath in _growthHomePetAssetPaths) {
        final frames = HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          assetPath,
        );
        expect(
          frames.every((framePath) => framePath.startsWith('images/pets/act/')),
          isTrue,
          reason: assetPath,
        );
      }

      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/cat/growing/lying.png',
        ),
        isEmpty,
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/dog/growing/lying.png',
        ),
        isEmpty,
      );
    });

    test(
      'keeps baby action frames isolated after JSON sprite cuts',
      () async {
        const babyPoseAssetPaths = <String>[
          'images/pets/grow/cat/baby/lying.png',
          'images/pets/grow/cat/baby/sitting.png',
          'images/pets/grow/cat/baby/stage.png',
          'images/pets/grow/dog/baby/lying.png',
          'images/pets/grow/dog/baby/sitting.png',
          'images/pets/grow/dog/baby/sleeping.png',
          'images/pets/grow/hamster/baby/lying.png',
          'images/pets/grow/hamster/baby/sitting.png',
          'images/pets/grow/hamster/baby/sleeping.png',
          'images/pets/grow/rabbit/baby/lying.png',
          'images/pets/grow/rabbit/baby/sleeping.png',
          'images/pets/grow/rabbit/baby/stage.png',
          'images/pets/grow/turtle/baby/crawling.png',
          'images/pets/grow/turtle/baby/sleeping.png',
          'images/pets/grow/turtle/baby/stage.png',
        ];

        for (final poseAssetPath in babyPoseAssetPaths) {
          final frames = HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
            poseAssetPath,
          );
          for (final frameAssetPath in frames) {
            await _expectTransparentImageCorners(frameAssetPath);
            await _expectSingleVisibleImageComponent(frameAssetPath);
            await _expectVisiblePixelRatioAtLeast(frameAssetPath, 0.50);
          }
        }
      },
    );

    test('keeps idle motion actions enabled for growing-stage pet poses', () {
      final growingAssetPaths = _growthHomePetAssetPaths.where(
        (assetPath) => assetPath.contains('/growing/'),
      );

      for (final assetPath in growingAssetPaths) {
        expect(
          HomeSceneGame.debugHasIdleMotionActionsForAsset(assetPath),
          isTrue,
          reason: assetPath,
        );
      }

      expect(
        HomeSceneGame.debugHasIdleMotionActionsForAsset(
          'images/pets/grow/cat/baby/sitting.png',
        ),
        isFalse,
      );
      expect(
        HomeSceneGame.debugHasIdleMotionActionsForAsset(
          'images/pets/grow/dog/companion/sitting.png',
        ),
        isFalse,
      );
    });

    test('keeps a pause window between homepage pet act playbacks', () {
      final hamsterStandPauseRange =
          HomeSceneGame.debugAnimationPlaybackPauseRangeForAsset(
            'images/pets/grow/hamster/growing/standing.png',
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
        greaterThanOrEqualTo(3),
      );
    });

    test('does not resize pets by slot-specific pose exceptions', () {
      expect(
        HomeSceneGame.debugPlacementScaleAdjustmentForCandidateAsset(
          candidateIndex: 6,
          assetPath: 'images/pets/grow/hamster/growing/sleeping.png',
        ),
        1,
      );
      expect(
        HomeSceneGame.debugPlacementScaleAdjustmentForCandidateAsset(
          candidateIndex: 3,
          assetPath: 'images/pets/grow/cat/growing/sleeping.png',
        ),
        1,
      );
    });

    test('keeps perspective from changing pet size between slots', () {
      expect(HomeSceneGame.debugPerspectiveScaleForCandidate(6), 1);
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
        'images/pets/grow/rabbit/growing/sitting.png',
      );
      final catLyingCrop = HomeSceneGame.debugPetCropRectForAssetPath(
        'images/pets/grow/cat/growing/lying.png',
      );

      expect(rabbitSitCrop, isNotNull);
      expect(catLyingCrop, isNotNull);

      final rabbitSitSize = HomeSceneGame.debugPetRenderSize(
        assetPath: 'images/pets/grow/rabbit/growing/sitting.png',
        slotSize: slotSize,
        sourceSize: rabbitSitCrop!.size,
      );
      final catLyingSize = HomeSceneGame.debugPetRenderSize(
        assetPath: 'images/pets/grow/cat/growing/lying.png',
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

          if (assetPath.contains('/hamster/') ||
              assetPath.contains('/turtle/')) {
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

    test('keeps bottom-center marked pets visible above the bottom edge', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final rect = game.debugPetRectForCandidate(
        candidateIndex: 5,
        assetPath: 'images/pets/grow/cat/growing/lying.png',
      );

      expect(
        rect.width,
        greaterThan(0.10),
        reason: 'Bottom-center pets should still read clearly.',
      );
      expect(
        rect.bottom,
        greaterThan(0.86),
        reason: 'Bottom-center pets should sit near the marked lower position.',
      );
      expect(
        rect.bottom,
        lessThan(0.94),
        reason: 'Bottom-center pets should not sink into the bottom edge.',
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

      for (final candidateIndex in const <int>[0, 2, 3, 4, 5, 6, 7]) {
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
        game.debugPetRenderPriorityForCandidate(2),
        greaterThan(HomeSceneGame.debugSeatOccluderRenderPriority),
      );
      expect(
        game.debugPetRenderPriorityForCandidate(1),
        lessThan(HomeSceneGame.debugSeatOccluderRenderPriority),
      );
    });

    test('keeps right armchair sit pets centered on the cushion band', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final cushionRect = HomeSceneGame.debugRightArmchairSeatCushionRect;
      final occluderRect = HomeSceneGame.debugRightArmchairFrontOccluderRect;

      for (final assetPath in _rightArmchairSitAssetPaths) {
        final rect = game.debugPetRectForCandidate(
          candidateIndex: 1,
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
          candidateIndex: 1,
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
          candidateIndex: 1,
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
          greaterThan(0.0065),
          reason: 'Repeated rabbits should stay large enough to see clearly.',
        );
        expect(
          rect.bottom,
          lessThan(0.94),
          reason: 'Repeated rabbits should stay away from the bottom edge.',
        );
      }
    });
  });
}
