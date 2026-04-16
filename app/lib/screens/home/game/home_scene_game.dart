import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../core/ui/sprite_atlas_flame.dart';
import '../task_panel_sprite_catalog.dart';
import '../../../models/pet_artwork.dart';

enum HomeSceneDevice { mobile, tablet }

const List<_PetCandidatePoint> _homePetCandidatePoints = <_PetCandidatePoint>[
  // 1. Couch center.
  _PetCandidatePoint(centerX: 0.31, centerY: 0.60),
  // 2. Upper-right floor by the chair.
  _PetCandidatePoint(centerX: 0.65, centerY: 0.72),
  // 3. Left floor near the book stack.
  _PetCandidatePoint(centerX: 0.14, centerY: 0.83),
  // 4. Bottom-left open floor.
  _PetCandidatePoint(centerX: 0.06, centerY: 0.95),
  // 5. Center-left rug edge.
  _PetCandidatePoint(centerX: 0.30, centerY: 0.88),
  // 6. Bottom-center floor.
  _PetCandidatePoint(centerX: 0.55, centerY: 0.95),
  // 7. Right floor near the plant.
  _PetCandidatePoint(centerX: 0.67, centerY: 0.87),
  // 8. Bottom-right floor.
  _PetCandidatePoint(centerX: 0.87, centerY: 0.92),
];

const double _homePetTargetFillFactor = 0.56;
const double _homeSceneBackgroundAspectRatio = 1376 / 3076;
const double _homePetSceneInsetFactor = 0.012;

class _PetFrameAnimationSpec {
  const _PetFrameAnimationSpec({
    required this.frameAssetPaths,
    required this.frameDurations,
  });

  final List<String> frameAssetPaths;
  final List<double> frameDurations;
}

const _PetFrameAnimationSpec _dogLieHomeAnimation = _PetFrameAnimationSpec(
  frameAssetPaths: <String>[
    'images/pets/dog/1 (1).png',
    'images/pets/dog/2 (1).png',
    'images/pets/dog/3.png',
    'images/pets/dog/4 (2).png',
    'images/pets/dog/5.png',
    'images/pets/dog/6 (1).png',
  ],
  frameDurations: <double>[3.8, 0.26, 0.28, 0.38, 0.32, 0.9],
);

const _PetFrameAnimationSpec _catLieHomeAnimation = _PetFrameAnimationSpec(
  frameAssetPaths: <String>[
    'images/pets/cat/1 (3).png',
    'images/pets/cat/2 (3).png',
    'images/pets/cat/3 (2).png',
    'images/pets/cat/4 (4).png',
    'images/pets/cat/5 (2).png',
    'images/pets/cat/6 (2).png',
  ],
  frameDurations: <double>[3.6, 0.22, 0.22, 0.24, 0.24, 0.28],
);

const _PetFrameAnimationSpec _catSitHomeAnimation = _PetFrameAnimationSpec(
  frameAssetPaths: <String>[
    'images/pets/cat/wagging tail/1 (5).png',
    'images/pets/cat/wagging tail/2 (5).png',
    'images/pets/cat/wagging tail/3 (3).png',
    'images/pets/cat/wagging tail/4 (5).png',
    'images/pets/cat/wagging tail/5 (3).png',
  ],
  frameDurations: <double>[3.4, 0.18, 0.18, 0.18, 0.22],
);

const _PetFrameAnimationSpec _catSleepHomeAnimation = _PetFrameAnimationSpec(
  frameAssetPaths: <String>[
    'images/pets/cat/open eyes/1_transparent.png',
    'images/pets/cat/open eyes/2_transparent.png',
    'images/pets/cat/open eyes/1_transparent.png',
  ],
  frameDurations: <double>[4.0, 0.32, 0.42],
);

const _PetFrameAnimationSpec _dogSitHomeAnimation = _PetFrameAnimationSpec(
  frameAssetPaths: <String>[
    'images/pets/dog/turning the face and smiling/7_transparent.png',
    'images/pets/dog/turning the face and smiling/8_transparent.png',
    'images/pets/dog/turning the face and smiling/9_transparent.png',
    'images/pets/dog/turning the face and smiling/10_transparent.png',
    'images/pets/dog/turning the face and smiling/11_transparent.png',
    'images/pets/dog/wagging tail/12-ezremove.png',
    'images/pets/dog/wagging tail/13-ezremove.png',
    'images/pets/dog/wagging tail/14-ezremove.png',
    'images/pets/dog/wagging tail/15_transparent.png',
    'images/pets/dog/wagging tail/16-ezremove.png',
    'images/pets/dog/wagging tail/17-ezremove.png',
  ],
  frameDurations: <double>[
    3.2,
    0.18,
    0.18,
    0.18,
    0.24,
    0.18,
    0.18,
    0.18,
    0.18,
    0.18,
    0.24,
  ],
);

const _PetFrameAnimationSpec _dogSleepHomeAnimation = _PetFrameAnimationSpec(
  frameAssetPaths: <String>[
    'images/pets/dog/moving noise/1 (2).png',
    'images/pets/dog/moving noise/2 (2).png',
    'images/pets/dog/moving noise/3 (1).png',
    'images/pets/dog/moving noise/4 (3).png',
    'images/pets/dog/moving noise/5 (1).png',
  ],
  frameDurations: <double>[4.2, 0.24, 0.24, 0.24, 0.3],
);

class _PetCandidatePoint {
  const _PetCandidatePoint({required this.centerX, required this.centerY});

  final double centerX;
  final double centerY;
}

class _PetLayoutProfile {
  const _PetLayoutProfile({
    required this.widthFactor,
    required this.heightFactor,
    required this.overflowJitterX,
    required this.overflowJitterY,
  });

  final double widthFactor;
  final double heightFactor;
  final double overflowJitterX;
  final double overflowJitterY;
}

