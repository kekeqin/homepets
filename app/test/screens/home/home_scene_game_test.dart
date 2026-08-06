import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/screens/home/game/home_scene_game.dart';
import 'package:pickstarpet/screens/home/game/home_scene_layout.dart';

const _staticHomePetAssetPaths = <String>[
  'images/pets/grow/cat/growing/lying.webp',
  'images/pets/grow/cat/growing/sitting.webp',
  'images/pets/grow/cat/growing/sleeping.webp',
  'images/pets/grow/dog/growing/lying.webp',
  'images/pets/grow/dog/growing/sitting.webp',
  'images/pets/grow/dog/growing/sleeping.webp',
  'images/pets/grow/hamster/growing/standing.webp',
  'images/pets/grow/hamster/growing/sitting.webp',
  'images/pets/grow/hamster/growing/sleeping.webp',
  'images/pets/grow/rabbit/growing/lying.webp',
  'images/pets/grow/rabbit/growing/sitting.webp',
  'images/pets/grow/rabbit/growing/sleeping.webp',
  'images/pets/grow/turtle/growing/crawling.webp',
  'images/pets/grow/turtle/growing/sitting.webp',
  'images/pets/grow/turtle/growing/sleeping.webp',
];

const _growthHomePetAssetPaths = <String>[
  'images/pets/grow/cat/baby/lying.webp',
  'images/pets/grow/cat/baby/sitting.webp',
  'images/pets/grow/cat/baby/stage.webp',
  'images/pets/grow/cat/growing/lying.webp',
  'images/pets/grow/cat/growing/sitting.webp',
  'images/pets/grow/cat/growing/sleeping.webp',
  'images/pets/grow/cat/companion/sitting.webp',
  'images/pets/grow/cat/companion/stage.webp',
  'images/pets/grow/cat/companion/stretching.webp',
  'images/pets/grow/dog/baby/lying.webp',
  'images/pets/grow/dog/baby/sitting.webp',
  'images/pets/grow/dog/baby/sleeping.webp',
  'images/pets/grow/dog/growing/lying.webp',
  'images/pets/grow/dog/growing/sitting.webp',
  'images/pets/grow/dog/growing/sleeping.webp',
  'images/pets/grow/dog/companion/lying.webp',
  'images/pets/grow/dog/companion/sitting.webp',
  'images/pets/grow/dog/companion/stage.webp',
  'images/pets/grow/hamster/baby/lying.webp',
  'images/pets/grow/hamster/baby/sitting.webp',
  'images/pets/grow/hamster/baby/sleeping.webp',
  'images/pets/grow/hamster/growing/standing.webp',
  'images/pets/grow/hamster/growing/sitting.webp',
  'images/pets/grow/hamster/growing/sleeping.webp',
  'images/pets/grow/hamster/companion/lying.webp',
  'images/pets/grow/hamster/companion/sleeping.webp',
  'images/pets/grow/hamster/companion/stage.webp',
  'images/pets/grow/rabbit/baby/lying.webp',
  'images/pets/grow/rabbit/baby/sleeping.webp',
  'images/pets/grow/rabbit/baby/stage.webp',
  'images/pets/grow/rabbit/growing/lying.webp',
  'images/pets/grow/rabbit/growing/sitting.webp',
  'images/pets/grow/rabbit/growing/sleeping.webp',
  'images/pets/grow/rabbit/companion/lying.webp',
  'images/pets/grow/rabbit/companion/stage.webp',
  'images/pets/grow/rabbit/companion/stretching.webp',
  'images/pets/grow/turtle/baby/crawling.webp',
  'images/pets/grow/turtle/baby/sleeping.webp',
  'images/pets/grow/turtle/baby/stage.webp',
  'images/pets/grow/turtle/growing/crawling.webp',
  'images/pets/grow/turtle/growing/sitting.webp',
  'images/pets/grow/turtle/growing/sleeping.webp',
  'images/pets/grow/turtle/companion/crawling.webp',
  'images/pets/grow/turtle/companion/sleeping.webp',
  'images/pets/grow/turtle/companion/waving.webp',
];