class _AssignedPetPlacement {
  const _AssignedPetPlacement({
    required this.candidateIndex,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  final int candidateIndex;
  final double offsetX;
  final double offsetY;
}

class HomeSceneTaskSeed {
  const HomeSceneTaskSeed({required this.title, required this.points});

  final String title;
  final int points;
}

class HomeScenePetSeed {
  const HomeScenePetSeed({required this.petId, required this.petType});

  final int petId;
  final String petType;
}

class HomeSceneGame extends FlameGame<World> with RiverpodGameMixin<World> {
  HomeSceneGame({
    required this.device,
    this.onTaskTap,
    this.onOpenFamily,
    this.onOpenShop,
    this.onTaskItemLongPress,
    this.onTaskAddTap,
    this.onOpenPetDetail,
  }) : super(world: World()) {
    _profile = _profileFor(
      device,
      onTaskTap: onTaskTap ?? _showTaskPanel,
      onOpenFamily: onOpenFamily,
      onOpenShop: onOpenShop,
    );
  }

  final HomeSceneDevice device;
  final VoidCallback? onTaskTap;
  final VoidCallback? onOpenFamily;
  final VoidCallback? onOpenShop;
  final void Function(String taskLabel, Offset globalPosition)?
  onTaskItemLongPress;
  final Future<void> Function()? onTaskAddTap;
  final void Function(int petId)? onOpenPetDetail;
  late final _SceneProfile _profile;

  late Vector2 _sceneSize;
  late final _SceneBackgroundComponent _background;
  final List<_AnimatedSceneComponent> _animatedComponents =
      <_AnimatedSceneComponent>[];
  _SceneSpriteComponent? _taskNoteComponent;
  _TaskPanelOverlay? _taskPanelOverlay;
  final List<_TaskPanelEntry> _taskEntries = <_TaskPanelEntry>[];
  final List<HomeScenePetSeed> _petEntries = <HomeScenePetSeed>[];
  final Map<int, _AssignedPetPlacement> _petPlacements =
      <int, _AssignedPetPlacement>{};
  final math.Random _petPlacementRandom = math.Random();
  Vector2? _lastUiLayoutSize;

  bool _ready = false;
  bool _exitTriggered = false;
  bool _openTaskPanelWhenReady = false;
  static const int maxTaskCount = _TaskPanelOverlay._maxTaskCount;

  int get taskCount => _taskEntries.length;

  int get taskPageCount => math.max(
    1,
    (taskCount + _TaskPanelOverlay._pageSize - 1) ~/
        _TaskPanelOverlay._pageSize,
  );

  static _SceneProfile _profileFor(
    HomeSceneDevice device, {
    required VoidCallback onTaskTap,
    VoidCallback? onOpenFamily,
    VoidCallback? onOpenShop,
  }) {
    return switch (device) {
      HomeSceneDevice.mobile => _mobileProfile(
        onTaskTap: onTaskTap,
        onOpenFamily: onOpenFamily,
        onOpenShop: onOpenShop,
      ),
      HomeSceneDevice.tablet => _tabletProfile(
        onTaskTap: onTaskTap,
        onOpenFamily: onOpenFamily,
        onOpenShop: onOpenShop,
      ),
    };
  }

  static _SceneProfile _mobileProfile({
    required VoidCallback onTaskTap,
    VoidCallback? onOpenFamily,
    VoidCallback? onOpenShop,
  }) {
    return _SceneProfile(
      backgroundAsset: 'scenes/4.jpg',
      backgroundFit: _SceneBackgroundFit.contain,
      backgroundFillColor: const Color(0xFFF4E3CF),
      specs: <_UiSpec>[
        _SceneSpriteSpec(
          rect: const _RectFactor(0.068, 0.102, 0.148, 0.122),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: 'images/ui/task_note.png',
          behavior: _SceneSpriteBehavior.taskNote,
          ambientPhase: 0.2,
          entryDelay: 0.22,
          entryOffset: 70,
          onTap: onTaskTap,
        ),
        _SceneSpriteSpec(
          rect: const _RectFactor(0.422, 0.322, 0.156, 0.102),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: 'images/ui/family_photo.png',
          behavior: _SceneSpriteBehavior.familyPhoto,
          ambientPhase: 1.6,
          entryDelay: 0.30,
          entryOffset: 70,
          onTap: onOpenFamily,
        ),
        _SceneSpriteSpec(
          rect: const _RectFactor(0.704, 0.104, 0.178, 0.154),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: 'images/ui/shop_basket.png',
          behavior: _SceneSpriteBehavior.shopBasket,
          ambientPhase: 2.4,
          entryDelay: 0.38,
          entryOffset: 70,
          onTap: onOpenShop,
        ),
      ],
    );
  }

  static _SceneProfile _tabletProfile({
    required VoidCallback onTaskTap,
    VoidCallback? onOpenFamily,
    VoidCallback? onOpenShop,
  }) {
    return _SceneProfile(
      backgroundAsset: 'scenes/4.jpg',
      backgroundFit: _SceneBackgroundFit.contain,
      backgroundFillColor: const Color(0xFFF4E3CF),
      specs: <_UiSpec>[
        _SceneSpriteSpec(
          rect: const _RectFactor(0.070, 0.102, 0.138, 0.118),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: 'images/ui/task_note.png',
          behavior: _SceneSpriteBehavior.taskNote,
          ambientPhase: 0.3,
          entryDelay: 0.18,
          entryOffset: 46,
          onTap: onTaskTap,
        ),
        _SceneSpriteSpec(
          rect: const _RectFactor(0.430, 0.322, 0.150, 0.100),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: 'images/ui/family_photo.png',
          behavior: _SceneSpriteBehavior.familyPhoto,
          ambientPhase: 1.8,
          entryDelay: 0.24,
          entryOffset: 46,
          onTap: onOpenFamily,
        ),
        _SceneSpriteSpec(
          rect: const _RectFactor(0.694, 0.106, 0.184, 0.154),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: 'images/ui/shop_basket.png',
          behavior: _SceneSpriteBehavior.shopBasket,
          ambientPhase: 2.2,
          entryDelay: 0.30,
          entryOffset: 46,
          onTap: onOpenShop,
        ),
      ],
    );
  }

  void replacePetEntries(List<HomeScenePetSeed> pets) {
    _petEntries
      ..clear()
      ..addAll(pets.where((item) => item.petId > 0));
    _syncPetPlacements();

    if (_ready) {
      _rebuildUiFromProfile();
    }
  }

  int get debugPetCandidateCount => _homePetCandidatePoints.length;

  Map<int, int> debugPetCandidateAssignments() {
    return Map<int, int>.unmodifiable(
      _petPlacements.map(
        (petId, placement) => MapEntry(petId, placement.candidateIndex),
      ),
    );
  }

  Map<int, Offset> debugPetPlacementOffsets() {
    return Map<int, Offset>.unmodifiable(
      _petPlacements.map(
        (petId, placement) =>
            MapEntry(petId, Offset(placement.offsetX, placement.offsetY)),
      ),
    );
  }

  Map<int, Rect> debugPetRects() {
    _syncPetPlacements();
    final layout = _petLayoutProfile();

    return Map<int, Rect>.unmodifiable(<int, Rect>{
      for (var index = 0; index < _petEntries.length; index++)
        _petEntries[index].petId: () {
          final pet = _petEntries[index];
          final petType = _normalizedPetType(pet.petType, index: index);
          final assetPath = _petAssetPathForType(petType, pet.petId);
          final rect = _petRectForPlacement(
            _petPlacements[pet.petId]!,
            layout,
            cropRect: _petCropRectForAsset(assetPath),
          );
          return Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height);
        }(),
    });
  }

  static Rect? debugPetCropRectForAssetPath(String assetPath) {
    final cropRect = _homePetCropRects[assetPath];
    if (cropRect == null) {
      return null;
    }
    return Rect.fromLTWH(
      cropRect.left,
      cropRect.top,
      cropRect.width,
      cropRect.height,
    );
  }

  static Size debugPetRenderSize({
    required Size slotSize,
    required Size sourceSize,
  }) {
    return _resolveHomePetRenderSize(
      slotSize: slotSize,
      sourceSize: sourceSize,
    );
  }

  List<_PetSpriteSpec> _buildPetSpecs() {
    if (_petEntries.isEmpty) {
      return const <_PetSpriteSpec>[];
    }

    _syncPetPlacements();
    final layout = _petLayoutProfile();

    return List<_PetSpriteSpec>.generate(_petEntries.length, (index) {
      final pet = _petEntries[index];
      final petType = _normalizedPetType(pet.petType, index: index);
      final placement = _petPlacements[pet.petId]!;
      final assetPath = _petAssetPathForType(petType, pet.petId);
      final cropRect = _petCropRectForAsset(assetPath);
      final animation = _petAnimationForAsset(assetPath);
      return _PetSpriteSpec(
        rect: _petRectForPlacement(placement, layout, cropRect: cropRect),
        referenceSpace: _UiReferenceSpace.background,
        assetPath: assetPath,
        cropRect: cropRect,
        animationFrameAssetPaths:
            animation?.frameAssetPaths ?? const <String>[],
        animationFrameDurations: animation?.frameDurations ?? const <double>[],
        entryDelay: _petEntryDelayFor(index),
        entryOffset: _petEntryOffsetFor(device),
        onTap: () => onOpenPetDetail?.call(pet.petId),
      );
    });
  }

  void _syncPetPlacements() {
    final activePetIds = _petEntries.map((item) => item.petId).toSet();
    _petPlacements.removeWhere((petId, _) => !activePetIds.contains(petId));

    if (activePetIds.isEmpty) {
      return;
    }

    final occupancyCounts = List<int>.filled(_homePetCandidatePoints.length, 0);
    for (final petId in activePetIds) {
      final placement = _petPlacements[petId];
      if (placement == null) {
        continue;
      }
      occupancyCounts[placement.candidateIndex] += 1;
    }

    final availableIndices = List<int>.generate(
      _homePetCandidatePoints.length,
      (index) => index,
    )..removeWhere((index) => occupancyCounts[index] > 0);

    final layout = _petLayoutProfile();
    for (final pet in _petEntries) {
      if (_petPlacements.containsKey(pet.petId)) {
        continue;
      }

      final placement = _createPetPlacement(
        availableIndices: availableIndices,
        occupancyCounts: occupancyCounts,
        layout: layout,
      );
      _petPlacements[pet.petId] = placement;
      occupancyCounts[placement.candidateIndex] += 1;
    }
  }

  _AssignedPetPlacement _createPetPlacement({
    required List<int> availableIndices,
    required List<int> occupancyCounts,
    required _PetLayoutProfile layout,
  }) {
    if (availableIndices.isNotEmpty) {
      final randomIndex = _petPlacementRandom.nextInt(availableIndices.length);
      final candidateIndex = availableIndices.removeAt(randomIndex);
      return _AssignedPetPlacement(candidateIndex: candidateIndex);
    }

    final minimumOccupancy = occupancyCounts.reduce(math.min);
    final leastCrowdedIndices = <int>[];
    for (var index = 0; index < occupancyCounts.length; index++) {
      if (occupancyCounts[index] == minimumOccupancy) {
        leastCrowdedIndices.add(index);
      }
    }

    final candidateIndex =
        leastCrowdedIndices[_petPlacementRandom.nextInt(
          leastCrowdedIndices.length,
        )];
    final occupantCount = occupancyCounts[candidateIndex];
    final spreadMultiplier = math.min(occupantCount + 1, 3).toDouble();
    final angle = _petPlacementRandom.nextDouble() * math.pi * 2;
    return _AssignedPetPlacement(
      candidateIndex: candidateIndex,
      offsetX: math.cos(angle) * layout.overflowJitterX * spreadMultiplier,
      offsetY: math.sin(angle) * layout.overflowJitterY * spreadMultiplier,
    );
  }

  _RectFactor _petRectForPlacement(
    _AssignedPetPlacement placement,
    _PetLayoutProfile layout, {
    _RectFactor? cropRect,
  }) {
    final candidate = _homePetCandidatePoints[placement.candidateIndex];
    final renderSize = _petRenderSizeFactors(
      layout: layout,
      cropRect: cropRect,
    );
    final halfWidth = renderSize.width / 2;
    final centerX = (candidate.centerX + placement.offsetX)
        .clamp(
          halfWidth + _homePetSceneInsetFactor,
          1 - halfWidth - _homePetSceneInsetFactor,
        )
        .toDouble();
    final bottom =
        (candidate.centerY + placement.offsetY + (layout.heightFactor / 2))
            .clamp(
              renderSize.height + _homePetSceneInsetFactor,
              1 - _homePetSceneInsetFactor,
            )
            .toDouble();

    return _RectFactor(
      centerX - halfWidth,
      bottom - renderSize.height,
      renderSize.width,
      renderSize.height,
    );
  }

  Size _petRenderSizeFactors({
    required _PetLayoutProfile layout,
    required _RectFactor? cropRect,
  }) {
    if (cropRect == null) {
      return Size(layout.widthFactor, layout.heightFactor);
    }

    final normalizedRenderSize = _resolveHomePetRenderSize(
      slotSize: Size(
        layout.widthFactor * _homeSceneBackgroundAspectRatio,
        layout.heightFactor,
      ),
      sourceSize: Size(cropRect.width, cropRect.height),
    );
    if (normalizedRenderSize.isEmpty) {
      return Size(layout.widthFactor, layout.heightFactor);
    }

    return Size(
      normalizedRenderSize.width / _homeSceneBackgroundAspectRatio,
      normalizedRenderSize.height,
    );
  }

  _PetLayoutProfile _petLayoutProfile() {
    return switch (device) {
      HomeSceneDevice.mobile => const _PetLayoutProfile(
        widthFactor: 0.17,
        heightFactor: 0.11,
        overflowJitterX: 0.028,
        overflowJitterY: 0.020,
      ),
      HomeSceneDevice.tablet => const _PetLayoutProfile(
        widthFactor: 0.11,
        heightFactor: 0.15,
        overflowJitterX: 0.022,
        overflowJitterY: 0.024,
      ),
    };
  }

  double _petEntryDelayFor(int index) {
    return switch (device) {
      HomeSceneDevice.mobile => 0.68 + (index * 0.04),
      HomeSceneDevice.tablet => 0.58 + (index * 0.035),
    };
  }

  double _petEntryOffsetFor(HomeSceneDevice device) {
    return switch (device) {
      HomeSceneDevice.mobile => 44,
      HomeSceneDevice.tablet => 34,
    };
  }

  String _normalizedPetType(String petType, {required int index}) {
    return normalizePetType(
      petType,
      fallback: selectablePetTypes[index % selectablePetTypes.length],
    );
  }

  String _petAssetPathForType(String petType, int petId) {
    final poseIndex = deterministicPetPoseIndex(petType, petId);
    return petHomeAssetPath(petType, poseIndex);
  }

  _RectFactor? _petCropRectForAsset(String assetPath) {
    return _homePetCropRects[assetPath];
  }

  _PetFrameAnimationSpec? _petAnimationForAsset(String assetPath) {
    return switch (assetPath) {
      'images/pets/cat_lie.png' => _catLieHomeAnimation,
      'images/pets/cat_sit.png' => _catSitHomeAnimation,
      'images/pets/cat_sleep_clean.png' => _catSleepHomeAnimation,
      'images/pets/dog_lie.png' => _dogLieHomeAnimation,
      'images/pets/dog_sit.png' => _dogSitHomeAnimation,
      'images/pets/dog_sleep_clean.png' => _dogSleepHomeAnimation,
      _ => null,
    };
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    _sceneSize = size.clone();
    camera.viewfinder.position = _sceneSize / 2;
    if (_ready) {
      _background.updateSceneSize(_sceneSize);
      _taskPanelOverlay?.updateSceneSize(_sceneSize);
      if (_needsUiRebuild()) {
        _rebuildUiFromProfile();
      }
    }
  }

  void _showTaskPanel() {
    if (!_ready || _taskPanelOverlay != null) {
      return;
    }
    final overlay = _TaskPanelOverlay(
      sceneSize: _sceneSize,
      isTablet: device == HomeSceneDevice.tablet,
      panelOriginRectProvider: _resolveTaskPanelOriginRect,
      onRemoved: () => _taskPanelOverlay = null,
      onTaskItemLongPress: onTaskItemLongPress,
      onAddTaskTap: onTaskAddTap,
      taskEntries: List<_TaskPanelEntry>.from(_taskEntries),
    );
    _taskPanelOverlay = overlay;
    world.add(overlay);
  }

  void openTaskPanel() {
    if (!_ready) {
      _openTaskPanelWhenReady = true;
      return;
    }
    if (onTaskTap != null) {
      onTaskTap!.call();
      return;
    }
    _showTaskPanel();
  }

  void replaceTaskEntries(List<HomeSceneTaskSeed> tasks) {
    _taskEntries.clear();

    var index = 0;
    for (final task in tasks) {
      if (_taskEntries.length >= _TaskPanelOverlay._maxTaskCount) {
        break;
      }

      final normalized = task.title.trim();
      if (normalized.isEmpty) {
        continue;
      }

      _taskEntries.add(
        _TaskPanelEntry(
          label: normalized,
          highlighted: index.isEven,
          points: task.points > 0 ? task.points : 10,
        ),
      );
      index += 1;
    }

    _taskPanelOverlay?.replaceEntries(List<_TaskPanelEntry>.from(_taskEntries));
  }

  void removeTaskItem(String taskLabel) {
    final normalized = taskLabel.trim();
    final index = _taskEntries.indexWhere((item) => item.label == normalized);
    if (index < 0) {
      return;
    }
    _taskEntries.removeAt(index);
    _taskPanelOverlay?.removeTaskItem(normalized);
  }

  int? taskPointsOf(String taskLabel) {
    final normalized = taskLabel.trim();
    final index = _taskEntries.indexWhere((item) => item.label == normalized);
    if (index < 0) {
      return null;
    }
    return _taskEntries[index].points;
  }

  bool addTaskItem(String taskLabel, {int points = 10}) {
    final normalized = taskLabel.trim();
    if (normalized.isEmpty ||
        _taskEntries.length >= _TaskPanelOverlay._maxTaskCount) {
      return false;
    }
    if (_taskEntries.any((item) => item.label == normalized)) {
      return false;
    }

    final safePoints = points > 0 ? points : 10;
    final index = _taskEntries.length;
    final entry = _TaskPanelEntry(
      label: normalized,
      highlighted: index.isEven,
      points: safePoints,
    );
    _taskEntries.add(entry);
    _taskPanelOverlay?.addTaskItemFromEntry(entry);
    return true;
  }

  bool updateTaskItem({
    required String oldTaskLabel,
    required String newTaskLabel,
    int? points,
  }) {
    final oldNormalized = oldTaskLabel.trim();
    final normalized = newTaskLabel.trim();
    if (oldNormalized.isEmpty || normalized.isEmpty) {
      return false;
    }

    final index = _taskEntries.indexWhere(
      (item) => item.label == oldNormalized,
    );
    if (index < 0) {
      return false;
    }

    final hasDuplicate = _taskEntries.any(
      (item) => item.label == normalized && item.label != oldNormalized,
    );
    if (hasDuplicate) {
      return false;
    }

    final currentPoints = _taskEntries[index].points;
    final safePoints = points == null
        ? currentPoints
        : (points > 0 ? points : currentPoints);

    _taskEntries[index] = _taskEntries[index].copyWith(
      label: normalized,
      points: safePoints,
    );
    _taskPanelOverlay?.updateTaskItem(
      oldTaskLabel: oldNormalized,
      newTaskLabel: normalized,
    );
    return true;
  }

  @override
  Color backgroundColor() => _profile.backgroundFillColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _sceneSize = size.clone();
    camera.viewfinder.position = _sceneSize / 2;
    images.prefix = 'assets/';

    final backgroundSprite = Sprite(
      await images.load(_profile.backgroundAsset),
    );
    _background = _SceneBackgroundComponent(
      sprite: backgroundSprite,
      sceneSize: _sceneSize,
      fit: _profile.backgroundFit,
    );
    await world.add(_background);

    if (_sceneSize.x > 0 && _sceneSize.y > 0) {
      _rebuildUiFromProfile();
    }

    _ready = true;
    if (_openTaskPanelWhenReady) {
      _openTaskPanelWhenReady = false;
      _showTaskPanel();
    }
  }

  void startExitAnimation() {
    if (!_ready || _exitTriggered) {
      return;
    }
    _exitTriggered = true;

    _background.startExit();
    _taskPanelOverlay?.startExit();

    for (var i = 0; i < _animatedComponents.length; i++) {
      _animatedComponents[i].playExit(delay: 0.018 * i);
    }
  }

  bool _needsUiRebuild() {
    final lastSize = _lastUiLayoutSize;
    if (lastSize == null) {
      return true;
    }
    return (lastSize.x - _sceneSize.x).abs() > 0.5 ||
        (lastSize.y - _sceneSize.y).abs() > 0.5;
  }

  void _rebuildUiFromProfile() {
    for (final component in List<_AnimatedSceneComponent>.from(
      _animatedComponents,
    )) {
      component.removeFromParent();
    }
    _animatedComponents.clear();
    _taskNoteComponent = null;

    final sceneSpecs = <_UiSpec>[..._profile.specs, ..._buildPetSpecs()];
    final backgroundRect = _background.layoutRect;

    for (final spec in sceneSpecs) {
      final component = spec.build(
        sceneSize: _sceneSize,
        backgroundRect: backgroundRect,
      );
      if (component is _SceneSpriteComponent &&
          component.behavior == _SceneSpriteBehavior.taskNote) {
        _taskNoteComponent = component;
      }
      _addAnimated(component);
    }
    _lastUiLayoutSize = _sceneSize.clone();
  }

  Rect? _resolveTaskPanelOriginRect() {
    final taskNote = _taskNoteComponent;
    if (taskNote == null || taskNote.parent == null) {
      return null;
    }
    return taskNote.sceneRect;
  }

  Rect? taskPanelOriginRect() => _resolveTaskPanelOriginRect();

  void _addAnimated(_AnimatedSceneComponent component) {
    _animatedComponents.add(component);
    world.add(component);
  }
}

class _SceneProfile {
  const _SceneProfile({
    required this.backgroundAsset,
    required this.backgroundFit,
    required this.backgroundFillColor,
    required this.specs,
  });

  final String backgroundAsset;
  final _SceneBackgroundFit backgroundFit;
  final Color backgroundFillColor;
  final List<_UiSpec> specs;
}

enum _SceneBackgroundFit { cover, contain }

class _RectFactor {
  const _RectFactor(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  Rect resolve(Vector2 sceneSize) {
    return Rect.fromLTWH(
      sceneSize.x * left,
      sceneSize.y * top,
      sceneSize.x * width,
      sceneSize.y * height,
    );
  }

  Rect resolveInRect(Rect referenceRect) {
    return Rect.fromLTWH(
      referenceRect.left + (referenceRect.width * left),
      referenceRect.top + (referenceRect.height * top),
      referenceRect.width * width,
      referenceRect.height * height,
    );
  }
}

const Map<String, _RectFactor> _homePetCropRects = <String, _RectFactor>{
  'images/pets/cat_lie.png': _RectFactor(0.1399, 0.3372, 0.7495, 0.3412),
  'images/pets/cat_sit.png': _RectFactor(0.1697, 0.0369, 0.6621, 0.9272),
  'images/pets/cat_sleep_clean.png': _RectFactor(
    0.0662,
    0.2805,
    0.8744,
    0.5488,
  ),
  'images/pets/dog_lie.png': _RectFactor(0.1682, 0.3186, 0.7602, 0.3305),
  'images/pets/dog_sit.png': _RectFactor(0.2649, 0.2434, 0.4077, 0.4917),
  'images/pets/dog_sleep_clean.png': _RectFactor(
    0.2044,
    0.2893,
    0.5727,
    0.3784,
  ),
  'images/pets/hamster_lie_.png': _RectFactor(0.1687, 0.3084, 0.6699, 0.3515),
  'images/pets/hamster_sit.png': _RectFactor(0.2151, 0.1780, 0.5742, 0.6606),
  'images/pets/hamster_sleep.png': _RectFactor(0.1023, 0.1780, 0.8198, 0.6411),
  'images/pets/rabbit_sit.png': _RectFactor(0.2127, 0.0442, 0.6191, 0.9038),
  'images/pets/rabbit_sleep.png': _RectFactor(0.0662, 0.2122, 0.9106, 0.6171),
  'images/pets/turtle_sleep.png': _RectFactor(0.0642, 0.2263, 0.8779, 0.6113),
};

Size _resolveHomePetRenderSize({
  required Size slotSize,
  required Size sourceSize,
}) {
  if (slotSize.width <= 0 ||
      slotSize.height <= 0 ||
      sourceSize.width <= 0 ||
      sourceSize.height <= 0) {
    return Size.zero;
  }

  final fitted = applyBoxFit(BoxFit.contain, sourceSize, slotSize);
  final destination = fitted.destination;
  final destinationArea = destination.width * destination.height;
  if (destinationArea <= 0) {
    return Size.zero;
  }

  final targetArea =
      slotSize.width * slotSize.height * _homePetTargetFillFactor;
  final scale = math.sqrt(targetArea / destinationArea);

  return Size(destination.width * scale, destination.height * scale);
}

enum _UiReferenceSpace { viewport, background }

abstract class _UiSpec {
  const _UiSpec({
    required this.rect,
    required this.entryDelay,
    required this.entryOffset,
    this.referenceSpace = _UiReferenceSpace.viewport,
  });

  final _RectFactor rect;
  final double entryDelay;
  final double entryOffset;
  final _UiReferenceSpace referenceSpace;

  Rect resolveRect(Vector2 sceneSize, Rect backgroundRect) {
    final referenceRect = switch (referenceSpace) {
      _UiReferenceSpace.viewport => Rect.fromLTWH(
        0,
        0,
        sceneSize.x,
        sceneSize.y,
      ),
      _UiReferenceSpace.background => backgroundRect,
    };
    return rect.resolveInRect(referenceRect);
  }