const _transparentGrowthCanvasCropRects = <String, Rect>{
  'images/pets/grow/dog/baby/sleeping.webp': Rect.fromLTWH(
    0.1469,
    0.2585,
    0.7275,
    0.4510,
  ),
  'images/pets/grow/hamster/companion/lying.webp': Rect.fromLTWH(
    0.0760,
    0.1853,
    0.8171,
    0.6106,
  ),
  'images/pets/grow/hamster/companion/sleeping.webp': Rect.fromLTWH(
    0.1022,
    0.1887,
    0.8003,
    0.5985,
  ),
  'images/pets/grow/rabbit/baby/lying.webp': Rect.fromLTWH(
    0.2217,
    0.1794,
    0.6132,
    0.5845,
  ),
};

const _rightArmchairSeatAssetPaths = <String>[
  'images/pets/grow/cat/baby/sitting.webp',
  'images/pets/grow/cat/baby/stage.webp',
  'images/pets/grow/cat/growing/sitting.webp',
  'images/pets/grow/cat/companion/sitting.webp',
  'images/pets/grow/cat/companion/stage.webp',
  'images/pets/grow/dog/baby/sitting.webp',
  'images/pets/grow/dog/growing/sitting.webp',
  'images/pets/grow/dog/companion/sitting.webp',
  'images/pets/grow/dog/companion/stage.webp',
  'images/pets/grow/hamster/baby/sitting.webp',
  'images/pets/grow/hamster/growing/standing.webp',
  'images/pets/grow/hamster/growing/sitting.webp',
  'images/pets/grow/hamster/companion/stage.webp',
  'images/pets/grow/rabbit/baby/stage.webp',
  'images/pets/grow/rabbit/growing/sitting.webp',
  'images/pets/grow/rabbit/companion/stage.webp',
  'images/pets/grow/turtle/baby/stage.webp',
  'images/pets/grow/turtle/growing/sitting.webp',
  'images/pets/grow/turtle/companion/waving.webp',
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
      expect(layout.region('sofaFrontOccluder')?.centerX, 0.2855);
      expect(layout.region('sofaFrontOccluder')?.height, 0.118);
      expect(layout.region('rightArmchairNearArmOccluder')?.centerX, 0.74);
      expect(layout.region('rightArmchairNearArmOccluder')?.height, 0.13);
      expect(layout.region('rightArmchairSideOccluder')?.centerX, 0.8275);
      expect(layout.region('rightArmchairSideOccluder')?.height, 0.142);
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
      expect(positions.candidates.first.centerY, 0.542);
      expect(positions.candidates.first.preferSitPose, isTrue);
      expect(positions.candidates[1].centerX, 0.76);
      expect(positions.candidates[1].centerY, 0.549);
      expect(positions.candidates[1].renderPriority, 4);
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

    test('covers narrow mobile viewport without side gutters', () {
      final backgroundRect = HomeSceneGame.debugBackgroundLayoutRect(
        device: HomeSceneDevice.mobile,
        sceneSize: const Size(945, 2048),
      );

      expect(backgroundRect.left, lessThanOrEqualTo(0));
      expect(backgroundRect.right, greaterThanOrEqualTo(945));
      expect(backgroundRect.top, lessThanOrEqualTo(0));
      expect(backgroundRect.bottom, greaterThanOrEqualTo(2048));
    });

    test('covers tablet viewport without letterboxing', () {
      final backgroundRect = HomeSceneGame.debugBackgroundLayoutRect(
        device: HomeSceneDevice.tablet,
        sceneSize: const Size(2048, 2732),
      );

      expect(backgroundRect.left, lessThanOrEqualTo(0));
      expect(backgroundRect.right, greaterThanOrEqualTo(2048));
      expect(backgroundRect.top, lessThanOrEqualTo(0));
      expect(backgroundRect.bottom, greaterThanOrEqualTo(2732));
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

    test('excludes decorative scene layers from tap hit testing', () {
      expect(
        HomeSceneGame.debugSceneComponentCanReceiveTap(hasTapCallback: false),
        isFalse,
      );
      expect(
        HomeSceneGame.debugSceneComponentCanReceiveTap(hasTapCallback: true),
        isTrue,
      );
    });

    test('debug guide sprite rects resolve to real home targets', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);

      final taskRect = game.debugTaskNoteHomeRect(const Size(390, 844));
      final familyRect = game.debugFamilyPhotoHomeRect(const Size(390, 844));

      expect(taskRect, isNotNull);
      expect(familyRect, isNotNull);
      expect(taskRect!.left, closeTo(80, 2));
      expect(taskRect.top, closeTo(102, 2));
      expect(taskRect.width, closeTo(71, 2));
      expect(taskRect.height, closeTo(78, 2));
      expect(familyRect!.left, closeTo(320, 2));
      expect(familyRect.top, closeTo(276, 2));
      expect(familyRect.width, closeTo(48, 2));
      expect(familyRect.height, closeTo(56, 2));
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

    test('keeps pet candidate assignments stable when pet data changes', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      game.replacePetEntries(const <HomeScenePetSeed>[
        HomeScenePetSeed(petId: 11, petType: 'dog', level: 1),
        HomeScenePetSeed(petId: 22, petType: 'cat', level: 1),
        HomeScenePetSeed(petId: 33, petType: 'rabbit', level: 1),
      ]);
      final firstAssignments = game.debugPetCandidateAssignments();

      game.replacePetEntries(const <HomeScenePetSeed>[
        HomeScenePetSeed(petId: 11, petType: 'dog', level: 4),
        HomeScenePetSeed(petId: 22, petType: 'cat', level: 2),
        HomeScenePetSeed(petId: 33, petType: 'rabbit', level: 3),
      ]);
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
          expect(assetPath, endsWith('.webp'));
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

    test('uses static sit poses for preferred home seat slots', () {
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
      final sofaPetId = assignments.entries
          .singleWhere((entry) => entry.value == 0)
          .key;
      final armchairPetId = assignments.entries
          .singleWhere((entry) => entry.value == 1)
          .key;

      expect(
        currentAssets[sofaPetId],
        anyOf(contains('sit'), contains('stand'), contains('stage')),
      );
      expect(currentAssets[armchairPetId], isIn(poseVariants[armchairPetId]!));
      expect(
        poseVariants[armchairPetId]!.every(
          (assetPath) =>
              assetPath.contains('sit') ||
              assetPath.contains('stand') ||
              assetPath.contains('stage') ||
              assetPath.contains('waving'),
        ),
        isTrue,
      );
    });

    test('keeps cat and dog companion stage poses off the red armchair', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      game.replacePetEntries(
        List<HomeScenePetSeed>.generate(
          game.debugPetCandidateCount,
          (index) => HomeScenePetSeed(
            petId: index + 201,
            petType: index.isEven ? 'cat' : 'dog',
            level: 4,
          ),
        ),
      );

      final assignments = game.debugPetCandidateAssignments();
      final armchairPetId = assignments.entries
          .singleWhere((entry) => entry.value == 1)
          .key;
      final armchairPoseVariants = game
          .debugPetPoseAssetVariants()[armchairPetId]!;

      expect(
        armchairPoseVariants,
        isNot(
          contains(
            anyOf(
              'images/pets/grow/cat/companion/stage.webp',
              'images/pets/grow/dog/companion/stage.webp',
            ),
          ),
        ),
      );
      expect(
        armchairPoseVariants,
        contains(
          anyOf(
            'images/pets/grow/cat/companion/sitting.webp',
            'images/pets/grow/dog/companion/sitting.webp',
          ),
        ),
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
          'images/pets/grow/hamster/growing/sitting.webp',
        ),
        lessThan(
          HomeSceneGame.debugHomePetTargetAreaForAssetPath(
            'images/pets/grow/cat/growing/sitting.webp',
          ),
        ),
      );
      expect(
        HomeSceneGame.debugHomePetTargetAreaForAssetPath(
          'images/pets/grow/turtle/growing/sleeping.webp',
        ),
        lessThan(
          HomeSceneGame.debugHomePetTargetAreaForAssetPath(
            'images/pets/grow/rabbit/growing/sleeping.webp',
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

      final babyArea = visibleAreaFor('images/pets/grow/dog/baby/lying.webp');
      final growingArea = visibleAreaFor(
        'images/pets/grow/dog/growing/lying.webp',
      );
      final companionArea = visibleAreaFor(
        'images/pets/grow/dog/companion/lying.webp',
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
        expect(frames.first, 'images/pets/act/${prefix}_frame_01.webp');
        expect(frames.last, 'images/pets/act/${prefix}_frame_35.webp');
      }

      expectBabyActFrames(
        'images/pets/grow/cat/baby/lying.webp',
        'cat_baby_lying',
      );
      expectBabyActFrames(
        'images/pets/grow/cat/baby/sitting.webp',
        'cat_baby_sitting',
      );
      expectBabyActFrames(
        'images/pets/grow/cat/baby/stage.webp',
        'cat_baby_stage',
      );
      expectBabyActFrames(
        'images/pets/grow/dog/baby/lying.webp',
        'dog_baby_lying',
      );
      expectBabyActFrames(
        'images/pets/grow/dog/baby/sitting.webp',
        'dog_baby_sitting',
      );
      expectBabyActFrames(
        'images/pets/grow/dog/baby/sleeping.webp',
        'dog_baby_sleeping',
      );
      expectBabyActFrames(
        'images/pets/grow/hamster/baby/lying.webp',
        'hamster_baby_lying',
      );
      expectBabyActFrames(
        'images/pets/grow/hamster/baby/sitting.webp',
        'hamster_baby_sitting',
      );
      expectBabyActFrames(
        'images/pets/grow/hamster/baby/sleeping.webp',
        'hamster_baby_sleeping',
      );
      expectBabyActFrames(
        'images/pets/grow/rabbit/baby/lying.webp',
        'rabbit_baby_lying',
      );
      expectBabyActFrames(
        'images/pets/grow/rabbit/baby/sleeping.webp',
        'rabbit_baby_sleeping',
      );
      expectBabyActFrames(
        'images/pets/grow/rabbit/baby/stage.webp',
        'rabbit_baby_stage',
      );
      expectBabyActFrames(
        'images/pets/grow/turtle/baby/crawling.webp',
        'turtle_baby_crawling',
      );
      expectBabyActFrames(
        'images/pets/grow/turtle/baby/sleeping.webp',
        'turtle_baby_sleeping',
      );
      expectBabyActFrames(
        'images/pets/grow/turtle/baby/stage.webp',
        'turtle_baby_stage',
      );

      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/cat/growing/sitting.webp',
        ),
        hasLength(25),
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/cat/growing/sleeping.webp',
        ).first,
        'images/pets/act/cat_sleep_frame_01.webp',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/dog/growing/sitting.webp',
        ).last,
        'images/pets/act/dog_sit_frame_25.webp',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/dog/growing/sleeping.webp',
        ),
        hasLength(25),
      );
      final List<String> hamsterStandFrames =
          HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
            'images/pets/grow/hamster/growing/standing.webp',
          );
      expect(hamsterStandFrames, hasLength(14));
      expect(
        hamsterStandFrames.first,
        'images/pets/act/hamster_stand_frame_01.webp',
      );
      expect(
        hamsterStandFrames.last,
        'images/pets/act/hamster_stand_frame_24.webp',
      );
      expect(
        hamsterStandFrames,
        isNot(contains('images/pets/act/hamster_stand_frame_09.webp')),
      );
      expect(
        hamsterStandFrames,
        isNot(contains('images/pets/act/hamster_stand_frame_25.webp')),
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/hamster/growing/sitting.webp',
        ).last,
        'images/pets/act/hamster_sit_frame_25.webp',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/rabbit/growing/lying.webp',
        ).first,
        'images/pets/act/rabbit_lying_frame_01.webp',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/rabbit/growing/sitting.webp',
        ).last,
        'images/pets/act/rabbit_sit_frame_25.webp',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/rabbit/growing/sleeping.webp',
        ),
        hasLength(25),
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/turtle/growing/crawling.webp',
        ).first,
        'images/pets/act/turtle_lying_frame_01.webp',
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/turtle/growing/sitting.webp',
        ).last,
        'images/pets/act/turtle_sit_frame_25.webp',
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
          'images/pets/grow/cat/growing/lying.webp',
        ),
        isEmpty,
      );
      expect(
        HomeSceneGame.debugAnimationFrameAssetPathsForAsset(
          'images/pets/grow/dog/growing/lying.webp',
        ),
        isEmpty,
      );
    });

    test('keeps baby action frames isolated after JSON sprite cuts', () async {
      const babyPoseAssetPaths = <String>[
        'images/pets/grow/cat/baby/lying.webp',
        'images/pets/grow/cat/baby/sitting.webp',
        'images/pets/grow/cat/baby/stage.webp',
        'images/pets/grow/dog/baby/lying.webp',
        'images/pets/grow/dog/baby/sitting.webp',
        'images/pets/grow/dog/baby/sleeping.webp',
        'images/pets/grow/hamster/baby/lying.webp',
        'images/pets/grow/hamster/baby/sitting.webp',
        'images/pets/grow/hamster/baby/sleeping.webp',
        'images/pets/grow/rabbit/baby/lying.webp',
        'images/pets/grow/rabbit/baby/sleeping.webp',
        'images/pets/grow/rabbit/baby/stage.webp',
        'images/pets/grow/turtle/baby/crawling.webp',
        'images/pets/grow/turtle/baby/sleeping.webp',
        'images/pets/grow/turtle/baby/stage.webp',
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
    });

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
          'images/pets/grow/cat/baby/sitting.webp',
        ),
        isFalse,
      );
      expect(
        HomeSceneGame.debugHasIdleMotionActionsForAsset(
          'images/pets/grow/dog/companion/sitting.webp',
        ),
        isFalse,
      );
    });

    test('keeps a pause window between homepage pet act playbacks', () {
      final hamsterStandPauseRange =
          HomeSceneGame.debugAnimationPlaybackPauseRangeForAsset(
            'images/pets/grow/hamster/growing/standing.webp',
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

    test('fits pets smaller on the right armchair seat slot', () {
      expect(
        HomeSceneGame.debugPlacementScaleAdjustmentForCandidateAsset(
          candidateIndex: 0,
          assetPath: 'images/pets/grow/rabbit/growing/sitting.webp',
        ),
        0.94,
      );
      expect(
        HomeSceneGame.debugPlacementScaleAdjustmentForCandidateAsset(
          candidateIndex: 1,
          assetPath: 'images/pets/grow/dog/baby/sitting.webp',
        ),
        0.94,
      );
      expect(
        HomeSceneGame.debugPlacementScaleAdjustmentForCandidateAsset(
          candidateIndex: 6,
          assetPath: 'images/pets/grow/hamster/growing/sleeping.webp',
        ),
        1,
      );
      expect(
        HomeSceneGame.debugPlacementScaleAdjustmentForCandidateAsset(
          candidateIndex: 3,
          assetPath: 'images/pets/grow/cat/growing/sleeping.webp',
        ),
        1,
      );
    });

    test('applies noticeable perspective scale between home slots', () {
      final sofaScale = HomeSceneGame.debugPerspectiveScaleForCandidate(0);
      final plantSideScale = HomeSceneGame.debugPerspectiveScaleForCandidate(6);
      final lowerRightScale = HomeSceneGame.debugPerspectiveScaleForCandidate(
        7,
      );

      expect(sofaScale, closeTo(0.962, 0.002));
      expect(plantSideScale, greaterThan(sofaScale));
      expect(lowerRightScale, greaterThan(plantSideScale));
      expect(lowerRightScale, closeTo(1.098, 0.002));
      expect(lowerRightScale, lessThanOrEqualTo(1.12));
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
        'images/pets/grow/rabbit/growing/sitting.webp',
      );
      final catLyingCrop = HomeSceneGame.debugPetCropRectForAssetPath(
        'images/pets/grow/cat/growing/lying.webp',
      );

      expect(rabbitSitCrop, isNotNull);
      expect(catLyingCrop, isNotNull);

      final rabbitSitSize = HomeSceneGame.debugPetRenderSize(
        assetPath: 'images/pets/grow/rabbit/growing/sitting.webp',
        slotSize: slotSize,
        sourceSize: rabbitSitCrop!.size,
      );
      final catLyingSize = HomeSceneGame.debugPetRenderSize(
        assetPath: 'images/pets/grow/cat/growing/lying.webp',
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
        assetPath: 'images/pets/grow/cat/growing/lying.webp',
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

    test('draws sofa pets above front backfills and under right armrest', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);

      expect(
        game.debugPetRenderPriorityForCandidate(0),
        greaterThan(HomeSceneGame.debugSeatBackfillRenderPriority),
      );
      expect(
        game.debugPetRenderPriorityForCandidate(2),
        greaterThan(HomeSceneGame.debugSeatOccluderRenderPriority),
      );
      expect(
        game.debugPetRenderPriorityForCandidate(1),
        greaterThan(HomeSceneGame.debugSeatBackfillRenderPriority),
      );
      expect(
        game.debugPetRenderPriorityForCandidate(1),
        lessThan(HomeSceneGame.debugSeatOccluderRenderPriority),
      );
    });

    test('keeps right armchair front behind pets and side arm in front', () {
      for (final device in HomeSceneDevice.values) {
        expect(
          HomeSceneGame.debugRightArmchairFrontOccluderRenderPriority(device),
          HomeSceneGame.debugSeatBackfillRenderPriority,
          reason: '$device front edge should not cover seated pets.',
        );
        expect(
          HomeSceneGame.debugRightArmchairSideOccluderRenderPriority(device),
          HomeSceneGame.debugSeatOccluderRenderPriority,
          reason: '$device right armrest should cover the pet tail edge.',
        );
      }
    });

    test('clips the sofa front backfill to the cushion apron shape', () {
      final clipPoints = HomeSceneGame.debugSofaFrontOccluderClipPoints;

      expect(clipPoints, hasLength(11));
      expect(
        clipPoints.map((point) => point.dx),
        everyElement(inInclusiveRange(0, 1)),
      );
      expect(
        clipPoints.map((point) => point.dy),
        everyElement(inInclusiveRange(0, 1)),
      );
      expect(clipPoints.first.dx, closeTo(0.01, 0.001));
      expect(clipPoints.first.dy, closeTo(0.34, 0.001));
      expect(clipPoints[3].dy, closeTo(0.18, 0.001));
      expect(clipPoints.last.dy, closeTo(0.84, 0.001));
    });

    test('clips the right armchair side cover to the armrest shape', () {
      final clipPoints = HomeSceneGame.debugRightArmchairSideOccluderClipPoints;

      expect(clipPoints, hasLength(9));
      expect(
        clipPoints.map((point) => point.dx),
        everyElement(inInclusiveRange(0, 1)),
      );
      expect(
        clipPoints.map((point) => point.dy),
        everyElement(inInclusiveRange(0, 1)),
      );
      expect(clipPoints.first.dx, closeTo(0.68, 0.001));
      expect(clipPoints.first.dy, closeTo(0.28, 0.001));
      expect(clipPoints[1].dx, closeTo(0.78, 0.001));
      expect(clipPoints.any((point) => point.dx == 1), isTrue);
    });

    test('clips the right armchair near-arm backfill shape', () {
      final clipPoints =
          HomeSceneGame.debugRightArmchairNearArmOccluderClipPoints;

      expect(clipPoints, hasLength(7));
      expect(
        clipPoints.map((point) => point.dx),
        everyElement(inInclusiveRange(0, 1)),
      );
      expect(
        clipPoints.map((point) => point.dy),
        everyElement(inInclusiveRange(0, 1)),
      );
      expect(clipPoints.first.dx, closeTo(0.00, 0.001));
      expect(clipPoints.first.dy, closeTo(0.45, 0.001));
      expect(clipPoints[3].dx, closeTo(0.58, 0.001));
      expect(clipPoints.last.dy, closeTo(0.68, 0.001));
    });

    test('keeps sofa seat pets centered above the front backfill', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final cushionRect = HomeSceneGame.debugSofaSeatCushionRect;
      final occluderRect = HomeSceneGame.debugSofaFrontOccluderRect;
      final clipPoints = HomeSceneGame.debugSofaFrontOccluderClipPoints;
      final visibleFrontEdgeY =
          occluderRect.top + (occluderRect.height * clipPoints[3].dy);

      expect(
        game.debugPetRenderPriorityForCandidate(0),
        greaterThan(HomeSceneGame.debugSeatBackfillRenderPriority),
      );

      for (final assetPath in _rightArmchairSeatAssetPaths) {
        final rect = game.debugPetRectForCandidate(
          candidateIndex: 0,
          assetPath: assetPath,
        );

        expect(
          rect.center.dx,
          closeTo(cushionRect.center.dx, 0.028),
          reason: '$assetPath should sit on the sofa cushion.',
        );
        expect(
          rect.bottom,
          greaterThan(visibleFrontEdgeY),
          reason:
              '$assetPath may overlap the sofa front but should render fully above it.',
        );
      }
    });

    test('keeps right armchair seat pets centered on the cushion band', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final cushionRect = HomeSceneGame.debugRightArmchairSeatCushionRect;

      for (final assetPath in _rightArmchairSeatAssetPaths) {
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
          greaterThan(cushionRect.top + (cushionRect.height * 0.35)),
          reason: '$assetPath should sit down into the armchair cushion.',
        );
        expect(
          rect.bottom,
          lessThan(cushionRect.bottom),
          reason: '$assetPath should not sink below the armchair cushion.',
        );
      }
    });

    test('draws right armchair pets above the seat front backfill', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);

      expect(
        game.debugPetRenderPriorityForCandidate(1),
        greaterThan(HomeSceneGame.debugSeatBackfillRenderPriority),
      );
      expect(
        HomeSceneGame.debugRightArmchairFrontOccluderRenderPriority(
          HomeSceneDevice.mobile,
        ),
        HomeSceneGame.debugSeatBackfillRenderPriority,
      );
    });

    test('lets only the right armrest draw over seated armchair pets', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final occluderRect = HomeSceneGame.debugRightArmchairSideOccluderRect;
      final clipPoints = HomeSceneGame.debugRightArmchairSideOccluderClipPoints;
      final innerArmrestLeft =
          occluderRect.left + (occluderRect.width * clipPoints[1].dx);
      final innerArmrestTop =
          occluderRect.top + (occluderRect.height * clipPoints[1].dy);

      for (final assetPath in _rightArmchairSeatAssetPaths) {
        final rect = game.debugPetRectForCandidate(
          candidateIndex: 1,
          assetPath: assetPath,
        );

        expect(
          game.debugPetRenderPriorityForCandidate(1),
          lessThan(HomeSceneGame.debugSeatOccluderRenderPriority),
          reason:
              '$assetPath should let the right armrest draw over the outer edge.',
        );
        expect(
          innerArmrestLeft,
          greaterThan(rect.left + (rect.width * 0.62)),
          reason: '$assetPath should only be covered near the tail/right edge.',
        );
        expect(
          innerArmrestLeft,
          lessThan(occluderRect.right),
          reason: '$assetPath should keep the armrest cover inside the chair.',
        );
        expect(
          innerArmrestTop,
          greaterThan(rect.top + (rect.height * 0.2)),
          reason: '$assetPath corner cover should start below the head.',
        );
      }
    });

    test('keeps right armchair near-arm backfill behind seated pets', () {
      final game = HomeSceneGame(device: HomeSceneDevice.mobile);
      final occluderRect = HomeSceneGame.debugRightArmchairNearArmOccluderRect;
      final clipPoints =
          HomeSceneGame.debugRightArmchairNearArmOccluderClipPoints;
      final armTopLeft = Offset(
        occluderRect.left + (occluderRect.width * clipPoints[1].dx),
        occluderRect.top + (occluderRect.height * clipPoints[1].dy),
      );
      final armInnerRight = Offset(
        occluderRect.left + (occluderRect.width * clipPoints[3].dx),
        occluderRect.top + (occluderRect.height * clipPoints[3].dy),
      );

      final rect = game.debugPetRectForCandidate(
        candidateIndex: 1,
        assetPath: 'images/pets/grow/dog/growing/sitting.webp',
      );

      expect(
        game.debugPetRenderPriorityForCandidate(1),
        greaterThan(HomeSceneGame.debugSeatBackfillRenderPriority),
      );
      expect(armTopLeft.dx, lessThan(rect.center.dx));
      expect(armTopLeft.dy, greaterThan(rect.top + (rect.height * 0.14)));
      expect(armInnerRight.dx, greaterThan(rect.left + (rect.width * 0.15)));
      expect(armInnerRight.dx, lessThan(rect.center.dx));
      expect(armInnerRight.dy, greaterThan(rect.top + (rect.height * 0.45)));
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