  _AnimatedSceneComponent build({
    required Vector2 sceneSize,
    required Rect backgroundRect,
  });
}

class _SceneSpriteSpec extends _UiSpec {
  const _SceneSpriteSpec({
    required super.rect,
    required this.assetPath,
    required this.behavior,
    required this.ambientPhase,
    this.onTap,
    super.referenceSpace,
    required super.entryDelay,
    required super.entryOffset,
  });

  final String assetPath;
  final _SceneSpriteBehavior behavior;
  final double ambientPhase;
  final VoidCallback? onTap;

  @override
  _AnimatedSceneComponent build({
    required Vector2 sceneSize,
    required Rect backgroundRect,
  }) {
    final resolved = resolveRect(sceneSize, backgroundRect);
    return _SceneSpriteComponent(
      rect: resolved,
      assetPath: assetPath,
      behavior: behavior,
      ambientPhase: ambientPhase,
      onTap: onTap,
      entryDelay: entryDelay,
      entryOffset: entryOffset,
    );
  }
}

class _PetSpriteSpec extends _UiSpec {
  const _PetSpriteSpec({
    required super.rect,
    required this.assetPath,
    this.cropRect,
    this.onTap,
    this.animationFrameAssetPaths = const <String>[],
    this.animationFrameDurations = const <double>[],
    super.referenceSpace,
    required super.entryDelay,
    required super.entryOffset,
  });

  final String assetPath;
  final _RectFactor? cropRect;
  final VoidCallback? onTap;
  final List<String> animationFrameAssetPaths;
  final List<double> animationFrameDurations;

  @override
  _AnimatedSceneComponent build({
    required Vector2 sceneSize,
    required Rect backgroundRect,
  }) {
    final resolved = resolveRect(sceneSize, backgroundRect);
    return _PetSpriteComponent(
      rect: resolved,
      assetPath: assetPath,
      cropRect: cropRect,
      onTap: onTap,
      animationFrameAssetPaths: animationFrameAssetPaths,
      animationFrameDurations: animationFrameDurations,
      entryDelay: entryDelay,
      entryOffset: entryOffset,
    );
  }
}

// ignore: unused_element
enum _IconTileInteraction { paperStickerWobble }

class _SceneBackgroundComponent extends SpriteComponent {
  _SceneBackgroundComponent({
    required Sprite sprite,
    required Vector2 sceneSize,
    required this.fit,
  }) : _sceneSize = sceneSize.clone(),
       _sourceSize = sprite.srcSize.clone(),
       super(
         sprite: sprite,
         anchor: Anchor.center,
         position: sceneSize / 2,
         priority: 0,
       ) {
    paint.blendMode = BlendMode.srcOver;
  }

  Vector2 _sceneSize;
  final Vector2 _sourceSize;
  final _SceneBackgroundFit fit;
  bool _exitStarted = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _applyLayout();
    opacity = 0;
    scale = Vector2.all(1.018);

    add(
      OpacityEffect.to(
        1,
        EffectController(duration: 0.68, curve: Curves.easeOut),
      ),
    );

    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 1.32, curve: Curves.easeOutCubic),
      ),
    );
  }

  void updateSceneSize(Vector2 sceneSize) {
    _sceneSize = sceneSize.clone();
    _applyLayout();
  }

  void _applyLayout() {
    final scaleFactor = switch (fit) {
      _SceneBackgroundFit.cover => math.max(
        _sceneSize.x / _sourceSize.x,
        _sceneSize.y / _sourceSize.y,
      ),
      _SceneBackgroundFit.contain => math.min(
        _sceneSize.x / _sourceSize.x,
        _sceneSize.y / _sourceSize.y,
      ),
    };
    size = _sourceSize * scaleFactor;
    position = _sceneSize / 2;
  }

  Rect get layoutRect => Rect.fromCenter(
    center: Offset(position.x, position.y),
    width: size.x,
    height: size.y,
  );

  void startExit() {
    if (_exitStarted) {
      return;
    }
    _exitStarted = true;

    add(
      OpacityEffect.to(
        0,
        EffectController(duration: 0.24, curve: Curves.easeIn),
      ),
    );
  }
}

abstract class _AnimatedSceneComponent extends PositionComponent
    with HasPaint, TapCallbacks {
  _AnimatedSceneComponent({
    required super.position,
    required super.size,
    required this.entryDelay,
    required this.entryOffset,
    this.onTap,
    this.pressedScale = 0.94,
    Anchor anchor = Anchor.topLeft,
  }) : super(anchor: anchor);

  final double entryDelay;
  final double entryOffset;
  final VoidCallback? onTap;
  final double pressedScale;

  late final Vector2 _restPosition;
  bool _exitStarted = false;
  double _targetScale = 1;
  bool _pressed = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _restPosition = position.clone();
    position = _restPosition + Vector2(0, entryOffset);
    opacity = 0;

    add(
      MoveEffect.to(
        _restPosition,
        EffectController(
          duration: 0.44,
          startDelay: entryDelay,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    add(
      OpacityEffect.to(
        1,
        EffectController(
          duration: 0.36,
          startDelay: entryDelay,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  void playExit({required double delay}) {
    if (_exitStarted) {
      return;
    }
    _exitStarted = true;

    add(
      MoveEffect.by(
        Vector2(0, -(entryOffset * 0.7 + 18)),
        EffectController(
          duration: 0.28,
          startDelay: delay,
          curve: Curves.easeIn,
        ),
      ),
    );

    add(
      OpacityEffect.to(
        0,
        EffectController(
          duration: 0.24,
          startDelay: delay,
          curve: Curves.easeIn,
        ),
      ),
    );
  }

  Rect get sceneRect {
    final scaledWidth = size.x * scale.x;
    final scaledHeight = size.y * scale.y;
    return Rect.fromLTWH(
      position.x - (scaledWidth * anchor.x),
      position.y - (scaledHeight * anchor.y),
      scaledWidth,
      scaledHeight,
    );
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= 0 &&
        point.y >= 0 &&
        point.x <= size.x &&
        point.y <= size.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final nextScale =
        scale.x + ((_targetScale - scale.x) * math.min(1, dt * 16));
    scale.setValues(nextScale, nextScale);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_exitStarted) {
      return;
    }
    _pressed = true;
    _targetScale = pressedScale;
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_pressed && !_exitStarted) {
      triggerTapAction();
    }
    _pressed = false;
    _targetScale = 1;
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _pressed = false;
    _targetScale = 1;
    super.onTapCancel(event);
  }

  @protected
  void triggerTapAction() {
    onTap?.call();
  }
}

// ignore: unused_element
class _IconTileComponent extends _AnimatedSceneComponent {
  _IconTileComponent({
    required Rect rect,
    required this.icon,
    required this.label,
    required this.style,
    required this.interaction,
    required super.entryDelay,
    required super.entryOffset,
  }) : super(
         position: Vector2(rect.left, rect.top),
         size: Vector2(rect.width, rect.height),
       );

  final String icon;
  final String label;
  final _IconTileStyle style;
  final _IconTileInteraction interaction;

  static const double _paperStickerWobbleDuration = 0.34;
  double _paperStickerWobbleElapsed = _paperStickerWobbleDuration;

  @override
  void render(Canvas canvas) {
    final alpha = opacity.clamp(0, 1).toDouble();

    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.y * 0.07, size.x, size.y),
      Radius.circular(size.y * 0.28),
    );
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.y * 0.28),
    );

    canvas.drawRRect(
      shadowRect,
      Paint()..color = _applyOpacity(style.shadow, alpha),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()..color = _applyOpacity(style.fill, alpha),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = _applyOpacity(style.border, alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final iconCenter = Offset(size.x * 0.28, size.y * 0.5);
    canvas.drawCircle(
      iconCenter,
      size.y * 0.24,
      Paint()..color = _applyOpacity(style.iconBg, alpha),
    );

    _drawCenteredText(
      canvas,
      text: icon,
      center: iconCenter,
      fontSize: size.y * 0.42,
      color: _applyOpacity(style.iconFg, alpha),
      weight: FontWeight.w700,
    );

    _drawCenteredText(
      canvas,
      text: label,
      center: Offset(size.x * 0.68, size.y * 0.52),
      fontSize: size.y * 0.23,
      color: _applyOpacity(style.label, alpha),
      weight: FontWeight.w700,
    );

    if (interaction == _IconTileInteraction.paperStickerWobble) {
      _renderPaperStickerWobble(canvas, alpha);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_paperStickerWobbleElapsed < _paperStickerWobbleDuration) {
      _paperStickerWobbleElapsed = math.min(
        _paperStickerWobbleDuration,
        _paperStickerWobbleElapsed + dt,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (interaction == _IconTileInteraction.paperStickerWobble) {
      _paperStickerWobbleElapsed = 0;
    }
    super.onTapDown(event);
  }

  void _renderPaperStickerWobble(Canvas canvas, double alpha) {
    if (_paperStickerWobbleElapsed >= _paperStickerWobbleDuration) {
      return;
    }

    final progress = _paperStickerWobbleElapsed / _paperStickerWobbleDuration;
    final energy = Curves.easeOut.transform(1 - progress).clamp(0, 1);
    final shiftX =
        size.x * 0.040 * math.sin(_paperStickerWobbleElapsed * 40) * energy;
    final tilt = 0.030 * math.sin(_paperStickerWobbleElapsed * 22) * energy;
    final shadowOffsetX =
        size.x *
        0.016 *
        math.sin(_paperStickerWobbleElapsed * 40 + 0.8) *
        energy;
    final paperRect = Rect.fromLTWH(
      size.x * 0.10,
      size.y * 0.15,
      size.x * 0.70,
      size.y * 0.70,
    );
    final paperRRect = RRect.fromRectAndRadius(
      paperRect,
      Radius.circular(size.y * 0.035),
    );

    canvas.drawRRect(
      paperRRect.shift(Offset(shadowOffsetX, size.y * 0.012 * energy)),
      Paint()..color = const Color(0x332E2014).withValues(alpha: alpha * 0.90),
    );

    canvas.save();
    canvas.translate(
      paperRect.center.dx,
      paperRect.top + (paperRect.height * 0.10),
    );
    canvas.translate(shiftX, 0);
    canvas.rotate(tilt);
    canvas.translate(
      -paperRect.center.dx,
      -(paperRect.top + (paperRect.height * 0.10)),
    );

    canvas.drawRRect(
      paperRRect,
      Paint()..color = const Color(0xFFF5EAD7).withValues(alpha: alpha * 0.92),
    );
    canvas.drawRRect(
      paperRRect,
      Paint()
        ..color = const Color(0xFF9B7960).withValues(alpha: alpha * 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final checkboxSize = size.y * 0.072;
    final checkboxLeft = paperRect.left + (paperRect.width * 0.14);
    final lineLeft = checkboxLeft + checkboxSize + (paperRect.width * 0.08);
    final lineRight = paperRect.right - (paperRect.width * 0.12);
    final rowYs = <double>[
      paperRect.top + (paperRect.height * 0.24),
      paperRect.top + (paperRect.height * 0.46),
      paperRect.top + (paperRect.height * 0.68),
    ];

    for (final rowY in rowYs) {
      final boxRect = Rect.fromLTWH(
        checkboxLeft,
        rowY - (checkboxSize * 0.5),
        checkboxSize,
        checkboxSize,
      );
      canvas.drawRect(
        boxRect,
        Paint()
          ..color = const Color(0xFF8A6D57).withValues(alpha: alpha * 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final checkPath = Path()
        ..moveTo(
          boxRect.left + checkboxSize * 0.18,
          boxRect.top + checkboxSize * 0.52,
        )
        ..lineTo(
          boxRect.left + checkboxSize * 0.42,
          boxRect.top + checkboxSize * 0.76,
        )
        ..lineTo(
          boxRect.left + checkboxSize * 0.84,
          boxRect.top + checkboxSize * 0.24,
        );
      canvas.drawPath(
        checkPath,
        Paint()
          ..color = const Color(0xFF8A6D57).withValues(alpha: alpha * 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawLine(
        Offset(lineLeft, rowY),
        Offset(lineRight, rowY),
        Paint()
          ..color = const Color(0xCC9C846F).withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    canvas.restore();
  }
}

enum _SceneSpriteBehavior { taskNote, shopBasket, familyPhoto }

class _SceneSpriteComponent extends _AnimatedSceneComponent
    with HasGameReference<HomeSceneGame> {
  _SceneSpriteComponent({
    required Rect rect,
    required this.assetPath,
    required this.behavior,
    required this.ambientPhase,
    required super.entryDelay,
    required super.entryOffset,
    super.onTap,
  }) : super(
         position: _positionForRect(rect, behavior),
         size: Vector2(rect.width, rect.height),
         anchor: _anchorForBehavior(behavior),
         pressedScale: behavior == _SceneSpriteBehavior.taskNote ? 0.94 : 1,
       );

  final String assetPath;
  final _SceneSpriteBehavior behavior;
  final double ambientPhase;

  Sprite? _sprite;
  final Paint _spritePaint = Paint();
  double _ambientTime = 0;
  double? _tapElapsed;
  double? _actionCountdown;
  bool _tapLocked = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = Sprite(await game.images.load(assetPath));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ambientTime += dt;
    final tapAngle = _updateTapAnimation(dt);
    angle = _ambientAngle() + tapAngle;

    final countdown = _actionCountdown;
    if (countdown == null) {
      return;
    }

    final nextCountdown = countdown - dt;
    if (nextCountdown <= 0) {
      _actionCountdown = null;
      onTap?.call();
      return;
    }
    _actionCountdown = nextCountdown;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sprite = _sprite;
    if (sprite == null) {
      return;
    }

    _spritePaint.color = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: opacity.clamp(0, 1).toDouble());
    sprite.render(canvas, size: size, overridePaint: _spritePaint);
  }

  @override
  void triggerTapAction() {
    if (onTap == null || _tapLocked) {
      return;
    }

    _tapLocked = true;
    _tapElapsed = 0;
    _actionCountdown = _tapActionDelay();
  }

  double _ambientAngle() {
    return switch (behavior) {
      _SceneSpriteBehavior.taskNote =>
        math.sin((_ambientTime * 1.8) + ambientPhase) * 0.004,
      _SceneSpriteBehavior.shopBasket =>
        math.sin((_ambientTime * 1.5) + ambientPhase) * 0.014,
      _SceneSpriteBehavior.familyPhoto =>
        math.sin((_ambientTime * 1.3) + ambientPhase) * 0.008,
    };
  }

  double _updateTapAnimation(double dt) {
    final elapsed = _tapElapsed;
    if (elapsed == null) {
      return 0;
    }

    final nextElapsed = elapsed + dt;
    final duration = _tapDuration();
    if (nextElapsed >= duration) {
      _tapElapsed = null;
      _tapLocked = false;
      return 0;
    }

    _tapElapsed = nextElapsed;
    final progress = nextElapsed / duration;
    return switch (behavior) {
      _SceneSpriteBehavior.taskNote =>
        progress < 0.55
            ? -0.034 * Curves.easeOut.transform(progress / 0.55)
            : -0.034 *
                      (1 -
                          Curves.easeInOut.transform(
                            (progress - 0.55) / 0.45,
                          )) +
                  (0.004 * Curves.easeOut.transform((progress - 0.55) / 0.45)),
      _SceneSpriteBehavior.shopBasket =>
        math.sin(progress * math.pi * 2.2) * 0.080 * (1 - (progress * 0.35)),
      _SceneSpriteBehavior.familyPhoto =>
        progress < 0.5
            ? 0.078 * Curves.easeOut.transform(progress / 0.5)
            : 0.078 * (1 - Curves.easeIn.transform((progress - 0.5) / 0.5)),
    };
  }

  double _tapDuration() {
    return switch (behavior) {
      _SceneSpriteBehavior.taskNote => 0.22,
      _SceneSpriteBehavior.shopBasket => 0.22,
      _SceneSpriteBehavior.familyPhoto => 0.24,
    };
  }

  double _tapActionDelay() {
    return switch (behavior) {
      _SceneSpriteBehavior.taskNote => 0.18,
      _SceneSpriteBehavior.shopBasket => 0.20,
      _SceneSpriteBehavior.familyPhoto => 0.21,
    };
  }

  static Anchor _anchorForBehavior(_SceneSpriteBehavior behavior) {
    return switch (behavior) {
      _SceneSpriteBehavior.taskNote => Anchor.topCenter,
      _SceneSpriteBehavior.shopBasket => Anchor.topCenter,
      _SceneSpriteBehavior.familyPhoto => Anchor.center,
    };
  }

  static Vector2 _positionForRect(Rect rect, _SceneSpriteBehavior behavior) {
    return switch (_anchorForBehavior(behavior)) {
      Anchor.topCenter => Vector2(rect.center.dx, rect.top),
      Anchor.bottomCenter => Vector2(rect.center.dx, rect.bottom),
      _ => Vector2(rect.center.dx, rect.center.dy),
    };
  }
}

class _PetSpriteComponent extends _AnimatedSceneComponent
    with HasGameReference<HomeSceneGame> {
  _PetSpriteComponent({
    required Rect rect,
    required this.assetPath,
    this.cropRect,
    this.animationFrameAssetPaths = const <String>[],
    this.animationFrameDurations = const <double>[],
    required super.entryDelay,
    required super.entryOffset,
    super.onTap,
  }) : super(
         position: Vector2(rect.left, rect.top),
         size: Vector2(rect.width, rect.height),
       );

  final String assetPath;
  final _RectFactor? cropRect;
  final List<String> animationFrameAssetPaths;
  final List<double> animationFrameDurations;

  Sprite? _sprite;
  final List<Sprite> _animationFrames = <Sprite>[];
  double _animationElapsed = 0;
  int _animationIndex = 0;
  final Paint _spritePaint = Paint();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (animationFrameAssetPaths.isNotEmpty) {
      for (final frameAssetPath in animationFrameAssetPaths) {
        _animationFrames.add(Sprite(await game.images.load(frameAssetPath)));
      }
      return;
    }

    final image = await game.images.load(assetPath);
    final clip = cropRect;
    if (clip == null) {
      _sprite = Sprite(image);
      return;
    }

    final sourceSize = Vector2(image.width.toDouble(), image.height.toDouble());
    final sourceRect = clip.resolve(sourceSize);
    _sprite = Sprite(
      image,
      srcPosition: Vector2(sourceRect.left, sourceRect.top),
      srcSize: Vector2(sourceRect.width, sourceRect.height),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_animationFrames.length < 2) {
      return;
    }

    _animationElapsed += dt;
    while (_animationElapsed >= _frameDurationFor(_animationIndex)) {
      _animationElapsed -= _frameDurationFor(_animationIndex);
      _animationIndex = (_animationIndex + 1) % _animationFrames.length;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final sprite = _activeSprite;
    if (sprite == null) {
      return;
    }

    _spritePaint.color = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: opacity.clamp(0, 1).toDouble());
    sprite.render(canvas, size: size, overridePaint: _spritePaint);
  }

  Sprite? get _activeSprite {
    if (_animationFrames.isNotEmpty) {
      return _animationFrames[_animationIndex];
    }
    return _sprite;
  }

  double _frameDurationFor(int frameIndex) {
    if (frameIndex >= 0 && frameIndex < animationFrameDurations.length) {
      return animationFrameDurations[frameIndex];
    }
    return 0.18;
  }
}

class _TaskPanelEntry {
  const _TaskPanelEntry({
    required this.label,
    required this.highlighted,
    this.points = 10,
  });

  final String label;
  final bool highlighted;
  final int points;

  _TaskPanelEntry copyWith({String? label, bool? highlighted, int? points}) {
    return _TaskPanelEntry(
      label: label ?? this.label,
      highlighted: highlighted ?? this.highlighted,
      points: points ?? this.points,
    );
  }
}

class _TaskPanelOverlay extends PositionComponent
    with HasGameReference<HomeSceneGame>, TapCallbacks {
  _TaskPanelOverlay({
    required Vector2 sceneSize,
    required this.isTablet,
    required this.panelOriginRectProvider,
    required this.onRemoved,
    required this.onTaskItemLongPress,
    required this.onAddTaskTap,
    required this.taskEntries,
  }) : _sceneSize = sceneSize.clone(),
       super(
         position: Vector2.zero(),
         size: sceneSize.clone(),
         anchor: Anchor.topLeft,
         priority: 88,
       );

  static const String _taskBoardAsset = 'images/ui/sprites/task.png';
  static const String _taskStickerAsset = 'images/ui/task_add_sticker.png';
  static const String _taskRowFieldAsset = 'images/ui/task_row_field_idle.png';
  static const String _taskCheckboxEmptyAsset =
      'images/ui/task_checkbox_empty.png';

  final bool isTablet;
  final Rect? Function() panelOriginRectProvider;
  final VoidCallback onRemoved;
  final void Function(String taskLabel, Offset globalPosition)?
  onTaskItemLongPress;
  final Future<void> Function()? onAddTaskTap;
  final List<_TaskPanelEntry> taskEntries;
  Vector2 _sceneSize;

  static const int _maxTaskCount = 12;
  static const int _pageSize = 4;
  static const double _rowWidthFactor = 0.84;
  static const double _rowHeightFactor = 0.108;
  static const double _addButtonWidthFactor = 0.58;
  static const double _addButtonHeightFactor = 0.078;
  static const double _firstRowTopPaddingFactor = 0.24;
  static const double _minRowGapFactor = 0.16;
  static const double _panelBottomPaddingFactor = 0.088;
  static const double _rowToButtonGapFactor = 0.30;
  static const double _buttonToButtonGapFactor = 0.18;
  static const double _titleYFactor = 0.082;
  static const double _minPanelHeightFactor = 0.72;
  static const double _panelOpenDuration = 0.32;
  static const double _panelCloseDuration = 0.24;
  static const double _backdropFadeDuration = 0.22;
  static const double _backdropTargetOpacity = 0.22;
  static const double _contentEnterDelay = 0.30;
  static const double _contentEnterStep = 0.08;
  static const double _contentEnterDuration = 0.28;
  static const double _contentExitDuration = 0.16;
  static const double _panelCloseStartDelay = 0.07;

  late final PositionComponent _panelRoot;
  late final Vector2 _basePanelSize;
  late final SpriteComponent _panelBoard;
  late final _TaskPanelActionButton _addTaskButton;
  late final PositionComponent _titleComponent;
  final List<_TaskPanelItem> _taskItems = <_TaskPanelItem>[];
  _TaskPanelActionButton? _nextPageButton;
  RectangleComponent? _backdropLayer;
  bool _panelReady = false;
  bool _exitStarted = false;
  double? _removeAfterSeconds;
  int _currentPage = 0;

  int get _totalPageCount =>
      math.max(1, (taskEntries.length + _pageSize - 1) ~/ _pageSize);

  bool get _showsPagination => taskEntries.length > _pageSize;

  List<_TaskPanelEntry> get _visibleEntries {
    final start = _currentPage * _pageSize;
    if (start >= taskEntries.length) {
      return const <_TaskPanelEntry>[];
    }
    final end = math.min(start + _pageSize, taskEntries.length);
    return taskEntries.sublist(start, end);
  }

  String get _nextPageLabel {
    if (_currentPage > 0) {
      return '\u4e0a\u4e00\u9875 $_currentPage/$_totalPageCount';
    }

    final nextPageNumber = _currentPage + 2;
    return '\u4e0b\u4e00\u9875 $nextPageNumber/$_totalPageCount';
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final backdrop = RectangleComponent(
      position: Vector2.zero(),
      size: _sceneSize.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xFF0F0A05),
      priority: 0,
    )..opacity = 0;
    _backdropLayer = backdrop;
    add(backdrop);
    backdrop.add(
      OpacityEffect.to(
        _backdropTargetOpacity,
        EffectController(
          duration: _backdropFadeDuration,
          curve: Curves.easeOut,
        ),
      ),
    );

    final boardAtlas = await TaskPanelSpriteCatalog.atlasAsset.load();
    final boardSprite = TaskPanelSpriteCatalog(
      boardAtlas,
    ).board.toFlameSprite(await game.images.load(_taskBoardAsset));
    final stickerImage = await game.images.load(_taskStickerAsset);
    final stickerSprite = Sprite(stickerImage);

    _basePanelSize = _panelBoardSize();
    final originRect = panelOriginRectProvider();
    final panelTargetPosition = _openPanelTargetPosition();

    _panelRoot = PositionComponent(
      position: _initialPanelPosition(originRect),
      size: _basePanelSize.clone(),
      anchor: Anchor.center,
      scale: Vector2.all(_initialPanelScale(originRect)),
      priority: 2,
    );
    add(_panelRoot);

    final boardComponent = SpriteComponent(
      sprite: boardSprite,
      position: _panelRoot.size / 2,
      size: _panelRoot.size,
      anchor: Anchor.center,
      priority: 0,
    );
    _panelBoard = boardComponent;
    _panelRoot.add(boardComponent);
    _panelRoot.add(
      MoveEffect.to(
        panelTargetPosition,
        EffectController(
          duration: _panelOpenDuration,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    _panelRoot.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(
          duration: _panelOpenDuration,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    final initialEntries = _visibleEntries;
    final initialLayout = _buildLayout(
      initialEntries.length,
      showPagination: _showsPagination,
    );
    _resizePanelBoard(initialLayout.panelHeight);
    final rowWidth = _basePanelSize.x * _rowWidthFactor;
    final rowHeight = _basePanelSize.y * _rowHeightFactor;
    final firstRowY = initialLayout.firstRowCenterY;
    final rowGap = initialLayout.rowGap;

    for (var index = 0; index < initialEntries.length; index++) {
      final entry = initialEntries[index];
      final target = Vector2(
        _panelRoot.size.x * 0.5,
        firstRowY + (index * (rowHeight + rowGap)),
      );
      final item = _buildTaskPanelItem(
        label: entry.label,
        highlighted: entry.highlighted,
        size: Vector2(rowWidth, rowHeight),
      )..anchor = Anchor.center;

      _taskItems.add(item);
      _panelRoot.add(item);
      _animateContentEntrance(
        item,
        target,
        startDelay: _contentEnterDelay + (index * _contentEnterStep),
        verticalOffset: rowHeight * 0.75,
      );
    }

    final addTaskButton = _TaskPanelActionButton(
      label: '\u6DFB\u52A0\u4EFB\u52A1',
      size: Vector2(
        _basePanelSize.x * _addButtonWidthFactor,
        _basePanelSize.y * _addButtonHeightFactor,
      ),
      onTap: () => onAddTaskTap?.call(),
    )..anchor = Anchor.center;
    _addTaskButton = addTaskButton;
    _panelRoot.add(addTaskButton);
    _animateContentEntrance(
      addTaskButton,
      Vector2(_panelRoot.size.x * 0.5, initialLayout.addButtonCenterY),
      startDelay:
          _contentEnterDelay +
          (initialEntries.length * _contentEnterStep) +
          0.06,
      verticalOffset: rowHeight * 0.88,
      initialScale: 0.94,
    );

    if (_showsPagination && initialLayout.nextPageButtonCenterY != null) {
      final nextPageButton = _TaskPanelActionButton(
        label: _nextPageLabel,
        size: Vector2(
          _basePanelSize.x * _addButtonWidthFactor,
          _basePanelSize.y * _addButtonHeightFactor,
        ),
        onTap: _goToNextPage,
        showPlusPrefix: false,
      )..anchor = Anchor.center;
      _nextPageButton = nextPageButton;
      _panelRoot.add(nextPageButton);
      _animateContentEntrance(
        nextPageButton,
        Vector2(_panelRoot.size.x * 0.5, initialLayout.nextPageButtonCenterY!),
        startDelay:
            _contentEnterDelay + (initialEntries.length * _contentEnterStep),
        verticalOffset: rowHeight * 0.82,
        initialScale: 0.94,
      );
    }

    final titleAspectRatio = stickerImage.height / stickerImage.width;
    final titleWidth = _panelRoot.size.x * 0.42;
    final titleSize = Vector2(titleWidth, titleWidth * titleAspectRatio);
    final title = PositionComponent(
      size: titleSize,
      anchor: Anchor.center,
      priority: 3,
    );
    title.add(
      SpriteComponent(
        sprite: stickerSprite,
        position: title.size / 2,
        size: title.size,
        anchor: Anchor.center,
      ),
    );
    title.add(
      _TaskPanelPushPinComponent(
        position: Vector2(title.size.x * 0.5, title.size.y * 0.05),
        size: Vector2.all(title.size.y * 0.64),
        anchor: Anchor.center,
      ),
    );
    title.add(
      TextComponent(
        text: '\u4efb\u52a1\u6e05\u5355',
        position: Vector2(title.size.x * 0.5, title.size.y * 0.50),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: TextStyle(
            color: const Color(0xFF5B4327),
            fontSize: isTablet ? 24 : 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
    _titleComponent = title;
    _panelRoot.add(title);
    _animateContentEntrance(
      title,
      Vector2(_panelRoot.size.x * 0.5, initialLayout.titleCenterY),
      startDelay: _contentEnterDelay + 0.02,
      verticalOffset: -(titleSize.y * 0.45),
      initialScale: 0.92,
    );

    _panelReady = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final removeAfterSeconds = _removeAfterSeconds;
    if (removeAfterSeconds == null) {
      return;
    }

    final nextValue = removeAfterSeconds - dt;
    if (nextValue <= 0) {
      _removeAfterSeconds = null;
      removeFromParent();
      return;
    }

    _removeAfterSeconds = nextValue;
  }

  Vector2 _openPanelTargetPosition() => _sceneSize / 2;

  Vector2 _initialPanelPosition(Rect? originRect) {
    if (originRect == null) {
      final center = _openPanelTargetPosition();
      return Vector2(center.x, center.y + (_sceneSize.y * 0.06));
    }
    return Vector2(originRect.center.dx, originRect.center.dy);
  }

  double _initialPanelScale(Rect? originRect) {
    if (originRect == null) {
      return 0.36;
    }

    final widthScale = originRect.width / _basePanelSize.x;
    final heightScale = originRect.height / _basePanelSize.y;
    return (((widthScale + heightScale) * 0.5).clamp(0.14, 0.42)).toDouble();
  }

  void _animateContentEntrance(
    PositionComponent component,
    Vector2 target, {
    required double startDelay,
    required double verticalOffset,
    double initialScale = 0.90,
  }) {
    component.position = target + Vector2(0, verticalOffset);
    component.scale = Vector2.all(initialScale);
    component.add(
      MoveEffect.to(
        target,
        EffectController(
          duration: _contentEnterDuration,
          startDelay: startDelay,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    component.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(
          duration: _contentEnterDuration + 0.02,
          startDelay: startDelay,
          curve: Curves.easeOutBack,
        ),
      ),
    );
  }

  Vector2 _contentExitTarget(PositionComponent component) {
    final panelCenter = Vector2(
      _panelRoot.size.x * 0.5,
      _panelRoot.size.y * 0.48,
    );
    return Vector2(
      component.position.x + ((panelCenter.x - component.position.x) * 0.35),
      component.position.y + ((panelCenter.y - component.position.y) * 0.35),
    );
  }

  void _animateContentExit(
    PositionComponent component, {
    double startDelay = 0,
  }) {
    _clearTransformEffects(component);
    component.add(
      MoveEffect.to(
        _contentExitTarget(component),
        EffectController(
          duration: _contentExitDuration,
          startDelay: startDelay,
          curve: Curves.easeInCubic,
        ),
      ),
    );
    component.add(
      ScaleEffect.to(
        Vector2.all(0.82),
        EffectController(
          duration: _contentExitDuration,
          startDelay: startDelay,
          curve: Curves.easeInCubic,
        ),
      ),
    );
  }

  void _clearTransformEffects(PositionComponent component) {
    final effects = component.children
        .where((child) => child is MoveEffect || child is ScaleEffect)
        .toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }

  void _clearOpacityEffects(PositionComponent component) {
    final effects = component.children.whereType<OpacityEffect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= 0 &&
        point.y >= 0 &&
        point.x <= size.x &&
        point.y <= size.y;
  }

  _TaskPanelLayout _buildLayout(int rowCount, {required bool showPagination}) {
    final safeRowCount = math.max(1, rowCount);
    final rowHeight = _basePanelSize.y * _rowHeightFactor;
    final addButtonHeight = _basePanelSize.y * _addButtonHeightFactor;
    final nextPageButtonHeight = showPagination
        ? _basePanelSize.y * _addButtonHeightFactor
        : 0.0;
    final topPadding = _basePanelSize.y * _firstRowTopPaddingFactor;
    final minGap = rowHeight * _minRowGapFactor;
    final bottomPadding = _basePanelSize.y * _panelBottomPaddingFactor;
    final buttonGap = rowHeight * _buttonToButtonGapFactor;

    final requiredPanelHeight =
        topPadding +
        (safeRowCount * rowHeight) +
        ((safeRowCount - 1) * minGap) +
        (showPagination ? nextPageButtonHeight + buttonGap : 0.0) +
        addButtonHeight +
        bottomPadding +
        (rowHeight * _rowToButtonGapFactor);
    final minPanelHeight = _basePanelSize.y * _minPanelHeightFactor;
    final panelHeight = math.max(minPanelHeight, requiredPanelHeight);

    final addButtonCenterY =
        panelHeight - bottomPadding - (addButtonHeight * 0.5);
    final nextPageButtonCenterY = showPagination
        ? addButtonCenterY -
              (addButtonHeight * 0.5) -
              buttonGap -
              (nextPageButtonHeight * 0.5)
        : null;
    final topActionCenterY = nextPageButtonCenterY ?? addButtonCenterY;
    final topActionHeight = showPagination
        ? nextPageButtonHeight
        : addButtonHeight;
    final rowsBottomCenter =
        topActionCenterY -
        (topActionHeight * 0.5) -
        (rowHeight * _rowToButtonGapFactor) -
        (rowHeight * 0.5);

    double rowGap = 0;
    if (safeRowCount > 1) {
      rowGap =
          ((rowsBottomCenter - topPadding) / (safeRowCount - 1)) - rowHeight;
      rowGap = math.max(minGap, rowGap);
    }

    return _TaskPanelLayout(
      panelHeight: panelHeight,
      firstRowCenterY: topPadding,
      rowGap: rowGap,
      addButtonCenterY: addButtonCenterY,
      nextPageButtonCenterY: nextPageButtonCenterY,
      titleCenterY: panelHeight * _titleYFactor,
    );
  }

  void _resizePanelBoard(double panelHeight) {
    final nextSize = Vector2(_basePanelSize.x, panelHeight);
    if ((_panelRoot.size.y - panelHeight).abs() < 0.1) {
      return;
    }

    _panelRoot.size = nextSize;
    _panelBoard.size = nextSize;
    _panelBoard.position = nextSize / 2;
  }

  void _clampCurrentPage() {
    final maxPageIndex = math.max(0, _totalPageCount - 1);
    _currentPage = _currentPage.clamp(0, maxPageIndex);
  }

  void _goToNextPage() {
    if (!_showsPagination || !_panelReady) {
      return;
    }

    if (_currentPage > 0) {
      _currentPage -= 1;
    } else if (_currentPage < _totalPageCount - 1) {
      _currentPage += 1;
    } else {
      return;
    }

    _refreshVisiblePage(animated: false);
  }

  _TaskPanelItem _buildTaskPanelItem({
    required String label,
    required bool highlighted,
    required Vector2 size,
  }) {
    return _TaskPanelItem(
      highlighted: highlighted,
      label: label,
      onLongPress: (itemLabel, scenePoint) {
        onTaskItemLongPress?.call(
          itemLabel,
          Offset(scenePoint.x, scenePoint.y),
        );
      },
      size: size,
    );
  }

  void replaceEntries(List<_TaskPanelEntry> entries) {
    taskEntries
      ..clear()
      ..addAll(entries);

    _clampCurrentPage();

    if (!_panelReady) {
      return;
    }

    _refreshVisiblePage(animated: false);
  }

  bool addTaskItemFromEntry(_TaskPanelEntry entry) {
    if (!_panelReady) {
      return false;
    }

    final normalized = entry.label.trim();
    if (normalized.isEmpty || taskEntries.length >= _maxTaskCount) {
      return false;
    }

    if (taskEntries.any((item) => item.label == normalized)) {
      return false;
    }

    taskEntries.add(entry.copyWith(label: normalized));
    _refreshVisiblePage(animated: true);
    return true;
  }

  bool updateTaskItem({
    required String oldTaskLabel,
    required String newTaskLabel,
  }) {
    if (!_panelReady) {
      return false;
    }

    final normalized = newTaskLabel.trim();
    if (normalized.isEmpty) {
      return false;
    }

    final index = taskEntries.indexWhere((item) => item.label == oldTaskLabel);
    if (index < 0) {
      return false;
    }

    final hasDuplicate = taskEntries.any(
      (item) => item.label == normalized && item.label != oldTaskLabel,
    );
    if (hasDuplicate) {
      return false;
    }

    if (normalized == oldTaskLabel) {
      return true;
    }

    taskEntries[index] = taskEntries[index].copyWith(label: normalized);
    _refreshVisiblePage(animated: false);
    return true;
  }

  void removeTaskItem(String taskLabel) {
    if (!_panelReady) {
      return;
    }

    final index = taskEntries.indexWhere((item) => item.label == taskLabel);
    if (index < 0) {
      return;
    }

    taskEntries.removeAt(index);
    _clampCurrentPage();
    _refreshVisiblePage(animated: true);
  }

  void _clearMoveEffects(PositionComponent component) {
    final effects = component.children.whereType<MoveEffect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }

  void _rebuildVisibleTaskItems({required bool animated}) {
    for (final item in _taskItems) {
      item.removeFromParent();
    }
    _taskItems.clear();

    final rowWidth = _basePanelSize.x * _rowWidthFactor;
    final rowHeight = _basePanelSize.y * _rowHeightFactor;
    final initialY = animated
        ? _panelRoot.size.y + rowHeight
        : _panelRoot.size.y * 0.5;

    for (final entry in _visibleEntries) {
      final item =
          _buildTaskPanelItem(
              label: entry.label,
              highlighted: entry.highlighted,
              size: Vector2(rowWidth, rowHeight),
            )
            ..position = Vector2(_panelRoot.size.x * 0.5, initialY)
            ..anchor = Anchor.center;
      _taskItems.add(item);
      _panelRoot.add(item);
    }
  }

  void _syncNextPageButton({required bool animated}) {
    final shouldShow = _showsPagination;
    final buttonSize = Vector2(
      _basePanelSize.x * _addButtonWidthFactor,
      _basePanelSize.y * _addButtonHeightFactor,
    );

    if (!shouldShow) {
      _nextPageButton?.removeFromParent();
      _nextPageButton = null;
      return;
    }

    final currentButton = _nextPageButton;
    if (currentButton == null || currentButton.label != _nextPageLabel) {
      final replacement =
          _TaskPanelActionButton(
              label: _nextPageLabel,
              size: buttonSize,
              onTap: _goToNextPage,
              showPlusPrefix: false,
            )
            ..position =
                currentButton?.position.clone() ??
                Vector2(
                  _panelRoot.size.x * 0.5,
                  _panelRoot.size.y + buttonSize.y,
                )
            ..anchor = Anchor.center;
      currentButton?.removeFromParent();
      _nextPageButton = replacement;
      _panelRoot.add(replacement);
      if (!animated) {
        replacement.position = Vector2(
          _panelRoot.size.x * 0.5,
          replacement.position.y,
        );
      }
    }
  }

  void _refreshVisiblePage({required bool animated}) {
    _clampCurrentPage();
    _rebuildVisibleTaskItems(animated: animated);
    _syncNextPageButton(animated: animated);
    _relayoutTaskRows(animated: animated);
  }

  void _relayoutTaskRows({required bool animated}) {
    final rowCount = _visibleEntries.length;
    final rowHeight = _basePanelSize.y * _rowHeightFactor;
    final layout = _buildLayout(rowCount, showPagination: _showsPagination);

    _resizePanelBoard(layout.panelHeight);

    for (var i = 0; i < _taskItems.length; i++) {
      final item = _taskItems[i];
      _clearMoveEffects(item);
      final target = Vector2(
        _panelRoot.size.x * 0.5,
        layout.firstRowCenterY + (i * (rowHeight + layout.rowGap)),
      );
      if (animated) {
        item.add(
          MoveEffect.to(
            target,
            EffectController(duration: 0.22, curve: Curves.easeOutCubic),
          ),
        );
      } else {
        item.position = target;
      }
    }

    final addButtonTarget = Vector2(
      _panelRoot.size.x * 0.5,
      layout.addButtonCenterY,
    );
    _clearMoveEffects(_addTaskButton);
    if (animated) {
      _addTaskButton.add(
        MoveEffect.to(
          addButtonTarget,
          EffectController(duration: 0.22, curve: Curves.easeOutCubic),
        ),
      );
    } else {
      _addTaskButton.position = addButtonTarget;
    }

    final nextPageButton = _nextPageButton;
    final nextPageButtonCenterY = layout.nextPageButtonCenterY;
    if (nextPageButton != null && nextPageButtonCenterY != null) {
      final nextButtonTarget = Vector2(
        _panelRoot.size.x * 0.5,
        nextPageButtonCenterY,
      );
      _clearMoveEffects(nextPageButton);
      if (animated) {
        nextPageButton.add(
          MoveEffect.to(
            nextButtonTarget,
            EffectController(duration: 0.22, curve: Curves.easeOutCubic),
          ),
        );
      } else {
        nextPageButton.position = nextButtonTarget;
      }
    }

    final titleTarget = Vector2(_panelRoot.size.x * 0.5, layout.titleCenterY);
    _clearMoveEffects(_titleComponent);
    if (animated) {
      _titleComponent.add(
        MoveEffect.to(
          titleTarget,
          EffectController(duration: 0.22, curve: Curves.easeOutCubic),
        ),
      );
    } else {
      _titleComponent.position = titleTarget;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_exitStarted) {
      return;
    }

    if (!_panelReady) {
      startExit();
      super.onTapDown(event);
      return;
    }

    final panelPoint = _panelRoot.parentToLocal(event.localPosition);
    for (final item in _taskItems) {
      if (_isPointInCenteredComponent(item, panelPoint)) {
        super.onTapDown(event);
        return;
      }
    }

    final tappedInsidePanel = _panelRoot.containsLocalPoint(panelPoint);
    if (!tappedInsidePanel) {
      startExit();
    }

    super.onTapDown(event);
  }

  bool _isPointInCenteredComponent(
    PositionComponent component,
    Vector2 pointInParent,
  ) {
    final left = component.position.x - (component.size.x * 0.5);
    final right = component.position.x + (component.size.x * 0.5);
    final top = component.position.y - (component.size.y * 0.5);
    final bottom = component.position.y + (component.size.y * 0.5);
    return pointInParent.x >= left &&
        pointInParent.x <= right &&
        pointInParent.y >= top &&
        pointInParent.y <= bottom;
  }

  void updateSceneSize(Vector2 sceneSize) {
    _sceneSize = sceneSize.clone();
    size = _sceneSize.clone();
    _backdropLayer?.size = _sceneSize.clone();
  }

  void startExit() {
    if (_exitStarted) {
      return;
    }
    _exitStarted = true;

    for (final item in _taskItems) {
      _animateContentExit(item);
    }
    _animateContentExit(_titleComponent);
    _animateContentExit(_addTaskButton, startDelay: 0.02);
    final nextPageButton = _nextPageButton;
    if (nextPageButton != null) {
      _animateContentExit(nextPageButton, startDelay: 0.01);
    }

    final backdrop = _backdropLayer;
    if (backdrop != null) {
      _clearOpacityEffects(backdrop);
      backdrop.add(
        OpacityEffect.to(
          0,
          EffectController(
            duration: _backdropFadeDuration,
            curve: Curves.easeIn,
          ),
        ),
      );
    }

    final originRect = panelOriginRectProvider();
    _clearTransformEffects(_panelRoot);
    _panelRoot.add(
      MoveEffect.to(
        _initialPanelPosition(originRect),
        EffectController(
          duration: _panelCloseDuration,
          startDelay: _panelCloseStartDelay,
          curve: Curves.easeInCubic,
        ),
      ),
    );
    _panelRoot.add(
      ScaleEffect.to(
        Vector2.all(_initialPanelScale(originRect)),
        EffectController(
          duration: _panelCloseDuration,
          startDelay: _panelCloseStartDelay,
          curve: Curves.easeInCubic,
        ),
      ),
    );
    _removeAfterSeconds = _panelCloseStartDelay + _panelCloseDuration + 0.03;
  }

  Vector2 _panelBoardSize() {
    final width = math.min(
      _sceneSize.x * (isTablet ? 0.44 : 0.70),
      _sceneSize.y * (isTablet ? 0.31 : 0.44),
    );
    return Vector2(width, width * (812 / 510));
  }

  @override
  void onRemove() {
    onRemoved();
    super.onRemove();
  }
}

class _TaskPanelLayout {
  const _TaskPanelLayout({
    required this.panelHeight,
    required this.firstRowCenterY,
    required this.rowGap,
    required this.addButtonCenterY,
    required this.nextPageButtonCenterY,
    required this.titleCenterY,
  });

  final double panelHeight;
  final double firstRowCenterY;
  final double rowGap;
  final double addButtonCenterY;
  final double? nextPageButtonCenterY;
  final double titleCenterY;
}

class _TaskPanelActionButton extends PositionComponent
    with HasGameReference<HomeSceneGame>, TapCallbacks {
  _TaskPanelActionButton({
    required this.label,
    required Vector2 size,
    this.onTap,
    this.showPlusPrefix = true,
  }) : super(size: size, anchor: Anchor.center);

  final String label;
  final VoidCallback? onTap;
  final bool showPlusPrefix;
  bool _pressed = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final stickerSprite = Sprite(
      await game.images.load(_TaskPanelOverlay._taskStickerAsset),
    );

    add(
      SpriteComponent(
        sprite: stickerSprite,
        position: size / 2,
        size: size,
        anchor: Anchor.center,
      ),
    );
    add(
      TextComponent(
        text: showPlusPrefix ? '+ $label' : label,
        position: Vector2(size.x * 0.5, size.y * 0.52),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: TextStyle(
            color: const Color(0xFF5A4228),
            fontSize: size.y * 0.33,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= 0 &&
        point.y >= 0 &&
        point.x <= size.x &&
        point.y <= size.y;
  }

  @override
  void onTapDown(TapDownEvent event) {
    _pressed = true;
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_pressed) {
      onTap?.call();
    }
    _pressed = false;
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _pressed = false;
    super.onTapCancel(event);
  }
}

class _TaskPanelItem extends PositionComponent
    with HasGameReference<HomeSceneGame>, TapCallbacks {
  _TaskPanelItem({
    required this.highlighted,
    required this.label,
    required this.onLongPress,
    required Vector2 size,
  }) : super(size: size, anchor: Anchor.center);

  final bool highlighted;
  final String label;
  final void Function(String label, Vector2 scenePoint)? onLongPress;
  bool _legacyIconCleanupDone = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final checkboxSprite = Sprite(
      await game.images.load(_TaskPanelOverlay._taskCheckboxEmptyAsset),
    );
    final rowFieldSprite = Sprite(
      await game.images.load(_TaskPanelOverlay._taskRowFieldAsset),
    );
    final checkboxSize = size.y * 0.58;
    final fieldWidth = size.x - checkboxSize - (size.x * 0.08);
    final fieldHeight = size.y * 0.90;

    add(
      SpriteComponent(
        sprite: checkboxSprite,
        position: Vector2(size.x * 0.07, size.y * 0.50),
        size: Vector2.all(checkboxSize),
        anchor: Anchor.centerLeft,
      ),
    );
    add(
      SpriteComponent(
        sprite: rowFieldSprite,
        position: Vector2(size.x * 0.16 + (fieldWidth * 0.5), size.y * 0.50),
        size: Vector2(fieldWidth, fieldHeight),
        anchor: Anchor.center,
      )..opacity = highlighted ? 0.94 : 0.84,
    );
    add(
      TextComponent(
        text: label,
        position: Vector2(size.x * 0.18, size.y * 0.50),
        anchor: Anchor.centerLeft,
        textRenderer: TextPaint(
          style: TextStyle(
            color: const Color(0xFF5A4228),
            fontSize: size.y * 0.34,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    if (!_legacyIconCleanupDone) {
      // Hot reload may preserve old row icon sprites on existing instances.
      // Remove right-aligned small sprites that match the legacy icon shape.
      final legacyIconSprites = children.whereType<SpriteComponent>().where((
        sprite,
      ) {
        final isRightAligned = sprite.position.x >= size.x * 0.70;
        final isIconLikeSize =
            sprite.size.x <= size.y * 1.25 && sprite.size.y <= size.y * 1.25;
        return isRightAligned && isIconLikeSize;
      }).toList();
      for (final sprite in legacyIconSprites) {
        sprite.removeFromParent();
      }
      _legacyIconCleanupDone = true;
    }
    super.update(dt);
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    onLongPress?.call(label, event.canvasPosition.clone());
    super.onLongTapDown(event);
  }
}

// ignore: unused_element
class _TaskPanelBoardComponent extends PositionComponent {
  _TaskPanelBoardComponent({
    required super.position,
    required super.size,
    required super.anchor,
  });

  @override
  void render(Canvas canvas) {
    final insetX = size.x * 0.02;
    final insetY = size.y * 0.01;
    final rect = Rect.fromLTWH(
      insetX,
      insetY,
      size.x - (insetX * 2),
      size.y - (insetY * 2),
    );
    final radius = Radius.circular(size.x * 0.035);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final shadowPaint = Paint()
      ..color = const Color(0x2B4E3523)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final paperPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(rect.left, rect.top),
        Offset(rect.right, rect.bottom),
        const [Color(0xFFF9F1DE), Color(0xFFF6E9D0), Color(0xFFF5E8D1)],
        const [0, 0.54, 1],
      );
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        rect.center,
        rect.width * 0.70,
        const [Color(0x44FFFDF5), Color(0x00FFFDF5)],
        const [0, 1],
      );
    final borderPaint = Paint()
      ..color = const Color(0xA6795C40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.1, size.x * 0.005);

    canvas.drawRRect(
      rrect.shift(Offset(size.x * 0.022, size.y * 0.026)),
      shadowPaint,
    );
    canvas.drawRRect(rrect, paperPaint);
    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, borderPaint);
  }
}

class _TaskPanelPushPinComponent extends PositionComponent {
  _TaskPanelPushPinComponent({
    required super.position,
    required super.size,
    required super.anchor,
  });

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x * 0.5, size.y * 0.5);
    final radius = size.x * 0.28;
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final outerPaint = Paint()
      ..shader = ui.Gradient.radial(
        center.translate(-(radius * 0.18), -(radius * 0.18)),
        radius * 1.15,
        const [Color(0xFFE8B36A), Color(0xFFC98D49)],
        const [0, 1],
      );
    final innerPaint = Paint()
      ..shader = ui.Gradient.radial(
        center.translate(-(radius * 0.12), -(radius * 0.18)),
        radius * 0.82,
        const [Color(0xFFF6C984), Color(0x00F6C984)],
        const [0, 1],
      );
    final borderPaint = Paint()
      ..color = const Color(0xB87A5330)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.x * 0.04);

    canvas.drawCircle(
      center.translate(size.x * 0.05, size.y * 0.08),
      radius,
      shadowPaint,
    );
    canvas.drawCircle(center, radius, outerPaint);
    canvas.drawCircle(center, radius * 0.72, innerPaint);
    canvas.drawCircle(center, radius, borderPaint);
  }
}

// ignore: unused_element
class _IconTileStyle {
  const _IconTileStyle({
    required this.fill,
    required this.border,
    required this.shadow,
    required this.iconBg,
    required this.iconFg,
    required this.label,
  });

  final Color fill;
  final Color border;
  final Color shadow;
  final Color iconBg;
  final Color iconFg;
  final Color label;
}

// ignore: unused_element
Color _applyOpacity(Color color, double opacity) {
  return color.withValues(alpha: (color.a * opacity).clamp(0, 1).toDouble());
}

// ignore: unused_element
void _drawCenteredText(
  Canvas canvas, {
  required String text,
  required Offset center,
  required double fontSize,
  required Color color,
  FontWeight weight = FontWeight.w700,
}) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  textPainter.paint(
    canvas,
    Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    ),
  );
}
