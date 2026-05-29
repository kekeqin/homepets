import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../core/ui/sprite_atlas_flame.dart';
import '../../../models/pet_artwork.dart';
import '../guide/home_guide_controller.dart';
import '../task_panel_sprite_catalog.dart';
import 'home_scene_layout.dart';

enum HomeSceneDevice { mobile, tablet }

const String _homeSceneBackgroundAsset = 'scenes/home.png';
const String _homeTaskStickerAsset = 'images/ui/home/home_task_sticker_add.png';
const String _homeFamilyPhotoFrameAsset =
    'images/ui/home/home_family_photo_frame.png';
const String _homePaywallAsset = 'images/ui/home/home_paywall.png';
const String _homeShopAsset = 'images/ui/home/home_shop.png';
const String _homeSetupAsset = 'images/ui/19.png';
const Size _homeSceneBackgroundSize = Size(840, 1871);
const Duration _homeGuideAnchorReadyDelay = Duration(milliseconds: 1250);
const String _homeSceneMobileLayoutProfile = 'mobile';
const String _homeSceneTabletLayoutProfile = 'tablet';
const String _homeLayoutTaskSticker = 'taskSticker';
const String _homeLayoutFamilyPhoto = 'familyPhoto';
const String _homeLayoutPaywall = 'paywall';
const String _homeLayoutShop = 'shop';
const String _homeLayoutSettings = 'settings';
const String _homeLayoutRightArmchairFrontOccluder =
    'rightArmchairFrontOccluder';
const String _homeLayoutRightArmchairSideOccluder = 'rightArmchairSideOccluder';
const Set<String> _homeSceneDensityAwareAssets = <String>{
  _homeTaskStickerAsset,
  _homeFamilyPhotoFrameAsset,
  _homePaywallAsset,
  _homeShopAsset,
  _homeSetupAsset,
};

const Map<String, String> _homeSceneAssetFallbacks = <String, String>{
  'scenes/4.png': 'scenes/4.jpg',
  _homeTaskStickerAsset: 'images/ui/task_note.png',
  _homeFamilyPhotoFrameAsset: 'images/ui/family_photo.png',
  _homePaywallAsset: 'images/ui/pay.png',
  _homeShopAsset: 'images/ui/shop_basket.png',
};

String? _homeSceneAssetDensityFor(double devicePixelRatio) {
  if (devicePixelRatio >= 2.625) {
    return '3.0';
  }
  if (devicePixelRatio >= 1.5) {
    return '2.0';
  }
  return null;
}

double _homeSceneCurrentDevicePixelRatio() {
  final implicitView = ui.PlatformDispatcher.instance.implicitView;
  return implicitView?.devicePixelRatio ?? 1;
}

const List<_PetCandidatePoint>
_defaultHomePetCandidatePoints = <_PetCandidatePoint>[
  // 1. Sofa left seat, seated on the cushion instead of the rug edge.
  _PetCandidatePoint(
    centerX: 0.315,
    centerY: 0.557,
    widthScale: 0.98,
    heightScale: 0.92,
    preferRestPose: true,
  ),
  // 2. Right armchair seat, high enough that the front edge only covers paws.
  _PetCandidatePoint(
    centerX: 0.795,
    centerY: 0.580,
    widthScale: 0.86,
    heightScale: 0.86,
    preferSitPose: true,
    contactShadow: _PetContactShadowSpec(
      widthFactor: 0.72,
      heightFactor: 0.08,
      centerYFactor: 0.95,
      opacity: 0.18,
      blurSigmaFactor: 0.045,
    ),
  ),
  // 3. Floor pet sits just in front of the right armchair edge.
  _PetCandidatePoint(
    centerX: 0.775,
    centerY: 0.655,
    renderPriority: _homeSeatOccluderRenderPriority + 1,
  ),
  // 4. Left rug area in front of the sofa.
  _PetCandidatePoint(centerX: 0.230, centerY: 0.790),
  // 5. Lower-left floor spot from the marked layout.
  _PetCandidatePoint(centerX: 0.145, centerY: 0.860),
  // 6. Bottom-center spot near the cushion.
  _PetCandidatePoint(centerX: 0.530, centerY: 0.860),
  // 7. Plant-side floor spot.
  _PetCandidatePoint(centerX: 0.665, centerY: 0.855),
  // 8. Lower-right floor beside the plant cluster.
  _PetCandidatePoint(centerX: 0.845, centerY: 0.865),
];

const double _homeSceneBackgroundAspectRatio = 840 / 1871;
const double _homePetSceneInsetFactor = 0.012;
const double _homePetPerspectiveFarCenterY = 0.40;
const double _homePetPerspectiveNearCenterY = 0.89;
const double _homePetPerspectiveFarScale = 1.0;
const double _homePetPerspectiveNearScale = 1.0;
const int _homePetRenderPriority = 4;
const int _homeSeatOccluderRenderPriority = 8;
const int _homeSceneUiRenderPriority = 12;
const Set<String> _homePetDynamicPoseTypes = <String>{};
const Size _homePetScaleReferenceSlotSize = Size(
  _homeSceneBackgroundAspectRatio * 0.17,
  0.11,
);
const double _homePetRegularTargetArea = 0.0105;
const double _homePetCompactTargetArea = 0.0084;
const double _homePetBabyStageScale = 0.85;
const double _homePetGrowingStageScale = 1.0;
const double _homePetCompanionStageScale = 1.18;
const List<int> _defaultHomePetCandidateAssignmentOrder = <int>[
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
];
const _RectFactor _homeSettingsGearRect = _RectFactor(
  0.623,
  0.315,
  0.113,
  0.043,
);
const _RectFactor _homeCoffeeTableNoPetRect = _RectFactor(
  0.330,
  0.635,
  0.315,
  0.125,
);
const _RectFactor _rightArmchairSeatCushionRect = _RectFactor(
  0.735,
  0.545,
  0.120,
  0.105,
);
const _RectFactor _rightArmchairFrontOccluderRect = _RectFactor(
  0.735,
  0.617,
  0.145,
  0.050,
);
const _RectFactor _rightArmchairSideOccluderRect = _RectFactor(
  0.850,
  0.595,
  0.072,
  0.088,
);

_RectFactor _rectFactorFromLayout(HomeSceneLayoutRect rect) {
  return _RectFactor.fromCenter(
    centerX: rect.centerX,
    centerY: rect.centerY,
    width: rect.width,
    height: rect.height,
  );
}

_RectFactor _homeLayoutSpriteRect(
  HomeSceneLayout? layout,
  String profile,
  String id,
  _RectFactor fallback,
) {
  final rect = layout?.sprite(profile, id);
  return rect == null ? fallback : _rectFactorFromLayout(rect);
}

_RectFactor _homeLayoutRegionRect(
  HomeSceneLayout? layout,
  String id,
  _RectFactor fallback,
) {
  final rect = layout?.region(id);
  return rect == null ? fallback : _rectFactorFromLayout(rect);
}

_PetCandidatePoint _petCandidatePointFromLayout(
  HomePetCandidatePosition position,
) {
  return _PetCandidatePoint(
    centerX: position.centerX,
    centerY: position.centerY,
    widthScale: position.widthScale,
    heightScale: position.heightScale,
    preferRestPose: position.preferRestPose,
    preferSitPose: position.preferSitPose,
    placementEnabled: position.placementEnabled,
    contactShadow: position.contactShadow == null
        ? null
        : _PetContactShadowSpec(
            widthFactor: position.contactShadow!.widthFactor,
            heightFactor: position.contactShadow!.heightFactor,
            centerYFactor: position.contactShadow!.centerYFactor,
            opacity: position.contactShadow!.opacity,
            blurSigmaFactor: position.contactShadow!.blurSigmaFactor,
          ),
    renderPriority: position.renderPriority ?? _homePetRenderPriority,
  );
}

bool _shouldRotateHomePetPosesForType(String petType) {
  return _homePetDynamicPoseTypes.contains(normalizePetType(petType));
}

bool _assetNameContainsAny(String assetName, Iterable<String> keywords) {
  return keywords.any(assetName.contains);
}

double _homePetScaleForAssetPath(String assetPath) {
  final cropRect = _homePetCropRects[assetPath];
  if (cropRect == null) {
    return _homePetGrowthStageScaleForAssetPath(assetPath);
  }

  final sourceSize = _resolvedPetSourceSize(
    assetPath,
    Size(cropRect.width, cropRect.height),
  );
  return _homePetScaleForSlot(
        assetPath: assetPath,
        slotSize: _homePetScaleReferenceSlotSize,
        sourceSize: sourceSize,
      ) *
      _homePetGrowthStageScaleForAssetPath(assetPath);
}

double _homePetPlacementScaleAdjustment({
  required _PetCandidatePoint candidate,
  required String assetPath,
}) {
  return 1;
}

double _homePetTargetAreaForAssetPath(String assetPath) {
  final normalizedPath = assetPath.toLowerCase();
  if (normalizedPath.contains('/hamster/') ||
      normalizedPath.contains('/turtle/')) {
    return _homePetCompactTargetArea;
  }
  return _homePetRegularTargetArea;
}

double _homePetGrowthStageScaleForAssetPath(String assetPath) {
  final normalizedPath = assetPath.toLowerCase();
  if (normalizedPath.contains('/baby/')) {
    return _homePetBabyStageScale;
  }
  if (normalizedPath.contains('/companion/')) {
    return _homePetCompanionStageScale;
  }
  if (normalizedPath.contains('/growing/')) {
    return _homePetGrowingStageScale;
  }
  return _homePetGrowingStageScale;
}

double _homePetScaleForSlot({
  required String assetPath,
  required Size slotSize,
  required Size sourceSize,
}) {
  final renderSize = _resolveHomePetRenderSize(
    slotSize: slotSize,
    sourceSize: sourceSize,
    petScale: 1,
  );
  if (renderSize.isEmpty) {
    return 1;
  }

  final normalizedArea =
      (renderSize.width / _homeSceneBackgroundAspectRatio) * renderSize.height;
  if (normalizedArea <= 0) {
    return 1;
  }

  return math.sqrt(_homePetTargetAreaForAssetPath(assetPath) / normalizedArea);
}

const Map<String, Size> _homePetImagePixelSizes = <String, Size>{
  'images/pets/grow/cat/baby/lying.png': Size(1459, 1078),
  'images/pets/grow/cat/baby/sitting.png': Size(1458, 1079),
  'images/pets/grow/cat/baby/stage.png': Size(1456, 1080),
  'images/pets/grow/cat/companion/sitting.png': Size(1185, 1327),
  'images/pets/grow/cat/companion/stage.png': Size(1467, 1072),
  'images/pets/grow/cat/companion/stretching.png': Size(1465, 1074),
  'images/pets/grow/cat/growing/lying.png': Size(1401, 1123),
  'images/pets/grow/cat/growing/sitting.png': Size(508, 696),
  'images/pets/grow/cat/growing/sleeping.png': Size(755, 445),
  'images/pets/grow/dog/baby/lying.png': Size(1402, 1122),
  'images/pets/grow/dog/baby/sitting.png': Size(1254, 1254),
  'images/pets/grow/dog/baby/sleeping.png': Size(1402, 1122),
  'images/pets/grow/dog/companion/lying.png': Size(1402, 1122),
  'images/pets/grow/dog/companion/sitting.png': Size(1145, 1373),
  'images/pets/grow/dog/companion/stage.png': Size(1402, 1122),
  'images/pets/grow/dog/growing/lying.png': Size(1402, 1122),
  'images/pets/grow/dog/growing/sitting.png': Size(350, 511),
  'images/pets/grow/dog/growing/sleeping.png': Size(583, 375),
  'images/pets/grow/hamster/baby/lying.png': Size(1326, 1186),
  'images/pets/grow/hamster/baby/sitting.png': Size(1199, 1312),
  'images/pets/grow/hamster/baby/sleeping.png': Size(1300, 1209),
  'images/pets/grow/hamster/companion/lying.png': Size(1487, 1058),
  'images/pets/grow/hamster/companion/sleeping.png': Size(1302, 1208),
  'images/pets/grow/hamster/companion/stage.png': Size(1175, 1338),
  'images/pets/grow/hamster/growing/sitting.png': Size(377, 420),
  'images/pets/grow/hamster/growing/sleeping.png': Size(1419, 1108),
  'images/pets/grow/hamster/growing/standing.png': Size(388, 621),
  'images/pets/grow/rabbit/baby/lying.png': Size(1254, 1254),
  'images/pets/grow/rabbit/baby/sleeping.png': Size(1362, 1155),
  'images/pets/grow/rabbit/baby/stage.png': Size(1254, 1254),
  'images/pets/grow/rabbit/companion/lying.png': Size(1451, 1084),
  'images/pets/grow/rabbit/companion/stage.png': Size(1163, 1353),
  'images/pets/grow/rabbit/companion/stretching.png': Size(1465, 1073),
  'images/pets/grow/rabbit/growing/lying.png': Size(351, 378),
  'images/pets/grow/rabbit/growing/sitting.png': Size(255, 429),
  'images/pets/grow/rabbit/growing/sleeping.png': Size(379, 234),
  'images/pets/grow/turtle/baby/crawling.png': Size(1402, 1122),
  'images/pets/grow/turtle/baby/sleeping.png': Size(1402, 1122),
  'images/pets/grow/turtle/baby/stage.png': Size(1254, 1254),
  'images/pets/grow/turtle/companion/crawling.png': Size(1402, 1122),
  'images/pets/grow/turtle/companion/sleeping.png': Size(1402, 1122),
  'images/pets/grow/turtle/companion/waving.png': Size(1173, 1341),
  'images/pets/grow/turtle/growing/crawling.png': Size(715, 339),
  'images/pets/grow/turtle/growing/sitting.png': Size(435, 489),
  'images/pets/grow/turtle/growing/sleeping.png': Size(690, 334),
};

Size _resolvedPetSourceSize(String assetPath, Size normalizedCropSize) {
  final imageSize = _homePetImagePixelSizes[assetPath];
  if (imageSize == null) {
    return normalizedCropSize;
  }
  return Size(
    normalizedCropSize.width * imageSize.width,
    normalizedCropSize.height * imageSize.height,
  );
}

double _homePetPerspectiveScaleForCandidate(_PetCandidatePoint candidate) {
  final normalizedDepth =
      ((candidate.centerY - _homePetPerspectiveFarCenterY) /
              (_homePetPerspectiveNearCenterY - _homePetPerspectiveFarCenterY))
          .clamp(0, 1)
          .toDouble();
  return ui.lerpDouble(
        _homePetPerspectiveFarScale,
        _homePetPerspectiveNearScale,
        normalizedDepth,
      ) ??
      1;
}

class _PetAmbientMotionProfile {
  const _PetAmbientMotionProfile({
    required this.breathAmplitude,
    required this.breathSpeed,
    required this.floatAmplitude,
    required this.wobbleAmplitude,
  });

  const _PetAmbientMotionProfile.inactive()
    : breathAmplitude = 0,
      breathSpeed = 1,
      floatAmplitude = 0,
      wobbleAmplitude = 0;

  final double breathAmplitude;
  final double breathSpeed;
  final double floatAmplitude;
  final double wobbleAmplitude;
}

_PetAmbientMotionProfile _petAmbientMotionProfileForDepth(
  double normalizedDepth,
) {
  final clampedDepth = normalizedDepth.clamp(0, 1).toDouble();
  final nearStrength = ((clampedDepth - 0.60) / 0.28).clamp(0, 1).toDouble();
  final easedNearStrength = Curves.easeInOut.transform(nearStrength);
  final floatStrength = ((nearStrength - 0.28) / 0.72).clamp(0, 1).toDouble();
  final easedFloatStrength = Curves.easeOut.transform(floatStrength);

  return _PetAmbientMotionProfile(
    breathAmplitude: ui.lerpDouble(0.90, 1.28, easedNearStrength) ?? 1.08,
    breathSpeed: ui.lerpDouble(0.92, 1.05, easedNearStrength) ?? 0.98,
    floatAmplitude: nearStrength <= 0.28
        ? 0
        : (ui.lerpDouble(0, 1.25, easedFloatStrength) ?? 0),
    wobbleAmplitude: ui.lerpDouble(0.55, 1.00, easedNearStrength) ?? 0.76,
  );
}

enum _PetMotionActionKind {
  catSitBlinkTail,
  catSitLook,
  catSleepEarTwitch,
  catSleepDrowse,
  dogSitTailWag,
  dogSitHeadTilt,
  dogSleepDreamTwitch,
  dogSleepKick,
  hamsterStandLook,
  hamsterStandTuck,
  hamsterSitNibble,
  hamsterSleepEarTwitch,
  rabbitLyingEarsFlick,
  rabbitLyingNoseTwitch,
  rabbitSitEarSway,
  rabbitSleepDrowse,
  turtleLyingHeadOut,
  turtleLyingPawShift,
  turtleSitLift,
  turtleSleepSink,
  tapCat,
  tapDog,
  tapHamster,
  tapRabbit,
  tapTurtle,
}

class _PetMotionSpec {
  const _PetMotionSpec({
    required this.breathAmplitude,
    required this.breathSpeed,
    required this.floatAmplitude,
    required this.floatSpeed,
    required this.idleDelayMin,
    required this.idleDelayMax,
    required this.idleActionKinds,
    required this.tapActionKind,
  });

  final double breathAmplitude;
  final double breathSpeed;
  final double floatAmplitude;
  final double floatSpeed;
  final double idleDelayMin;
  final double idleDelayMax;
  final List<_PetMotionActionKind> idleActionKinds;
  final _PetMotionActionKind tapActionKind;
}

const double _homePetFramePlaybackPauseMinFactor = 1.25;
const double _homePetFramePlaybackPauseMaxFactor = 1.85;

class _PetFramePlaybackTiming {
  const _PetFramePlaybackTiming({
    required this.pauseMin,
    required this.pauseMax,
  });

  final double pauseMin;
  final double pauseMax;
}

class _PetMotionTransform {
  const _PetMotionTransform({
    this.offsetX = 0,
    this.offsetY = 0,
    this.rotation = 0,
    this.scaleX = 1,
    this.scaleY = 1,
  });

  final double offsetX;
  final double offsetY;
  final double rotation;
  final double scaleX;
  final double scaleY;
}

class _ActivePetMotionAction {
  const _ActivePetMotionAction({
    required this.kind,
    required this.duration,
    required this.isTapFeedback,
  });

  final _PetMotionActionKind kind;
  final double duration;
  final bool isTapFeedback;
}

class _PetSpeechBubble {
  const _PetSpeechBubble({
    required this.message,
    required this.duration,
    this.emphasized = false,
  });

  final String message;
  final double duration;
  final bool emphasized;
}

class _PetCompletionReward {
  const _PetCompletionReward({
    required this.points,
    required this.leveledUp,
    required this.level,
    required this.duration,
  });

  final int points;
  final bool leveledUp;
  final int? level;
  final double duration;
}

_PetMotionSpec _petMotionSpecForAssetPath(String assetPath) {
  return switch (assetPath) {
    'images/pets/grow/cat/growing/lying.png' => const _PetMotionSpec(
      breathAmplitude: 0.0068,
      breathSpeed: 0.74,
      floatAmplitude: 0.10,
      floatSpeed: 0.58,
      idleDelayMin: 5.2,
      idleDelayMax: 8.2,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.catSleepEarTwitch,
        _PetMotionActionKind.catSleepDrowse,
      ],
      tapActionKind: _PetMotionActionKind.tapCat,
    ),
    'images/pets/grow/cat/growing/sitting.png' => const _PetMotionSpec(
      breathAmplitude: 0.0092,
      breathSpeed: 0.98,
      floatAmplitude: 0.26,
      floatSpeed: 0.82,
      idleDelayMin: 3.8,
      idleDelayMax: 6.4,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.catSitBlinkTail,
        _PetMotionActionKind.catSitLook,
      ],
      tapActionKind: _PetMotionActionKind.tapCat,
    ),
    'images/pets/grow/cat/growing/sleeping.png' => const _PetMotionSpec(
      breathAmplitude: 0.0070,
      breathSpeed: 0.72,
      floatAmplitude: 0.08,
      floatSpeed: 0.56,
      idleDelayMin: 5.8,
      idleDelayMax: 8.8,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.catSleepEarTwitch,
        _PetMotionActionKind.catSleepDrowse,
      ],
      tapActionKind: _PetMotionActionKind.tapCat,
    ),
    'images/pets/grow/dog/growing/lying.png' => const _PetMotionSpec(
      breathAmplitude: 0.0066,
      breathSpeed: 0.72,
      floatAmplitude: 0.08,
      floatSpeed: 0.56,
      idleDelayMin: 5.4,
      idleDelayMax: 8.6,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.dogSleepDreamTwitch,
        _PetMotionActionKind.dogSleepKick,
      ],
      tapActionKind: _PetMotionActionKind.tapDog,
    ),
    'images/pets/grow/dog/growing/sitting.png' => const _PetMotionSpec(
      breathAmplitude: 0.0080,
      breathSpeed: 0.90,
      floatAmplitude: 0.18,
      floatSpeed: 0.76,
      idleDelayMin: 3.6,
      idleDelayMax: 6.0,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.dogSitTailWag,
        _PetMotionActionKind.dogSitHeadTilt,
      ],
      tapActionKind: _PetMotionActionKind.tapDog,
    ),
    'images/pets/grow/dog/growing/sleeping.png' => const _PetMotionSpec(
      breathAmplitude: 0.0064,
      breathSpeed: 0.70,
      floatAmplitude: 0.05,
      floatSpeed: 0.54,
      idleDelayMin: 6.0,
      idleDelayMax: 9.2,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.dogSleepDreamTwitch,
        _PetMotionActionKind.dogSleepKick,
      ],
      tapActionKind: _PetMotionActionKind.tapDog,
    ),
    'images/pets/grow/hamster/growing/standing.png' => const _PetMotionSpec(
      breathAmplitude: 0.0088,
      breathSpeed: 1.12,
      floatAmplitude: 0.22,
      floatSpeed: 0.88,
      idleDelayMin: 2.6,
      idleDelayMax: 4.6,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.hamsterStandLook,
        _PetMotionActionKind.hamsterStandTuck,
      ],
      tapActionKind: _PetMotionActionKind.tapHamster,
    ),
    'images/pets/grow/hamster/growing/sitting.png' => const _PetMotionSpec(
      breathAmplitude: 0.0072,
      breathSpeed: 1.00,
      floatAmplitude: 0.14,
      floatSpeed: 0.70,
      idleDelayMin: 3.4,
      idleDelayMax: 5.8,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.hamsterSitNibble,
      ],
      tapActionKind: _PetMotionActionKind.tapHamster,
    ),
    'images/pets/grow/hamster/growing/sleeping.png' => const _PetMotionSpec(
      breathAmplitude: 0.0042,
      breathSpeed: 0.64,
      floatAmplitude: 0,
      floatSpeed: 0.48,
      idleDelayMin: 7.2,
      idleDelayMax: 10.2,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.hamsterSleepEarTwitch,
      ],
      tapActionKind: _PetMotionActionKind.tapHamster,
    ),
    'images/pets/grow/rabbit/growing/lying.png' => const _PetMotionSpec(
      breathAmplitude: 0.0074,
      breathSpeed: 0.84,
      floatAmplitude: 0.10,
      floatSpeed: 0.62,
      idleDelayMin: 3.0,
      idleDelayMax: 5.2,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.rabbitLyingEarsFlick,
        _PetMotionActionKind.rabbitLyingNoseTwitch,
      ],
      tapActionKind: _PetMotionActionKind.tapRabbit,
    ),
    'images/pets/grow/rabbit/growing/sitting.png' => const _PetMotionSpec(
      breathAmplitude: 0.0082,
      breathSpeed: 0.90,
      floatAmplitude: 0.18,
      floatSpeed: 0.70,
      idleDelayMin: 3.8,
      idleDelayMax: 6.2,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.rabbitSitEarSway,
      ],
      tapActionKind: _PetMotionActionKind.tapRabbit,
    ),
    'images/pets/grow/rabbit/growing/sleeping.png' => const _PetMotionSpec(
      breathAmplitude: 0.0054,
      breathSpeed: 0.66,
      floatAmplitude: 0.04,
      floatSpeed: 0.46,
      idleDelayMin: 6.6,
      idleDelayMax: 10.6,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.rabbitSleepDrowse,
      ],
      tapActionKind: _PetMotionActionKind.tapRabbit,
    ),
    'images/pets/grow/turtle/growing/crawling.png' => const _PetMotionSpec(
      breathAmplitude: 0.0048,
      breathSpeed: 0.58,
      floatAmplitude: 0.03,
      floatSpeed: 0.42,
      idleDelayMin: 5.8,
      idleDelayMax: 8.8,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.turtleLyingHeadOut,
        _PetMotionActionKind.turtleLyingPawShift,
      ],
      tapActionKind: _PetMotionActionKind.tapTurtle,
    ),
    'images/pets/grow/turtle/growing/sitting.png' => const _PetMotionSpec(
      breathAmplitude: 0.0054,
      breathSpeed: 0.62,
      floatAmplitude: 0.04,
      floatSpeed: 0.48,
      idleDelayMin: 5.0,
      idleDelayMax: 7.8,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.turtleSitLift,
      ],
      tapActionKind: _PetMotionActionKind.tapTurtle,
    ),
    'images/pets/grow/turtle/growing/sleeping.png' => const _PetMotionSpec(
      breathAmplitude: 0.0036,
      breathSpeed: 0.48,
      floatAmplitude: 0.02,
      floatSpeed: 0.38,
      idleDelayMin: 8.6,
      idleDelayMax: 12.0,
      idleActionKinds: <_PetMotionActionKind>[
        _PetMotionActionKind.turtleSleepSink,
      ],
      tapActionKind: _PetMotionActionKind.tapTurtle,
    ),
    _ => const _PetMotionSpec(
      breathAmplitude: 0.0052,
      breathSpeed: 0.86,
      floatAmplitude: 0.22,
      floatSpeed: 0.60,
      idleDelayMin: 4.8,
      idleDelayMax: 7.2,
      idleActionKinds: <_PetMotionActionKind>[],
      tapActionKind: _PetMotionActionKind.tapRabbit,
    ),
  };
}

_PetFramePlaybackTiming _petFramePlaybackTimingForAssetPath(String assetPath) {
  final motionSpec = _petMotionSpecForAssetPath(assetPath);
  return _PetFramePlaybackTiming(
    pauseMin: motionSpec.idleDelayMin * _homePetFramePlaybackPauseMinFactor,
    pauseMax: motionSpec.idleDelayMax * _homePetFramePlaybackPauseMaxFactor,
  );
}

double _randomBetweenFor(math.Random random, double min, double max) {
  if (max <= min) {
    return min;
  }
  return min + (random.nextDouble() * (max - min));
}

double _holdPulse(
  double progress, {
  required double begin,
  required double end,
}) {
  if (progress <= begin || progress >= end) {
    return 0;
  }
  final normalized = (progress - begin) / (end - begin);
  return math.sin(normalized * math.pi);
}

double _holdLevel(
  double progress, {
  required double begin,
  required double holdBegin,
  required double holdEnd,
  required double end,
}) {
  if (progress <= begin || progress >= end) {
    return 0;
  }
  if (progress < holdBegin) {
    return Curves.easeOut.transform((progress - begin) / (holdBegin - begin));
  }
  if (progress <= holdEnd) {
    return 1;
  }
  return 1 - Curves.easeInOut.transform((progress - holdEnd) / (end - holdEnd));
}

_PetMotionTransform _petMotionTransformForAction({
  required _PetMotionActionKind kind,
  required double progress,
  required double unit,
  required double amplitudeScale,
}) {
  final clamped = progress.clamp(0, 1).toDouble();
  final pulse = math.sin(clamped * math.pi);

  switch (kind) {
    case _PetMotionActionKind.catSitBlinkTail:
      final sway =
          math.sin(clamped * math.pi * 2.2) * 0.020 * pulse * amplitudeScale;
      final blink = _holdPulse(clamped, begin: 0.46, end: 0.68);
      return _PetMotionTransform(
        rotation: sway,
        scaleX: 1 + (0.014 * blink * amplitudeScale),
        scaleY: 1 - (0.030 * blink * amplitudeScale),
        offsetY: -(unit * 0.18 * blink * amplitudeScale),
      );
    case _PetMotionActionKind.catSitLook:
      final look = _holdLevel(
        clamped,
        begin: 0.08,
        holdBegin: 0.28,
        holdEnd: 0.62,
        end: 0.92,
      );
      return _PetMotionTransform(
        offsetY: -(unit * 0.95 * look * amplitudeScale),
        scaleY: 1 + (0.014 * look * amplitudeScale),
        rotation: 0.006 * look * amplitudeScale,
      );
    case _PetMotionActionKind.catSleepEarTwitch:
      final twitchA = _holdPulse(clamped, begin: 0.12, end: 0.28);
      final twitchB = _holdPulse(clamped, begin: 0.34, end: 0.48);
      return _PetMotionTransform(
        rotation: ((0.028 * twitchA) - (0.020 * twitchB)) * amplitudeScale,
        offsetX: unit * 0.10 * (twitchA - twitchB) * amplitudeScale,
      );
    case _PetMotionActionKind.catSleepDrowse:
      final drowse = _holdPulse(clamped, begin: 0.16, end: 0.86);
      return _PetMotionTransform(
        scaleX: 1 + (0.018 * drowse * amplitudeScale),
        scaleY: 1 - (0.030 * drowse * amplitudeScale),
        offsetY: unit * 0.24 * drowse * amplitudeScale,
      );
    case _PetMotionActionKind.dogSitTailWag:
      final wag = math.sin(clamped * math.pi * 4) * pulse * amplitudeScale;
      return _PetMotionTransform(
        rotation: wag * 0.030,
        offsetY: -(unit * 0.24 * pulse * amplitudeScale),
      );
    case _PetMotionActionKind.dogSitHeadTilt:
      final tilt = _holdLevel(
        clamped,
        begin: 0.10,
        holdBegin: 0.26,
        holdEnd: 0.66,
        end: 0.94,
      );
      return _PetMotionTransform(
        rotation: -0.080 * tilt * amplitudeScale,
        offsetY: -(unit * 0.50 * tilt * amplitudeScale),
        offsetX: unit * 0.18 * tilt * amplitudeScale,
      );
    case _PetMotionActionKind.dogSleepDreamTwitch:
      final twitchA = _holdPulse(clamped, begin: 0.10, end: 0.26);
      final twitchB = _holdPulse(clamped, begin: 0.34, end: 0.48);
      return _PetMotionTransform(
        offsetX: unit * 0.32 * (twitchA - twitchB) * amplitudeScale,
        rotation: ((0.010 * twitchA) - (0.008 * twitchB)) * amplitudeScale,
      );
    case _PetMotionActionKind.dogSleepKick:
      final twitchA = _holdPulse(clamped, begin: 0.14, end: 0.26);
      final twitchB = _holdPulse(clamped, begin: 0.32, end: 0.44);
      return _PetMotionTransform(
        offsetY: -(unit * 0.26 * (twitchA + (0.7 * twitchB)) * amplitudeScale),
        rotation: ((0.012 * twitchA) + (0.008 * twitchB)) * amplitudeScale,
      );
    case _PetMotionActionKind.hamsterStandLook:
      final look = math.sin(clamped * math.pi * 2) * pulse * amplitudeScale;
      return _PetMotionTransform(
        offsetX: unit * 0.34 * look,
        rotation: look * 0.060,
      );
    case _PetMotionActionKind.hamsterStandTuck:
      final tuck = _holdPulse(clamped, begin: 0.10, end: 0.88);
      return _PetMotionTransform(
        scaleX: 1 - (0.018 * tuck * amplitudeScale),
        scaleY: 1 + (0.022 * tuck * amplitudeScale),
        offsetY: -(unit * 0.42 * tuck * amplitudeScale),
      );
    case _PetMotionActionKind.hamsterSitNibble:
      final nibble = math.sin(clamped * math.pi * 3) * pulse * amplitudeScale;
      return _PetMotionTransform(
        offsetY: -(unit * 0.28 * nibble.abs()),
        scaleX: 1 + (0.016 * nibble),
        rotation: nibble * 0.020,
      );
    case _PetMotionActionKind.hamsterSleepEarTwitch:
      final twitch = _holdPulse(clamped, begin: 0.18, end: 0.40);
      return _PetMotionTransform(
        rotation: 0.020 * twitch * amplitudeScale,
        offsetY: -(unit * 0.08 * twitch * amplitudeScale),
      );
    case _PetMotionActionKind.rabbitLyingEarsFlick:
      final flick = math.sin(clamped * math.pi * 2.6) * pulse * amplitudeScale;
      return _PetMotionTransform(
        rotation: flick * 0.026,
        offsetY: -(unit * 0.14 * pulse * amplitudeScale),
      );
    case _PetMotionActionKind.rabbitLyingNoseTwitch:
      final twitch = math.sin(clamped * math.pi * 5.2) * pulse * amplitudeScale;
      return _PetMotionTransform(
        scaleX: 1 + (0.010 * twitch),
        scaleY: 1 - (0.010 * twitch.abs()),
      );
    case _PetMotionActionKind.rabbitSitEarSway:
      final sway = math.sin(clamped * math.pi * 2) * pulse * amplitudeScale;
      return _PetMotionTransform(
        rotation: sway * 0.028,
        offsetY: -(unit * 0.34 * pulse * amplitudeScale),
      );
    case _PetMotionActionKind.rabbitSleepDrowse:
      final drowse = _holdPulse(clamped, begin: 0.18, end: 0.86);
      return _PetMotionTransform(
        rotation: 0.010 * drowse * amplitudeScale,
        scaleY: 1 - (0.018 * drowse * amplitudeScale),
      );
    case _PetMotionActionKind.turtleLyingHeadOut:
      final extend = _holdLevel(
        clamped,
        begin: 0.10,
        holdBegin: 0.28,
        holdEnd: 0.58,
        end: 0.94,
      );
      return _PetMotionTransform(
        offsetX: unit * 0.42 * extend * amplitudeScale,
        offsetY: -(unit * 0.12 * extend * amplitudeScale),
      );
    case _PetMotionActionKind.turtleLyingPawShift:
      final shift = _holdPulse(clamped, begin: 0.20, end: 0.82);
      return _PetMotionTransform(
        offsetX: unit * 0.22 * shift * amplitudeScale,
        offsetY: unit * 0.10 * shift * amplitudeScale,
        rotation: 0.010 * shift * amplitudeScale,
      );
    case _PetMotionActionKind.turtleSitLift:
      final lift = _holdLevel(
        clamped,
        begin: 0.14,
        holdBegin: 0.32,
        holdEnd: 0.62,
        end: 0.92,
      );
      return _PetMotionTransform(
        offsetY: -(unit * 0.66 * lift * amplitudeScale),
        scaleY: 1 + (0.010 * lift * amplitudeScale),
      );
    case _PetMotionActionKind.turtleSleepSink:
      final sink = _holdPulse(clamped, begin: 0.18, end: 0.92);
      return _PetMotionTransform(
        offsetY: unit * 0.18 * sink * amplitudeScale,
        scaleY: 1 - (0.010 * sink * amplitudeScale),
      );
    case _PetMotionActionKind.tapCat:
      final ears = _holdPulse(clamped, begin: 0.00, end: 0.28);
      final tail =
          math.sin((clamped - 0.28).clamp(0, 1) * math.pi * 3.2) *
          _holdPulse(clamped, begin: 0.28, end: 0.88) *
          amplitudeScale;
      return _PetMotionTransform(
        offsetY: -(unit * 0.44 * ears * amplitudeScale),
        scaleY: 1 + (0.020 * ears * amplitudeScale),
        rotation: tail * 0.026,
      );
    case _PetMotionActionKind.tapDog:
      final head = _holdPulse(clamped, begin: 0.00, end: 0.30);
      final wag =
          math.sin((clamped - 0.26).clamp(0, 1) * math.pi * 4.2) *
          _holdPulse(clamped, begin: 0.26, end: 0.90) *
          amplitudeScale;
      return _PetMotionTransform(
        offsetY: -(unit * 0.58 * head * amplitudeScale),
        rotation: wag * 0.032,
      );
    case _PetMotionActionKind.tapHamster:
      final peek = _holdPulse(clamped, begin: 0.00, end: 0.64);
      return _PetMotionTransform(
        offsetY: -(unit * 0.42 * peek * amplitudeScale),
        scaleX: 1 + (0.020 * peek * amplitudeScale),
        scaleY: 1 + (0.020 * peek * amplitudeScale),
      );
    case _PetMotionActionKind.tapRabbit:
      final ears = _holdPulse(clamped, begin: 0.00, end: 0.34);
      final lift = _holdLevel(
        clamped,
        begin: 0.18,
        holdBegin: 0.34,
        holdEnd: 0.58,
        end: 0.92,
      );
      return _PetMotionTransform(
        offsetY: -(unit * (0.26 * ears + 0.52 * lift) * amplitudeScale),
        scaleY: 1 + (0.018 * ears * amplitudeScale),
      );
    case _PetMotionActionKind.tapTurtle:
      final retract = _holdPulse(clamped, begin: 0.00, end: 0.24);
      final extend = _holdLevel(
        clamped,
        begin: 0.24,
        holdBegin: 0.46,
        holdEnd: 0.62,
        end: 0.96,
      );
      return _PetMotionTransform(
        offsetX:
            ((-unit * 0.34 * retract) + (unit * 0.42 * extend)) *
            amplitudeScale,
      );
  }
}

class _PetFrameAnimationSpec {
  const _PetFrameAnimationSpec({
    required this.frameAssetPaths,
    required this.frameDurations,
  });

  final List<String> frameAssetPaths;
  final List<double> frameDurations;
}

List<String> _homeActFrameAssetPaths(String prefix, {List<int>? frameNumbers}) {
  final List<int> resolvedFrameNumbers =
      frameNumbers ?? List<int>.generate(25, (index) => index + 1);
  return resolvedFrameNumbers
      .map(
        (frameNumber) =>
            'images/pets/act/${prefix}_${frameNumber.toString().padLeft(2, '0')}.png',
      )
      .toList(growable: false);
}

List<double> _homeActFrameDurations(
  double durationSeconds, {
  int frameCount = 25,
}) => List<double>.filled(frameCount, durationSeconds);

const int _babyActFrameCount = 35;

final List<int> _babyActFrameNumbers = List<int>.generate(
  _babyActFrameCount,
  (index) => index + 1,
  growable: false,
);

_PetFrameAnimationSpec _babyActHomeAnimation(String prefix) {
  return _PetFrameAnimationSpec(
    frameAssetPaths: _homeActFrameAssetPaths(
      prefix,
      frameNumbers: _babyActFrameNumbers,
    ),
    frameDurations: _homeActFrameDurations(
      0.10,
      frameCount: _babyActFrameCount,
    ),
  );
}

final _PetFrameAnimationSpec _catSitActHomeAnimation = _PetFrameAnimationSpec(
  frameAssetPaths: _homeActFrameAssetPaths('cat_sit_frame'),
  frameDurations: _homeActFrameDurations(0.16),
);

final _PetFrameAnimationSpec _catSleepActHomeAnimation = _PetFrameAnimationSpec(
  frameAssetPaths: _homeActFrameAssetPaths('cat_sleep_frame'),
  frameDurations: _homeActFrameDurations(0.18),
);

final _PetFrameAnimationSpec _dogSitActHomeAnimation = _PetFrameAnimationSpec(
  frameAssetPaths: _homeActFrameAssetPaths('dog_sit_frame'),
  frameDurations: _homeActFrameDurations(0.15),
);

final _PetFrameAnimationSpec _dogSleepActHomeAnimation = _PetFrameAnimationSpec(
  frameAssetPaths: _homeActFrameAssetPaths('dog_sleep_frame'),
  frameDurations: _homeActFrameDurations(0.18),
);

final _PetFrameAnimationSpec _rabbitLyingActHomeAnimation =
    _PetFrameAnimationSpec(
      frameAssetPaths: _homeActFrameAssetPaths('rabbit_lying_frame'),
      frameDurations: _homeActFrameDurations(0.17),
    );

final _PetFrameAnimationSpec _rabbitSitActHomeAnimation =
    _PetFrameAnimationSpec(
      frameAssetPaths: _homeActFrameAssetPaths('rabbit_sit_frame'),
      frameDurations: _homeActFrameDurations(0.16),
    );

final _PetFrameAnimationSpec _rabbitSleepActHomeAnimation =
    _PetFrameAnimationSpec(
      frameAssetPaths: _homeActFrameAssetPaths('rabbit_sleep_frame'),
      frameDurations: _homeActFrameDurations(0.18),
    );

final _PetFrameAnimationSpec _catBabyLyingActHomeAnimation =
    _babyActHomeAnimation('cat_baby_lying_frame');
final _PetFrameAnimationSpec _catBabySittingActHomeAnimation =
    _babyActHomeAnimation('cat_baby_sitting_frame');
final _PetFrameAnimationSpec _catBabyStageActHomeAnimation =
    _babyActHomeAnimation('cat_baby_stage_frame');
final _PetFrameAnimationSpec _dogBabyLyingActHomeAnimation =
    _babyActHomeAnimation('dog_baby_lying_frame');
final _PetFrameAnimationSpec _dogBabySittingActHomeAnimation =
    _babyActHomeAnimation('dog_baby_sitting_frame');
final _PetFrameAnimationSpec _dogBabySleepingActHomeAnimation =
    _babyActHomeAnimation('dog_baby_sleeping_frame');
final _PetFrameAnimationSpec _hamsterBabyLyingActHomeAnimation =
    _babyActHomeAnimation('hamster_baby_lying_frame');
final _PetFrameAnimationSpec _hamsterBabySittingActHomeAnimation =
    _babyActHomeAnimation('hamster_baby_sitting_frame');
final _PetFrameAnimationSpec _hamsterBabySleepingActHomeAnimation =
    _babyActHomeAnimation('hamster_baby_sleeping_frame');
final _PetFrameAnimationSpec _rabbitBabyLyingActHomeAnimation =
    _babyActHomeAnimation('rabbit_baby_lying_frame');
final _PetFrameAnimationSpec _rabbitBabySleepingActHomeAnimation =
    _babyActHomeAnimation('rabbit_baby_sleeping_frame');
final _PetFrameAnimationSpec _rabbitBabyStageActHomeAnimation =
    _babyActHomeAnimation('rabbit_baby_stage_frame');
final _PetFrameAnimationSpec _turtleBabyCrawlingActHomeAnimation =
    _babyActHomeAnimation('turtle_baby_crawling_frame');
final _PetFrameAnimationSpec _turtleBabySleepingActHomeAnimation =
    _babyActHomeAnimation('turtle_baby_sleeping_frame');
final _PetFrameAnimationSpec _turtleBabyStageActHomeAnimation =
    _babyActHomeAnimation('turtle_baby_stage_frame');

final List<String> _hamsterStandActFrameAssetPaths = _homeActFrameAssetPaths(
  'hamster_stand_frame',
  frameNumbers: const <int>[1, 2, 3, 4, 5, 6, 7, 8, 19, 20, 21, 22, 23, 24],
);

final _PetFrameAnimationSpec _hamsterStandActHomeAnimation =
    _PetFrameAnimationSpec(
      frameAssetPaths: _hamsterStandActFrameAssetPaths,
      frameDurations: _homeActFrameDurations(
        0.15,
        frameCount: _hamsterStandActFrameAssetPaths.length,
      ),
    );

final _PetFrameAnimationSpec _hamsterSitActHomeAnimation =
    _PetFrameAnimationSpec(
      frameAssetPaths: _homeActFrameAssetPaths('hamster_sit_frame'),
      frameDurations: _homeActFrameDurations(0.15),
    );

final _PetFrameAnimationSpec _turtleLyingActHomeAnimation =
    _PetFrameAnimationSpec(
      frameAssetPaths: _homeActFrameAssetPaths('turtle_lying_frame'),
      frameDurations: _homeActFrameDurations(0.20),
    );

final _PetFrameAnimationSpec _turtleSitActHomeAnimation =
    _PetFrameAnimationSpec(
      frameAssetPaths: _homeActFrameAssetPaths('turtle_sit_frame'),
      frameDurations: _homeActFrameDurations(0.18),
    );

_PetFrameAnimationSpec? _homePetAnimationForAsset(String assetPath) {
  return switch (assetPath) {
    'images/pets/grow/cat/baby/lying.png' => _catBabyLyingActHomeAnimation,
    'images/pets/grow/cat/baby/sitting.png' => _catBabySittingActHomeAnimation,
    'images/pets/grow/cat/baby/stage.png' => _catBabyStageActHomeAnimation,
    'images/pets/grow/cat/growing/sitting.png' => _catSitActHomeAnimation,
    'images/pets/grow/cat/growing/sleeping.png' => _catSleepActHomeAnimation,
    'images/pets/grow/dog/baby/lying.png' => _dogBabyLyingActHomeAnimation,
    'images/pets/grow/dog/baby/sitting.png' => _dogBabySittingActHomeAnimation,
    'images/pets/grow/dog/baby/sleeping.png' =>
      _dogBabySleepingActHomeAnimation,
    'images/pets/grow/dog/growing/sitting.png' => _dogSitActHomeAnimation,
    'images/pets/grow/dog/growing/sleeping.png' => _dogSleepActHomeAnimation,
    'images/pets/grow/hamster/baby/lying.png' =>
      _hamsterBabyLyingActHomeAnimation,
    'images/pets/grow/hamster/baby/sitting.png' =>
      _hamsterBabySittingActHomeAnimation,
    'images/pets/grow/hamster/baby/sleeping.png' =>
      _hamsterBabySleepingActHomeAnimation,
    'images/pets/grow/hamster/growing/standing.png' =>
      _hamsterStandActHomeAnimation,
    'images/pets/grow/hamster/growing/sitting.png' =>
      _hamsterSitActHomeAnimation,
    'images/pets/grow/rabbit/baby/lying.png' =>
      _rabbitBabyLyingActHomeAnimation,
    'images/pets/grow/rabbit/baby/sleeping.png' =>
      _rabbitBabySleepingActHomeAnimation,
    'images/pets/grow/rabbit/baby/stage.png' =>
      _rabbitBabyStageActHomeAnimation,
    'images/pets/grow/rabbit/growing/lying.png' => _rabbitLyingActHomeAnimation,
    'images/pets/grow/rabbit/growing/sitting.png' => _rabbitSitActHomeAnimation,
    'images/pets/grow/rabbit/growing/sleeping.png' =>
      _rabbitSleepActHomeAnimation,
    'images/pets/grow/turtle/baby/crawling.png' =>
      _turtleBabyCrawlingActHomeAnimation,
    'images/pets/grow/turtle/baby/sleeping.png' =>
      _turtleBabySleepingActHomeAnimation,
    'images/pets/grow/turtle/baby/stage.png' =>
      _turtleBabyStageActHomeAnimation,
    'images/pets/grow/turtle/growing/crawling.png' =>
      _turtleLyingActHomeAnimation,
    'images/pets/grow/turtle/growing/sitting.png' => _turtleSitActHomeAnimation,
    _ => null,
  };
}

class _PetCandidatePoint {
  const _PetCandidatePoint({
    required this.centerX,
    required this.centerY,
    this.widthScale = 1,
    this.heightScale = 1,
    this.preferRestPose = false,
    this.preferSitPose = false,
    this.placementEnabled = true,
    this.contactShadow,
    this.renderPriority = _homePetRenderPriority,
  });

  final double centerX;
  final double centerY;
  final double widthScale;
  final double heightScale;
  final bool preferRestPose;
  final bool preferSitPose;
  final bool placementEnabled;
  final _PetContactShadowSpec? contactShadow;
  final int renderPriority;
}

class _PetContactShadowSpec {
  const _PetContactShadowSpec({
    required this.widthFactor,
    required this.heightFactor,
    required this.centerYFactor,
    this.opacity = 0.18,
    this.blurSigmaFactor = 0.06,
  });

  final double widthFactor;
  final double heightFactor;
  final double centerYFactor;
  final double opacity;
  final double blurSigmaFactor;
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
  const HomeScenePetSeed({
    required this.petId,
    required this.petType,
    this.level = 1,
  });

  final int petId;
  final String petType;
  final int level;
}

bool _homeScenePetSeedsEqual(
  List<HomeScenePetSeed> left,
  List<HomeScenePetSeed> right,
) {
  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index++) {
    final leftSeed = left[index];
    final rightSeed = right[index];
    if (leftSeed.petId != rightSeed.petId ||
        leftSeed.petType != rightSeed.petType ||
        leftSeed.level != rightSeed.level) {
      return false;
    }
  }

  return true;
}

class HomeSceneGame extends FlameGame<World> with RiverpodGameMixin<World> {
  HomeSceneGame({
    required this.device,
    this.devicePixelRatio,
    this.onTaskTap,
    this.onOpenFamily,
    this.onOpenShop,
    this.onOpenPaywall,
    this.onOpenSettings,
    this.onTaskItemLongPress,
    this.onTaskAddTap,
    this.onOpenPetDetail,
    this.onGuideAnchorLayoutChanged,
  }) : super(world: World()) {
    _profile = _profileFor(
      device,
      onTaskTap: onTaskTap ?? _showTaskPanel,
      onOpenFamily: onOpenFamily,
      onOpenShop: onOpenShop,
      onOpenPaywall: onOpenPaywall,
      onOpenSettings: onOpenSettings,
    );
  }

  final HomeSceneDevice device;
  final double? devicePixelRatio;
  final VoidCallback? onTaskTap;
  final VoidCallback? onOpenFamily;
  final VoidCallback? onOpenShop;
  final VoidCallback? onOpenPaywall;
  final VoidCallback? onOpenSettings;
  final void Function(String taskLabel, Offset globalPosition)?
  onTaskItemLongPress;
  final Future<void> Function()? onTaskAddTap;
  final void Function(int petId, String avatarAssetPath)? onOpenPetDetail;
  final VoidCallback? onGuideAnchorLayoutChanged;
  HomeSceneLayout? _layout;
  List<_PetCandidatePoint> _petCandidatePoints = _defaultHomePetCandidatePoints;
  List<int> _petCandidateAssignmentOrder =
      _defaultHomePetCandidateAssignmentOrder;
  late _SceneProfile _profile;

  late Vector2 _sceneSize;
  late final _SceneBackgroundComponent _background;
  final List<_AnimatedSceneComponent> _animatedComponents =
      <_AnimatedSceneComponent>[];
  _SceneSpriteComponent? _taskNoteComponent;
  _SceneSpriteComponent? _familyPhotoComponent;
  _TaskPanelOverlay? _taskPanelOverlay;
  final List<_TaskPanelEntry> _taskEntries = <_TaskPanelEntry>[];
  final List<HomeScenePetSeed> _petEntries = <HomeScenePetSeed>[];
  final Map<int, _AssignedPetPlacement> _petPlacements =
      <int, _AssignedPetPlacement>{};
  final Map<int, int> _petPoseIndices = <int, int>{};
  final math.Random _petPlacementRandom = math.Random();
  final math.Random _petPoseRandom = math.Random();
  Vector2? _lastUiLayoutSize;
  int _uiRebuildGeneration = 0;

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

  List<int> get _enabledPetCandidateIndices {
    return List<int>.unmodifiable(
      List<int>.generate(
        _petCandidatePoints.length,
        (index) => index,
      ).where((index) => _petCandidatePoints[index].placementEnabled),
    );
  }

  void _refreshProfileFromLayout() {
    _profile = _profileFor(
      device,
      layout: _layout,
      onTaskTap: onTaskTap ?? _showTaskPanel,
      onOpenFamily: onOpenFamily,
      onOpenShop: onOpenShop,
      onOpenPaywall: onOpenPaywall,
      onOpenSettings: onOpenSettings,
    );
  }

  Future<bool> _loadHomeSceneLayout({required bool bypassCache}) async {
    var loaded = false;
    try {
      _layout = await HomeSceneLayout.load(bypassCache: bypassCache);
      _refreshProfileFromLayout();
      loaded = true;
    } catch (error, stackTrace) {
      debugPrint('HomeSceneGame failed to load $homeSceneLayoutAsset: $error');
      debugPrint('$stackTrace');
    }
    try {
      final petPositions = await HomePetPositions.load(
        bypassCache: bypassCache,
      );
      _petCandidatePoints = List<_PetCandidatePoint>.unmodifiable(
        petPositions.candidates.map(_petCandidatePointFromLayout),
      );
      _petCandidateAssignmentOrder = _validPetCandidateAssignmentOrder(
        petPositions.assignmentOrder,
      );
      loaded = true;
    } catch (error, stackTrace) {
      debugPrint('HomeSceneGame failed to load $homePetPositionsAsset: $error');
      debugPrint('$stackTrace');
    }
    return loaded;
  }

  List<int> _validPetCandidateAssignmentOrder(List<int> order) {
    final valid = order
        .where((index) => index >= 0 && index < _petCandidatePoints.length)
        .toList(growable: false);
    if (valid.isNotEmpty) {
      return List<int>.unmodifiable(valid);
    }
    return _defaultHomePetCandidateAssignmentOrder
        .where((index) => index < _petCandidatePoints.length)
        .toList(growable: false);
  }

  Future<void> reloadSceneLayoutForHotReload() async {
    if (_exitTriggered) {
      return;
    }
    final loaded = await _loadHomeSceneLayout(bypassCache: true);
    if (!loaded || !_ready) {
      return;
    }
    await _preloadSceneUiAssets();
    await _rebuildUiFromProfile();
  }

  static _SceneProfile _profileFor(
    HomeSceneDevice device, {
    HomeSceneLayout? layout,
    required VoidCallback onTaskTap,
    VoidCallback? onOpenFamily,
    VoidCallback? onOpenShop,
    VoidCallback? onOpenPaywall,
    VoidCallback? onOpenSettings,
  }) {
    return switch (device) {
      HomeSceneDevice.mobile => _mobileProfile(
        layout: layout,
        onTaskTap: onTaskTap,
        onOpenFamily: onOpenFamily,
        onOpenShop: onOpenShop,
        onOpenPaywall: onOpenPaywall,
        onOpenSettings: onOpenSettings,
      ),
      HomeSceneDevice.tablet => _tabletProfile(
        layout: layout,
        onTaskTap: onTaskTap,
        onOpenFamily: onOpenFamily,
        onOpenShop: onOpenShop,
        onOpenPaywall: onOpenPaywall,
        onOpenSettings: onOpenSettings,
      ),
    };
  }

  static _SceneProfile _mobileProfile({
    HomeSceneLayout? layout,
    required VoidCallback onTaskTap,
    VoidCallback? onOpenFamily,
    VoidCallback? onOpenShop,
    VoidCallback? onOpenPaywall,
    VoidCallback? onOpenSettings,
  }) {
    return _SceneProfile(
      backgroundAsset: _homeSceneBackgroundAsset,
      backgroundFit: _SceneBackgroundFit.contain,
      backgroundFillColor: const Color(0xFFF4E3CF),
      specs: <_UiSpec>[
        _SceneSpriteSpec(
          rect: _homeLayoutSpriteRect(
            layout,
            _homeSceneMobileLayoutProfile,
            _homeLayoutTaskSticker,
            const _RectFactor(0.205, 0.132, 0.181, 0.090),
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homeTaskStickerAsset,
          behavior: _SceneSpriteBehavior.taskNote,
          ambientPhase: 0.2,
          entryDelay: 0.22,
          entryOffset: 70,
          onTap: onTaskTap,
        ),
        _SceneSpriteSpec(
          rect: _homeLayoutSpriteRect(
            layout,
            _homeSceneMobileLayoutProfile,
            _homeLayoutFamilyPhoto,
            const _RectFactor(0.820, 0.332, 0.124, 0.065),
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homeFamilyPhotoFrameAsset,
          behavior: _SceneSpriteBehavior.familyPhoto,
          ambientPhase: 1.6,
          entryDelay: 0.30,
          entryOffset: 70,
          onTap: onOpenFamily,
        ),
        _SceneSpriteSpec(
          rect: _homeLayoutSpriteRect(
            layout,
            _homeSceneMobileLayoutProfile,
            _homeLayoutPaywall,
            const _RectFactor(0.498, 0.122, 0.138, 0.089),
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homePaywallAsset,
          behavior: _SceneSpriteBehavior.wallBadge,
          ambientPhase: 1.1,
          entryDelay: 0.34,
          entryOffset: 70,
          onTap: onOpenPaywall,
        ),
        _SceneSpriteSpec(
          rect: _homeLayoutSpriteRect(
            layout,
            _homeSceneMobileLayoutProfile,
            _homeLayoutShop,
            const _RectFactor(0.734, 0.118, 0.162, 0.104),
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homeShopAsset,
          behavior: _SceneSpriteBehavior.shopBasket,
          ambientPhase: 2.4,
          entryDelay: 0.38,
          entryOffset: 70,
          onTap: onOpenShop,
        ),
        _SceneSpriteSpec(
          // Settings gear rests flat on the bookshelf top board.
          rect: _homeLayoutSpriteRect(
            layout,
            _homeSceneMobileLayoutProfile,
            _homeLayoutSettings,
            _homeSettingsGearRect,
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homeSetupAsset,
          behavior: _SceneSpriteBehavior.staticOverlay,
          ambientPhase: 0,
          renderPriority: _homeSceneUiRenderPriority,
          entryDelay: 0.32,
          entryOffset: 70,
          onTap: onOpenSettings,
        ),
        _SceneSpriteSpec(
          rect: _homeLayoutRegionRect(
            layout,
            _homeLayoutRightArmchairFrontOccluder,
            _rightArmchairFrontOccluderRect,
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homeSceneBackgroundAsset,
          behavior: _SceneSpriteBehavior.staticOverlay,
          ambientPhase: 0,
          cropRect: _homeLayoutRegionRect(
            layout,
            _homeLayoutRightArmchairFrontOccluder,
            _rightArmchairFrontOccluderRect,
          ),
          renderPriority: _homeSeatOccluderRenderPriority,
          entryDelay: 0.12,
          entryOffset: 0,
        ),
        _SceneSpriteSpec(
          rect: _homeLayoutRegionRect(
            layout,
            _homeLayoutRightArmchairSideOccluder,
            _rightArmchairSideOccluderRect,
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homeSceneBackgroundAsset,
          behavior: _SceneSpriteBehavior.staticOverlay,
          ambientPhase: 0,
          cropRect: _homeLayoutRegionRect(
            layout,
            _homeLayoutRightArmchairSideOccluder,
            _rightArmchairSideOccluderRect,
          ),
          renderPriority: _homeSeatOccluderRenderPriority,
          entryDelay: 0.12,
          entryOffset: 0,
        ),
      ],
    );
  }

  static _SceneProfile _tabletProfile({
    HomeSceneLayout? layout,
    required VoidCallback onTaskTap,
    VoidCallback? onOpenFamily,
    VoidCallback? onOpenShop,
    VoidCallback? onOpenPaywall,
    VoidCallback? onOpenSettings,
  }) {
    return _SceneProfile(
      backgroundAsset: _homeSceneBackgroundAsset,
      backgroundFit: _SceneBackgroundFit.contain,
      backgroundFillColor: const Color(0xFFF4E3CF),
      specs: <_UiSpec>[
        _SceneSpriteSpec(
          rect: _homeLayoutSpriteRect(
            layout,
            _homeSceneTabletLayoutProfile,
            _homeLayoutTaskSticker,
            const _RectFactor(0.205, 0.132, 0.181, 0.090),
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homeTaskStickerAsset,
          behavior: _SceneSpriteBehavior.taskNote,
          ambientPhase: 0.3,
          entryDelay: 0.18,
          entryOffset: 46,
          onTap: onTaskTap,
        ),
        _SceneSpriteSpec(
          rect: _homeLayoutSpriteRect(
            layout,
            _homeSceneTabletLayoutProfile,
            _homeLayoutFamilyPhoto,
            const _RectFactor(0.820, 0.332, 0.124, 0.065),
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homeFamilyPhotoFrameAsset,
          behavior: _SceneSpriteBehavior.familyPhoto,
          ambientPhase: 1.8,
          entryDelay: 0.24,
          entryOffset: 46,
          onTap: onOpenFamily,
        ),
        _SceneSpriteSpec(
          rect: _homeLayoutSpriteRect(
            layout,
            _homeSceneTabletLayoutProfile,
            _homeLayoutPaywall,
            const _RectFactor(0.498, 0.122, 0.138, 0.089),
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homePaywallAsset,
          behavior: _SceneSpriteBehavior.wallBadge,
          ambientPhase: 1.2,
          entryDelay: 0.27,
          entryOffset: 46,
          onTap: onOpenPaywall,
        ),
        _SceneSpriteSpec(
          rect: _homeLayoutSpriteRect(
            layout,
            _homeSceneTabletLayoutProfile,
            _homeLayoutShop,
            const _RectFactor(0.734, 0.118, 0.162, 0.104),
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homeShopAsset,
          behavior: _SceneSpriteBehavior.shopBasket,
          ambientPhase: 2.2,
          entryDelay: 0.30,
          entryOffset: 46,
          onTap: onOpenShop,
        ),
        _SceneSpriteSpec(
          // Settings gear rests flat on the bookshelf top board.
          rect: _homeLayoutSpriteRect(
            layout,
            _homeSceneTabletLayoutProfile,
            _homeLayoutSettings,
            _homeSettingsGearRect,
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homeSetupAsset,
          behavior: _SceneSpriteBehavior.staticOverlay,
          ambientPhase: 0,
          renderPriority: _homeSceneUiRenderPriority,
          entryDelay: 0.26,
          entryOffset: 46,
          onTap: onOpenSettings,
        ),
        _SceneSpriteSpec(
          rect: _homeLayoutRegionRect(
            layout,
            _homeLayoutRightArmchairFrontOccluder,
            _rightArmchairFrontOccluderRect,
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homeSceneBackgroundAsset,
          behavior: _SceneSpriteBehavior.staticOverlay,
          ambientPhase: 0,
          cropRect: _homeLayoutRegionRect(
            layout,
            _homeLayoutRightArmchairFrontOccluder,
            _rightArmchairFrontOccluderRect,
          ),
          renderPriority: _homeSeatOccluderRenderPriority,
          entryDelay: 0.12,
          entryOffset: 0,
        ),
        _SceneSpriteSpec(
          rect: _homeLayoutRegionRect(
            layout,
            _homeLayoutRightArmchairSideOccluder,
            _rightArmchairSideOccluderRect,
          ),
          referenceSpace: _UiReferenceSpace.background,
          assetPath: _homeSceneBackgroundAsset,
          behavior: _SceneSpriteBehavior.staticOverlay,
          ambientPhase: 0,
          cropRect: _homeLayoutRegionRect(
            layout,
            _homeLayoutRightArmchairSideOccluder,
            _rightArmchairSideOccluderRect,
          ),
          renderPriority: _homeSeatOccluderRenderPriority,
          entryDelay: 0.12,
          entryOffset: 0,
        ),
      ],
    );
  }

  void replacePetEntries(List<HomeScenePetSeed> pets) {
    final nextPetEntries = pets
        .where((item) => item.petId > 0)
        .toList(growable: false);
    if (_homeScenePetSeedsEqual(_petEntries, nextPetEntries)) {
      return;
    }

    _petEntries
      ..clear()
      ..addAll(nextPetEntries);
    _syncPetPlacements();
    _syncPetPoseIndices();
    if (_ready) {
      unawaited(_rebuildUiFromProfile());
    }
  }

  void shufflePetLayout() {
    if (_petEntries.isEmpty) {
      return;
    }

    _petPlacements.clear();
    _petPoseIndices.clear();
    _syncPetPlacements();
    _syncPetPoseIndices();
    if (_ready) {
      unawaited(_rebuildUiFromProfile());
    }
  }

  int get debugPetCandidateCount => _enabledPetCandidateIndices.length;

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
          final poseVariants = _buildPetPoseVariants(
            petType: petType,
            level: pet.level,
            petId: pet.petId,
            placement: _petPlacements[pet.petId]!,
            layout: layout,
          );
          final rect =
              poseVariants[_initialHomePetPoseIndex(
                    petType,
                    pet.petId,
                    poseVariants.length,
                  )]
                  .rect;
          final resolvedRect = Rect.fromLTWH(
            rect.left,
            rect.top,
            rect.width,
            rect.height,
          );
          return resolvedRect;
        }(),
    });
  }

  Rect? debugTaskNoteHomeRect(Size sceneSize) {
    return _debugHomeSpriteRect(sceneSize, _SceneSpriteBehavior.taskNote);
  }

  Rect? debugFamilyPhotoHomeRect(Size sceneSize) {
    return _debugHomeSpriteRect(sceneSize, _SceneSpriteBehavior.familyPhoto);
  }

  Rect? _debugHomeSpriteRect(Size sceneSize, _SceneSpriteBehavior behavior) {
    final backgroundSize = Vector2(sceneSize.width, sceneSize.height);
    final backgroundRect = _homeSceneBackgroundLayoutRect(
      sourceSize: _homeSceneBackgroundSize,
      sceneSize: backgroundSize,
      fit: _profile.backgroundFit,
    );
    for (final spec in _profile.specs.whereType<_SceneSpriteSpec>()) {
      if (spec.behavior != behavior) {
        continue;
      }
      return spec.resolveRect(backgroundSize, backgroundRect);
    }
    return null;
  }

  Map<int, List<String>> debugPetPoseAssetVariants() {
    _syncPetPlacements();
    final layout = _petLayoutProfile();

    return Map<int, List<String>>.unmodifiable(<int, List<String>>{
      for (var index = 0; index < _petEntries.length; index++)
        _petEntries[index].petId: () {
          final pet = _petEntries[index];
          final petType = _normalizedPetType(pet.petType, index: index);
          final poseVariants = _buildPetPoseVariants(
            petType: petType,
            level: pet.level,
            petId: pet.petId,
            placement: _petPlacements[pet.petId]!,
            layout: layout,
          );
          return List<String>.unmodifiable(
            poseVariants.map((variant) => variant.assetPath),
          );
        }(),
    });
  }

  Map<int, String> debugCurrentPetPoseAssetPaths() {
    _syncPetPlacements();
    _syncPetPoseIndices();

    final assetPaths = <int, String>{};
    for (var index = 0; index < _petEntries.length; index++) {
      final pet = _petEntries[index];
      final petType = _normalizedPetType(pet.petType, index: index);
      final placement = _petPlacements[pet.petId];
      if (placement == null) {
        continue;
      }
      final poseVariants = _homePoseAssetPathsForPlacement(
        petType,
        pet.level,
        pet.petId,
        placement,
      );
      final currentPoseIndex = _currentHomePetPoseIndex(
        petType,
        pet.petId,
        poseVariants.length,
      );
      assetPaths[pet.petId] = poseVariants[currentPoseIndex];
    }

    return Map<int, String>.unmodifiable(assetPaths);
  }

  Map<int, String> debugPetDetailAvatarAssetPaths() {
    return Map<int, String>.unmodifiable(
      debugCurrentPetPoseAssetPaths().map(
        (petId, assetPath) => MapEntry(
          petId,
          petDetailAvatarAssetPathForHomeAssetPath(assetPath),
        ),
      ),
    );
  }

  Map<int, List<Rect>> debugPetPoseVariantRects() {
    _syncPetPlacements();
    final layout = _petLayoutProfile();

    return Map<int, List<Rect>>.unmodifiable(<int, List<Rect>>{
      for (var index = 0; index < _petEntries.length; index++)
        _petEntries[index].petId: () {
          final pet = _petEntries[index];
          final petType = _normalizedPetType(pet.petType, index: index);
          final poseVariants = _buildPetPoseVariants(
            petType: petType,
            level: pet.level,
            petId: pet.petId,
            placement: _petPlacements[pet.petId]!,
            layout: layout,
          );
          return List<Rect>.unmodifiable(
            poseVariants.map(
              (variant) => Rect.fromLTWH(
                variant.rect.left,
                variant.rect.top,
                variant.rect.width,
                variant.rect.height,
              ),
            ),
          );
        }(),
    });
  }

  void playPetCompletionReaction({
    int? petId,
    required String message,
    int points = 10,
    bool leveledUp = false,
    int? level,
  }) {
    if (!_ready) {
      return;
    }
    final petComponents = _animatedComponents.whereType<_PetSpriteComponent>();
    _PetSpriteComponent? target;
    for (final component in petComponents) {
      if (petId == null || component.petId == petId) {
        target = component;
        break;
      }
    }
    target?.playCompletionReaction(
      message: message,
      points: points,
      leveledUp: leveledUp,
      level: level,
    );
  }

  static bool debugUsesDynamicHomePoseSwitching(String petType) {
    return _shouldRotateHomePetPosesForType(petType);
  }

  static int get debugSeatOccluderRenderPriority =>
      _homeSeatOccluderRenderPriority;

  static Rect get debugHomeSettingsGearRect => Rect.fromLTWH(
    _homeSettingsGearRect.left,
    _homeSettingsGearRect.top,
    _homeSettingsGearRect.width,
    _homeSettingsGearRect.height,
  );

  static Rect get debugHomeCoffeeTableNoPetRect => Rect.fromLTWH(
    _homeCoffeeTableNoPetRect.left,
    _homeCoffeeTableNoPetRect.top,
    _homeCoffeeTableNoPetRect.width,
    _homeCoffeeTableNoPetRect.height,
  );

  static Rect get debugRightArmchairSeatCushionRect => Rect.fromLTWH(
    _rightArmchairSeatCushionRect.left,
    _rightArmchairSeatCushionRect.top,
    _rightArmchairSeatCushionRect.width,
    _rightArmchairSeatCushionRect.height,
  );

  static Rect get debugRightArmchairFrontOccluderRect => Rect.fromLTWH(
    _rightArmchairFrontOccluderRect.left,
    _rightArmchairFrontOccluderRect.top,
    _rightArmchairFrontOccluderRect.width,
    _rightArmchairFrontOccluderRect.height,
  );

  static Rect get debugRightArmchairSideOccluderRect => Rect.fromLTWH(
    _rightArmchairSideOccluderRect.left,
    _rightArmchairSideOccluderRect.top,
    _rightArmchairSideOccluderRect.width,
    _rightArmchairSideOccluderRect.height,
  );

  static List<String> debugAnimationFrameAssetPathsForAsset(String assetPath) {
    return List<String>.unmodifiable(
      _homePetAnimationForAsset(assetPath)?.frameAssetPaths ?? const <String>[],
    );
  }

  static bool debugHasIdleMotionActionsForAsset(String assetPath) {
    return _petMotionSpecForAssetPath(assetPath).idleActionKinds.isNotEmpty;
  }

  static List<double> debugAnimationPlaybackPauseRangeForAsset(
    String assetPath,
  ) {
    final timing = _petFramePlaybackTimingForAssetPath(assetPath);
    return List<double>.unmodifiable(<double>[
      timing.pauseMin,
      timing.pauseMax,
    ]);
  }

  Map<int, double> debugPetInitialAnimationDelays() {
    _syncPetPlacements();
    final layout = _petLayoutProfile();

    return Map<int, double>.unmodifiable(<int, double>{
      for (var index = 0; index < _petEntries.length; index++)
        _petEntries[index].petId: () {
          final pet = _petEntries[index];
          final petType = _normalizedPetType(pet.petType, index: index);
          final placement = _petPlacements[pet.petId]!;
          final candidate = _petCandidatePoints[placement.candidateIndex];
          final poseVariants = _buildPetPoseVariants(
            petType: petType,
            level: pet.level,
            petId: pet.petId,
            placement: placement,
            layout: layout,
          );
          final initialPoseIndex = _initialHomePetPoseIndex(
            petType,
            pet.petId,
            poseVariants.length,
          );
          final initialPose = poseVariants[initialPoseIndex];
          return _PetSpriteComponent.debugInitialFramePlaybackDelay(
            assetPath: initialPose.assetPath,
            seedLeft: initialPose.rect.left,
            seedTop: initialPose.rect.top,
            poseVariantCount: poseVariants.length,
            renderPriority: candidate.renderPriority,
            entryDelay: _petEntryDelayFor(index),
          );
        }(),
    });
  }

  int debugPetRenderPriorityForCandidate(int candidateIndex) {
    RangeError.checkValidIndex(
      candidateIndex,
      _petCandidatePoints,
      'candidateIndex',
    );
    return _petCandidatePoints[candidateIndex].renderPriority;
  }

  Rect debugPetRectForCandidate({
    required int candidateIndex,
    required String assetPath,
  }) {
    RangeError.checkValidIndex(
      candidateIndex,
      _petCandidatePoints,
      'candidateIndex',
    );
    final cropRect = _petCropRectForAsset(assetPath);
    final rect = _petRectForPlacement(
      _AssignedPetPlacement(candidateIndex: candidateIndex),
      _petLayoutProfile(),
      assetPath: assetPath,
      petScale: 1,
      cropRect: cropRect,
    );
    return Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height);
  }

  bool advanceDynamicHomePetPoses() {
    _syncPetPoseIndices();

    var changed = false;
    for (var index = 0; index < _petEntries.length; index++) {
      final pet = _petEntries[index];
      final petType = _normalizedPetType(pet.petType, index: index);
      if (!_shouldRotateHomePetPosesForType(petType)) {
        continue;
      }

      final placement = _petPlacements[pet.petId]!;
      final poseCount = _homePoseAssetPathsForPlacement(
        petType,
        pet.level,
        pet.petId,
        placement,
      ).length;
      if (poseCount < 2) {
        continue;
      }

      final currentPoseIndex = _currentHomePetPoseIndex(
        petType,
        pet.petId,
        poseCount,
      );
      final nextPoseIndex = _nextDynamicHomePetPoseIndex(
        currentPoseIndex: currentPoseIndex,
        poseCount: poseCount,
      );
      if (nextPoseIndex == currentPoseIndex) {
        continue;
      }

      _setCurrentHomePetPoseIndex(
        petId: pet.petId,
        poseIndex: nextPoseIndex,
        poseCount: poseCount,
      );
      changed = true;
    }

    if (changed && _ready) {
      unawaited(_rebuildUiFromProfile());
    }
    return changed;
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
    required String assetPath,
    required Size slotSize,
    required Size sourceSize,
  }) {
    return _resolveHomePetRenderSize(
      slotSize: slotSize,
      sourceSize: _resolvedPetSourceSize(assetPath, sourceSize),
      petScale: _homePetScaleForAssetPath(assetPath),
    );
  }

  static double debugHomePetScaleForAssetPath(String assetPath) {
    return _homePetScaleForAssetPath(assetPath);
  }

  static double debugHomePetTargetAreaForAssetPath(String assetPath) {
    return _homePetTargetAreaForAssetPath(assetPath);
  }

  static double debugPerspectiveScaleForCandidate(int candidateIndex) {
    RangeError.checkValidIndex(
      candidateIndex,
      _defaultHomePetCandidatePoints,
      'candidateIndex',
    );
    return _homePetPerspectiveScaleForCandidate(
      _defaultHomePetCandidatePoints[candidateIndex],
    );
  }

  static ({
    double breathAmplitude,
    double floatAmplitude,
    double wobbleAmplitude,
  })
  debugAmbientMotionValuesForDepth(double normalizedDepth) {
    final profile = _petAmbientMotionProfileForDepth(normalizedDepth);
    return (
      breathAmplitude: profile.breathAmplitude,
      floatAmplitude: profile.floatAmplitude,
      wobbleAmplitude: profile.wobbleAmplitude,
    );
  }

  static bool debugHasHomePetScaleOverride(String assetPath) {
    return _homePetCropRects.containsKey(assetPath);
  }

  static double debugPlacementScaleAdjustmentForCandidateAsset({
    required int candidateIndex,
    required String assetPath,
  }) {
    RangeError.checkValidIndex(
      candidateIndex,
      _defaultHomePetCandidatePoints,
      'candidateIndex',
    );
    return _homePetPlacementScaleAdjustment(
      candidate: _defaultHomePetCandidatePoints[candidateIndex],
      assetPath: assetPath,
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
      final candidate = _petCandidatePoints[placement.candidateIndex];
      final poseVariants = _buildPetPoseVariants(
        petType: petType,
        level: pet.level,
        petId: pet.petId,
        placement: placement,
        layout: layout,
      );
      final initialPoseIndex = _initialHomePetPoseIndex(
        petType,
        pet.petId,
        poseVariants.length,
      );
      final detailAvatarAssetPath = petDetailAvatarAssetPathForHomeAssetPath(
        poseVariants[initialPoseIndex].assetPath,
      );

      return _PetSpriteSpec(
        petId: pet.petId,
        rect: poseVariants[initialPoseIndex].rect,
        referenceSpace: _UiReferenceSpace.background,
        poseVariants: poseVariants,
        initialPoseIndex: initialPoseIndex,
        contactShadow: candidate.contactShadow,
        renderPriority: candidate.renderPriority,
        entryDelay: _petEntryDelayFor(index),
        entryOffset: _petEntryOffsetFor(device),
        onTap: () => onOpenPetDetail?.call(pet.petId, detailAvatarAssetPath),
      );
    });
  }

  void _syncPetPlacements() {
    final activePetIds = _petEntries.map((item) => item.petId).toSet();
    _petPlacements.removeWhere(
      (petId, placement) =>
          !activePetIds.contains(petId) ||
          placement.candidateIndex < 0 ||
          placement.candidateIndex >= _petCandidatePoints.length ||
          !_petCandidatePoints[placement.candidateIndex].placementEnabled,
    );

    if (activePetIds.isEmpty) {
      return;
    }

    final occupancyCounts = List<int>.filled(_petCandidatePoints.length, 0);
    for (final petId in activePetIds) {
      final placement = _petPlacements[petId];
      if (placement == null) {
        continue;
      }
      occupancyCounts[placement.candidateIndex] += 1;
    }

    final availableIndices = _randomizedEnabledHomePetCandidateIndices()
      ..removeWhere((index) => occupancyCounts[index] > 0);

    final layout = _petLayoutProfile();
    for (var index = 0; index < _petEntries.length; index++) {
      final pet = _petEntries[index];
      if (_petPlacements.containsKey(pet.petId)) {
        continue;
      }
      final petType = _normalizedPetType(pet.petType, index: index);

      final placement = _createPetPlacement(
        petType: petType,
        availableIndices: availableIndices,
        enabledIndices: _enabledPetCandidateIndices,
        occupancyCounts: occupancyCounts,
        layout: layout,
      );
      _petPlacements[pet.petId] = placement;
      occupancyCounts[placement.candidateIndex] += 1;
    }
  }

  _AssignedPetPlacement _createPetPlacement({
    required String petType,
    required List<int> availableIndices,
    required List<int> enabledIndices,
    required List<int> occupancyCounts,
    required _PetLayoutProfile layout,
  }) {
    final compatibleAvailableIndices = availableIndices
        .where((index) => _candidateSupportsPetType(index, petType))
        .toList();
    if (compatibleAvailableIndices.isNotEmpty) {
      final candidateIndex = compatibleAvailableIndices.first;
      availableIndices.remove(candidateIndex);
      return _AssignedPetPlacement(candidateIndex: candidateIndex);
    }

    final minimumOccupancy = enabledIndices
        .map((index) => occupancyCounts[index])
        .reduce(math.min);
    final leastCrowdedIndices = <int>[];
    for (final index in enabledIndices) {
      if (occupancyCounts[index] == minimumOccupancy &&
          _candidateSupportsPetType(index, petType)) {
        leastCrowdedIndices.add(index);
      }
    }

    if (leastCrowdedIndices.isEmpty) {
      for (final index in enabledIndices) {
        if (occupancyCounts[index] == minimumOccupancy) {
          leastCrowdedIndices.add(index);
        }
      }
    }

    final candidateIndex = leastCrowdedIndices.first;
    final occupantCount = occupancyCounts[candidateIndex];
    final spreadMultiplier = math.min(occupantCount + 1, 3).toDouble();
    final angle = _petPlacementRandom.nextDouble() * math.pi * 2;
    return _AssignedPetPlacement(
      candidateIndex: candidateIndex,
      offsetX: math.cos(angle) * layout.overflowJitterX * spreadMultiplier,
      offsetY: math.sin(angle) * layout.overflowJitterY * spreadMultiplier,
    );
  }

  List<int> _orderedEnabledHomePetCandidateIndices() {
    final enabled = _enabledPetCandidateIndices.toSet();
    final ordered = <int>[
      for (final index in _petCandidateAssignmentOrder)
        if (enabled.remove(index)) index,
      ...enabled,
    ];
    return ordered;
  }

  List<int> _randomizedEnabledHomePetCandidateIndices() {
    final ordered = _orderedEnabledHomePetCandidateIndices();
    ordered.shuffle(_petPlacementRandom);
    return ordered;
  }

  _RectFactor _petRectForPlacement(
    _AssignedPetPlacement placement,
    _PetLayoutProfile layout, {
    required String assetPath,
    required double petScale,
    _RectFactor? cropRect,
  }) {
    final candidate = _petCandidatePoints[placement.candidateIndex];
    final perspectiveScale = _homePetPerspectiveScaleForCandidate(candidate);
    final placementScaleAdjustment = _homePetPlacementScaleAdjustment(
      candidate: candidate,
      assetPath: assetPath,
    );
    final slotLayout = _PetLayoutProfile(
      widthFactor: layout.widthFactor * candidate.widthScale * perspectiveScale,
      heightFactor:
          layout.heightFactor * candidate.heightScale * perspectiveScale,
      overflowJitterX: layout.overflowJitterX,
      overflowJitterY: layout.overflowJitterY,
    );
    final renderSize = _petRenderSizeFactors(
      layout: slotLayout,
      assetPath: assetPath,
      petScale: petScale * placementScaleAdjustment,
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
        (candidate.centerY + placement.offsetY + (slotLayout.heightFactor / 2))
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
    required String assetPath,
    required double petScale,
    required _RectFactor? cropRect,
  }) {
    if (cropRect == null) {
      return Size(
        layout.widthFactor * petScale,
        layout.heightFactor * petScale,
      );
    }

    final slotSize = Size(
      layout.widthFactor * _homeSceneBackgroundAspectRatio,
      layout.heightFactor,
    );
    final sourceSize = _resolvedPetSourceSize(
      assetPath,
      Size(cropRect.width, cropRect.height),
    );
    final slotScale =
        _homePetScaleForSlot(
          assetPath: assetPath,
          slotSize: slotSize,
          sourceSize: sourceSize,
        ) *
        _homePetGrowthStageScaleForAssetPath(assetPath) *
        petScale;
    final normalizedRenderSize = _resolveHomePetRenderSize(
      slotSize: slotSize,
      sourceSize: sourceSize,
      petScale: slotScale,
    );
    if (normalizedRenderSize.isEmpty) {
      return Size(
        layout.widthFactor * petScale,
        layout.heightFactor * petScale,
      );
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

  void _syncPetPoseIndices() {
    final activePetIds = _petEntries.map((item) => item.petId).toSet();
    _petPoseIndices.removeWhere((petId, _) => !activePetIds.contains(petId));

    for (var index = 0; index < _petEntries.length; index++) {
      final pet = _petEntries[index];
      final petType = _normalizedPetType(pet.petType, index: index);
      final placement = _petPlacements[pet.petId];
      if (placement == null) {
        continue;
      }
      final poseCount = _homePoseAssetPathsForPlacement(
        petType,
        pet.level,
        pet.petId,
        placement,
      ).length;
      if (poseCount <= 0) {
        continue;
      }

      if (_petPoseIndices.containsKey(pet.petId)) {
        _petPoseIndices[pet.petId] = _normalizeHomePetPoseIndex(
          _petPoseIndices[pet.petId]!,
          poseCount,
        );
      } else {
        _petPoseIndices[pet.petId] = _randomHomePetPoseIndex(
          petType: petType,
          poseCount: poseCount,
        );
      }
    }
  }

  int _currentHomePetPoseIndex(String petType, int petId, int poseCount) {
    if (poseCount <= 0) {
      return 0;
    }
    final cachedPoseIndex = _petPoseIndices[petId];
    return _normalizeHomePetPoseIndex(
      cachedPoseIndex ??
          _randomHomePetPoseIndex(petType: petType, poseCount: poseCount),
      poseCount,
    );
  }

  void _setCurrentHomePetPoseIndex({
    required int petId,
    required int poseIndex,
    required int poseCount,
  }) {
    final normalizedPoseIndex = _normalizeHomePetPoseIndex(
      poseIndex,
      poseCount,
    );
    _petPoseIndices[petId] = normalizedPoseIndex;
  }

  int _randomHomePetPoseIndex({
    required String petType,
    required int poseCount,
  }) {
    if (poseCount < 2) {
      return _normalizeHomePetPoseIndex(
        deterministicHomePetPoseIndex(petType, 0),
        poseCount,
      );
    }
    return _petPoseRandom.nextInt(poseCount);
  }

  int _nextDynamicHomePetPoseIndex({
    required int currentPoseIndex,
    required int poseCount,
  }) {
    if (poseCount < 2) {
      return _normalizeHomePetPoseIndex(currentPoseIndex, poseCount);
    }

    final offset = _petPoseRandom.nextInt(poseCount - 1) + 1;
    return (currentPoseIndex + offset) % poseCount;
  }

  int _normalizeHomePetPoseIndex(int poseIndex, int poseCount) {
    if (poseCount <= 0) {
      return 0;
    }
    final normalized = poseIndex % poseCount;
    return normalized < 0 ? normalized + poseCount : normalized;
  }

  bool _placementUsesRestPosePreference(_AssignedPetPlacement placement) {
    return _petCandidatePoints[placement.candidateIndex].preferRestPose;
  }

  bool _placementUsesSitPosePreference(_AssignedPetPlacement placement) {
    return _petCandidatePoints[placement.candidateIndex].preferSitPose;
  }

  bool _candidateSupportsPetType(int candidateIndex, String petType) {
    final candidate = _petCandidatePoints[candidateIndex];
    if (!candidate.preferSitPose) {
      return true;
    }
    return petGrowthHomePoseVariantsForType(petType, 1).any(
      (assetName) =>
          _assetNameContainsAny(assetName, const <String>['sit', 'stand']) ||
          assetName.contains('stage') ||
          assetName.contains('waving'),
    );
  }

  int _initialHomePetPoseIndex(String petType, int petId, int poseCount) {
    final placement = _petPlacements[petId];
    if (placement == null) {
      return 0;
    }
    return _currentHomePetPoseIndex(petType, petId, poseCount);
  }

  List<String> _homePoseAssetPathsForPlacement(
    String petType,
    int level,
    int petId,
    _AssignedPetPlacement placement,
  ) {
    if (_placementUsesSitPosePreference(placement)) {
      return _preferredSittingHomePoseAssetPaths(petType, level);
    }
    if (_placementUsesRestPosePreference(placement)) {
      return _preferredRestingHomePoseAssetPaths(petType, level);
    }
    return List<String>.unmodifiable(
      petGrowthHomePoseVariantsForType(petType, level).map(
        (assetName) => petGrowthHomeAssetPathForPose(petType, level, assetName),
      ),
    );
  }

  List<String> _preferredRestingHomePoseAssetPaths(String petType, int level) {
    final variantNames = petGrowthHomePoseVariantsForType(petType, level);
    final preferredLie = variantNames.where(
      (name) =>
          _assetNameContainsAny(name, const <String>['crawl', 'lie', 'lying']),
    );
    final preferredSleep = variantNames.where((name) => name.contains('sleep'));
    final preferred = <String>[
      ...preferredLie,
      ...preferredSleep.where((name) => !preferredLie.contains(name)),
    ];
    final variants = preferred.isNotEmpty ? preferred : variantNames;
    return List<String>.unmodifiable(
      variants.map(
        (assetName) => petGrowthHomeAssetPathForPose(petType, level, assetName),
      ),
    );
  }

  List<String> _preferredSittingHomePoseAssetPaths(String petType, int level) {
    final variantNames = petGrowthHomePoseVariantsForType(petType, level);
    final preferredSit = variantNames.where(
      (name) =>
          _assetNameContainsAny(name, const <String>['sit', 'stand']) ||
          name.contains('stage') ||
          name.contains('waving'),
    );
    final preferredLie = variantNames.where(
      (name) =>
          _assetNameContainsAny(name, const <String>['crawl', 'lie', 'lying']),
    );
    final preferred = <String>[
      ...preferredSit,
      ...preferredLie.where((name) => !preferredSit.contains(name)),
    ];
    final variants = preferred.isNotEmpty ? preferred : variantNames;
    return List<String>.unmodifiable(
      variants.map(
        (assetName) => petGrowthHomeAssetPathForPose(petType, level, assetName),
      ),
    );
  }

  List<_PetPoseVariantSpec> _buildPetPoseVariants({
    required String petType,
    required int level,
    required int petId,
    required _AssignedPetPlacement placement,
    required _PetLayoutProfile layout,
  }) {
    final assetPaths = _homePoseAssetPathsForPlacement(
      petType,
      level,
      petId,
      placement,
    );
    return List<_PetPoseVariantSpec>.generate(assetPaths.length, (index) {
      final assetPath = assetPaths[index];
      final cropRect = _petCropRectForAsset(assetPath);
      final animation = _homePetAnimationForAsset(assetPath);
      return _PetPoseVariantSpec(
        rect: _petRectForPlacement(
          placement,
          layout,
          assetPath: assetPath,
          petScale: 1,
          cropRect: cropRect,
        ),
        assetPath: assetPath,
        cropRect: cropRect,
        animationFrameAssetPaths:
            animation?.frameAssetPaths ?? const <String>[],
        animationFrameDurations: animation?.frameDurations ?? const <double>[],
      );
    });
  }

  _RectFactor? _petCropRectForAsset(String assetPath) {
    return _homePetCropRects[assetPath];
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
        unawaited(_rebuildUiFromProfile());
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
    await _loadHomeSceneLayout(bypassCache: false);

    final backgroundSprite = Sprite(
      await _loadSceneImage(_profile.backgroundAsset),
    );
    _background = _SceneBackgroundComponent(
      sprite: backgroundSprite,
      sceneSize: _sceneSize,
      fit: _profile.backgroundFit,
    );
    await world.add(_background);
    await _preloadSceneUiAssets();

    if (_sceneSize.x > 0 && _sceneSize.y > 0) {
      await _rebuildUiFromProfile();
    }

    _ready = true;
    if (_openTaskPanelWhenReady) {
      _openTaskPanelWhenReady = false;
      _showTaskPanel();
    }
  }

  Future<void> _preloadSceneUiAssets() async {
    for (final spec in _profile.specs) {
      if (spec is! _SceneSpriteSpec) {
        continue;
      }
      await _loadSceneImage(spec.assetPath);
    }
  }

  Future<ui.Image> _loadSceneImage(String assetPath) async {
    final densityAssetPath = _densityAssetPathFor(assetPath);
    try {
      return await images.load(densityAssetPath);
    } on FlutterError catch (error) {
      if (densityAssetPath != assetPath) {
        try {
          return await images.load(assetPath);
        } on FlutterError {
          // Fall through to the legacy fallback map below.
        }
      }
      final fallbackAssetPath = _homeSceneAssetFallbacks[assetPath];
      if (fallbackAssetPath == null) {
        rethrow;
      }
      debugPrint(
        'HomeSceneGame asset $densityAssetPath missing from bundle; '
        'falling back to $fallbackAssetPath. ${error.message}',
      );
      return images.load(fallbackAssetPath);
    }
  }

  String _densityAssetPathFor(String assetPath) {
    final density = _homeSceneAssetDensityFor(
      devicePixelRatio ?? _homeSceneCurrentDevicePixelRatio(),
    );
    if (density == null || !_homeSceneDensityAwareAssets.contains(assetPath)) {
      return assetPath;
    }
    final slashIndex = assetPath.lastIndexOf('/');
    if (slashIndex < 0) {
      return '${density}x/$assetPath';
    }
    return '${assetPath.substring(0, slashIndex)}/${density}x/'
        '${assetPath.substring(slashIndex + 1)}';
  }

  void startExitAnimation() {
    if (!_ready || _exitTriggered) {
      return;
    }
    _exitTriggered = true;
    _uiRebuildGeneration += 1;

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

  Future<void> _rebuildUiFromProfile() async {
    if (_exitTriggered) {
      return;
    }

    final rebuildGeneration = ++_uiRebuildGeneration;
    final previousComponents = List<_AnimatedSceneComponent>.from(
      _animatedComponents,
    );
    final nextComponents = <_AnimatedSceneComponent>[];
    _SceneSpriteComponent? nextTaskNoteComponent;
    _SceneSpriteComponent? nextFamilyPhotoComponent;
    try {
      final sceneSpecs = <_UiSpec>[..._profile.specs, ..._buildPetSpecs()];
      final backgroundRect = _background.layoutRect;

      for (final spec in sceneSpecs) {
        final component = spec.build(
          sceneSize: _sceneSize,
          backgroundRect: backgroundRect,
        );
        if (component is _SceneSpriteComponent &&
            component.behavior == _SceneSpriteBehavior.taskNote) {
          nextTaskNoteComponent = component;
        }
        if (component is _SceneSpriteComponent &&
            component.behavior == _SceneSpriteBehavior.familyPhoto) {
          nextFamilyPhotoComponent = component;
        }
        nextComponents.add(component);
      }
    } catch (error, stackTrace) {
      debugPrint('HomeSceneGame failed to rebuild scene components: $error');
      debugPrint('$stackTrace');
      return;
    }

    try {
      await Future.wait(nextComponents.map(_addAnimated));
    } catch (error, stackTrace) {
      for (final component in nextComponents) {
        component.removeFromParent();
      }
      debugPrint('HomeSceneGame failed to load scene components: $error');
      debugPrint('$stackTrace');
      return;
    }

    for (final component in nextComponents.whereType<_SceneSpriteComponent>()) {
      if (component.isCoreHomeEntry) {
        component.makeEntryVisibleImmediately();
      }
    }

    if (_exitTriggered || rebuildGeneration != _uiRebuildGeneration) {
      for (final component in nextComponents) {
        component.removeFromParent();
      }
      return;
    }

    for (final component in previousComponents) {
      component.removeFromParent();
    }
    _animatedComponents
      ..clear()
      ..addAll(nextComponents);
    _taskNoteComponent = nextTaskNoteComponent;
    _familyPhotoComponent = nextFamilyPhotoComponent;
    _lastUiLayoutSize = _sceneSize.clone();
    onGuideAnchorLayoutChanged?.call();
    Future<void>.delayed(_homeGuideAnchorReadyDelay, () {
      if (_exitTriggered || rebuildGeneration != _uiRebuildGeneration) {
        return;
      }
      onGuideAnchorLayoutChanged?.call();
    });
  }

  Rect? _resolveTaskPanelOriginRect() {
    final taskNote = _taskNoteComponent;
    if (taskNote == null || !taskNote.isGuideAnchorReady) {
      return null;
    }
    return taskNote.guideSceneRect;
  }

  Rect? taskPanelOriginRect() => _resolveTaskPanelOriginRect();

  Rect? familyPhotoRect() {
    final familyPhoto = _familyPhotoComponent;
    if (familyPhoto == null || !familyPhoto.isGuideAnchorReady) {
      return null;
    }
    return familyPhoto.guideSceneRect;
  }

  Rect? primaryPetRect() {
    final pet = _primaryPetComponent();
    if (pet == null || !pet.isGuideAnchorReady) {
      return null;
    }
    return pet.guideSceneRect;
  }

  int? primaryPetId() {
    return _primaryPetComponent()?.petId;
  }

  String? primaryPetDetailAvatarAssetPath() {
    final petId = primaryPetId();
    if (petId == null) {
      return null;
    }
    return debugPetDetailAvatarAssetPaths()[petId];
  }

  String? guideTargetAssetPath(HomeGuideStep step) {
    return switch (step) {
      HomeGuideStep.taskSticker => _taskNoteComponent?.assetPath,
      HomeGuideStep.familyFrame => _familyPhotoComponent?.assetPath,
      HomeGuideStep.petArea => _primaryPetComponent()?.activePoseAssetPath,
      HomeGuideStep.done => null,
    };
  }

  Rect? guideTargetAssetCropRect(HomeGuideStep step) {
    return switch (step) {
      HomeGuideStep.taskSticker => _taskNoteComponent?.assetCropRect,
      HomeGuideStep.familyFrame => _familyPhotoComponent?.assetCropRect,
      HomeGuideStep.petArea => _primaryPetComponent()?.activePoseCropRect,
      HomeGuideStep.done => null,
    };
  }

  _PetSpriteComponent? _primaryPetComponent() {
    final petComponents = _animatedComponents.whereType<_PetSpriteComponent>();
    if (petComponents.isEmpty) {
      return null;
    }

    final component = petComponents.reduce((left, right) {
      final leftArea = left.sceneRect.width * left.sceneRect.height;
      final rightArea = right.sceneRect.width * right.sceneRect.height;
      return rightArea > leftArea ? right : left;
    });
    return component;
  }

  Future<void> _addAnimated(_AnimatedSceneComponent component) async {
    await world.add(component);
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

  factory _RectFactor.fromCenter({
    required double centerX,
    required double centerY,
    required double width,
    required double height,
  }) {
    return _RectFactor(
      centerX - (width / 2),
      centerY - (height / 2),
      width,
      height,
    );
  }

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
  'images/pets/grow/cat/baby/lying.png': _RectFactor(
    0.2008,
    0.2588,
    0.6313,
    0.4898,
  ),
  'images/pets/grow/cat/baby/sitting.png': _RectFactor(
    0.2737,
    0.1279,
    0.4122,
    0.6988,
  ),
  'images/pets/grow/cat/baby/stage.png': _RectFactor(
    0.1834,
    0.2037,
    0.6133,
    0.5574,
  ),
  'images/pets/grow/cat/companion/sitting.png': _RectFactor(
    0.1443,
    0.0686,
    0.7013,
    0.8478,
  ),
  'images/pets/grow/cat/companion/stage.png': _RectFactor(
    0.0941,
    0.1166,
    0.8344,
    0.7528,
  ),
  'images/pets/grow/cat/companion/stretching.png': _RectFactor(
    0.0485,
    0.1527,
    0.9003,
    0.7225,
  ),
  'images/pets/grow/cat/growing/lying.png': _RectFactor(
    0.0521,
    0.1808,
    0.9094,
    0.6848,
  ),
  'images/pets/grow/cat/growing/sitting.png': _RectFactor(
    0.0335,
    0.0201,
    0.9528,
    0.9727,
  ),
  'images/pets/grow/cat/growing/sleeping.png': _RectFactor(
    0.0331,
    0.0404,
    0.9391,
    0.9079,
  ),
  'images/pets/grow/dog/baby/lying.png': _RectFactor(
    0.1576,
    0.2371,
    0.6797,
    0.5526,
  ),
  'images/pets/grow/dog/baby/sitting.png': _RectFactor(
    0.2065,
    0.1619,
    0.5710,
    0.6388,
  ),
  'images/pets/grow/dog/baby/sleeping.png': _RectFactor(
    0.1469,
    0.2585,
    0.7275,
    0.4510,
  ),
  'images/pets/grow/dog/companion/lying.png': _RectFactor(
    0.0720,
    0.1168,
    0.8787,
    0.7398,
  ),
  'images/pets/grow/dog/companion/sitting.png': _RectFactor(
    0.1362,
    0.0940,
    0.7729,
    0.7822,
  ),
  'images/pets/grow/dog/companion/stage.png': _RectFactor(
    0.1334,
    0.0989,
    0.7354,
    0.7870,
  ),
  'images/pets/grow/dog/growing/lying.png': _RectFactor(
    0.0870,
    0.1774,
    0.8488,
    0.6533,
  ),
  'images/pets/grow/dog/growing/sitting.png': _RectFactor(
    0.0457,
    0.0215,
    0.9086,
    0.9589,
  ),
  'images/pets/grow/dog/growing/sleeping.png': _RectFactor(
    0.0395,
    0.0373,
    0.9280,
    0.9173,
  ),
  'images/pets/grow/hamster/baby/lying.png': _RectFactor(
    0.1154,
    0.2319,
    0.7353,
    0.5447,
  ),
  'images/pets/grow/hamster/baby/sitting.png': _RectFactor(
    0.1827,
    0.1814,
    0.6339,
    0.6441,
  ),
  'images/pets/grow/hamster/baby/sleeping.png': _RectFactor(
    0.0685,
    0.2134,
    0.8438,
    0.5633,
  ),
  'images/pets/grow/hamster/companion/lying.png': _RectFactor(
    0.0760,
    0.1853,
    0.8171,
    0.6106,
  ),
  'images/pets/grow/hamster/companion/sleeping.png': _RectFactor(
    0.1022,
    0.1887,
    0.8003,
    0.5985,
  ),
  'images/pets/grow/hamster/companion/stage.png': _RectFactor(
    0.1200,
    0.0269,
    0.7166,
    0.9327,
  ),
  'images/pets/grow/hamster/growing/sitting.png': _RectFactor(
    0.0133,
    0.0262,
    0.9523,
    0.9500,
  ),
  'images/pets/grow/hamster/growing/sleeping.png': _RectFactor(
    0.1008,
    0.1435,
    0.8379,
    0.6661,
  ),
  'images/pets/grow/hamster/growing/standing.png': _RectFactor(
    0.0438,
    0.0789,
    0.9072,
    0.9002,
  ),
  'images/pets/grow/rabbit/baby/lying.png': _RectFactor(
    0.2217,
    0.1794,
    0.6132,
    0.5845,
  ),
  'images/pets/grow/rabbit/baby/sleeping.png': _RectFactor(
    0.1623,
    0.1056,
    0.7261,
    0.7584,
  ),
  'images/pets/grow/rabbit/baby/stage.png': _RectFactor(
    0.2265,
    0.1045,
    0.5327,
    0.7416,
  ),
  'images/pets/grow/rabbit/companion/lying.png': _RectFactor(
    0.1599,
    0.0664,
    0.7105,
    0.8081,
  ),
  'images/pets/grow/rabbit/companion/stage.png': _RectFactor(
    0.2519,
    0.0665,
    0.5340,
    0.8174,
  ),
  'images/pets/grow/rabbit/companion/stretching.png': _RectFactor(
    0.1543,
    0.1295,
    0.6976,
    0.7148,
  ),
  'images/pets/grow/rabbit/growing/lying.png': _RectFactor(
    0.0570,
    0.0582,
    0.8803,
    0.8862,
  ),
  'images/pets/grow/rabbit/growing/sitting.png': _RectFactor(
    0.0549,
    0.0303,
    0.8863,
    0.9464,
  ),
  'images/pets/grow/rabbit/growing/sleeping.png': _RectFactor(
    0.0317,
    0.0598,
    0.9420,
    0.8932,
  ),
  'images/pets/grow/turtle/baby/crawling.png': _RectFactor(
    0.1840,
    0.2620,
    0.6369,
    0.4724,
  ),
  'images/pets/grow/turtle/baby/sleeping.png': _RectFactor(
    0.1954,
    0.2843,
    0.6170,
    0.4305,
  ),
  'images/pets/grow/turtle/baby/stage.png': _RectFactor(
    0.2368,
    0.1611,
    0.5144,
    0.6850,
  ),
  'images/pets/grow/turtle/companion/crawling.png': _RectFactor(
    0.0991,
    0.2121,
    0.8017,
    0.5829,
  ),
  'images/pets/grow/turtle/companion/sleeping.png': _RectFactor(
    0.0492,
    0.2255,
    0.8987,
    0.5428,
  ),
  'images/pets/grow/turtle/companion/waving.png': _RectFactor(
    0.1415,
    0.1178,
    0.7059,
    0.7360,
  ),
  'images/pets/grow/turtle/growing/crawling.png': _RectFactor(
    0.0336,
    0.0501,
    0.9427,
    0.8791,
  ),
  'images/pets/grow/turtle/growing/sitting.png': _RectFactor(
    0.0483,
    0.0429,
    0.9057,
    0.9325,
  ),
  'images/pets/grow/turtle/growing/sleeping.png': _RectFactor(
    0.0275,
    0.0599,
    0.9420,
    0.9072,
  ),
};

Size _resolveHomePetRenderSize({
  required Size slotSize,
  required Size sourceSize,
  required double petScale,
}) {
  if (slotSize.width <= 0 ||
      slotSize.height <= 0 ||
      sourceSize.width <= 0 ||
      sourceSize.height <= 0 ||
      petScale <= 0) {
    return Size.zero;
  }

  final fitted = applyBoxFit(BoxFit.contain, sourceSize, slotSize);
  final destination = fitted.destination;
  if (destination.isEmpty) {
    return Size.zero;
  }

  return Size(destination.width * petScale, destination.height * petScale);
}

enum _UiReferenceSpace { viewport, background }

Rect _homeSceneBackgroundLayoutRect({
  required Size sourceSize,
  required Vector2 sceneSize,
  required _SceneBackgroundFit fit,
}) {
  final scaleFactor = switch (fit) {
    _SceneBackgroundFit.cover => math.max(
      sceneSize.x / sourceSize.width,
      sceneSize.y / sourceSize.height,
    ),
    _SceneBackgroundFit.contain => math.min(
      sceneSize.x / sourceSize.width,
      sceneSize.y / sourceSize.height,
    ),
  };
  final width = sourceSize.width * scaleFactor;
  final height = sourceSize.height * scaleFactor;
  return Rect.fromCenter(
    center: Offset(sceneSize.x * 0.5, sceneSize.y * 0.5),
    width: width,
    height: height,
  );
}

Rect _resolveUiRectForReferenceSpace({
  required _RectFactor rect,
  required Vector2 sceneSize,
  required Rect backgroundRect,
  required _UiReferenceSpace referenceSpace,
}) {
  final referenceRect = switch (referenceSpace) {
    _UiReferenceSpace.viewport => Rect.fromLTWH(0, 0, sceneSize.x, sceneSize.y),
    _UiReferenceSpace.background => backgroundRect,
  };
  return rect.resolveInRect(referenceRect);
}

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
    return _resolveUiRectForReferenceSpace(
      rect: rect,
      sceneSize: sceneSize,
      backgroundRect: backgroundRect,
      referenceSpace: referenceSpace,
    );
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
    this.cropRect,
    this.renderPriority = _homeSceneUiRenderPriority,
    this.onTap,
    super.referenceSpace,
    required super.entryDelay,
    required super.entryOffset,
  });

  final String assetPath;
  final _SceneSpriteBehavior behavior;
  final double ambientPhase;
  final _RectFactor? cropRect;
  final int renderPriority;
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
      cropRect: cropRect,
      renderPriority: renderPriority,
      onTap: onTap,
      entryDelay: entryDelay,
      entryOffset: entryOffset,
    );
  }
}

class _PetPoseVariantSpec {
  const _PetPoseVariantSpec({
    required this.rect,
    required this.assetPath,
    this.cropRect,
    this.animationFrameAssetPaths = const <String>[],
    this.animationFrameDurations = const <double>[],
  });

  final _RectFactor rect;
  final String assetPath;
  final _RectFactor? cropRect;
  final List<String> animationFrameAssetPaths;
  final List<double> animationFrameDurations;
}

class _ResolvedPetPoseVariant {
  const _ResolvedPetPoseVariant({
    required this.rect,
    required this.assetPath,
    this.cropRect,
    this.animationFrameAssetPaths = const <String>[],
    this.animationFrameDurations = const <double>[],
  });

  final Rect rect;
  final String assetPath;
  final _RectFactor? cropRect;
  final List<String> animationFrameAssetPaths;
  final List<double> animationFrameDurations;
}

class _PetSpriteSpec extends _UiSpec {
  const _PetSpriteSpec({
    required this.petId,
    required super.rect,
    this.onTap,
    required this.poseVariants,
    required this.initialPoseIndex,
    this.contactShadow,
    this.renderPriority = _homePetRenderPriority,
    super.referenceSpace,
    required super.entryDelay,
    required super.entryOffset,
  });

  final int petId;
  final VoidCallback? onTap;
  final List<_PetPoseVariantSpec> poseVariants;
  final int initialPoseIndex;
  final _PetContactShadowSpec? contactShadow;
  final int renderPriority;

  @override
  _AnimatedSceneComponent build({
    required Vector2 sceneSize,
    required Rect backgroundRect,
  }) {
    final resolvedPoseVariants = List<_ResolvedPetPoseVariant>.generate(
      poseVariants.length,
      (index) {
        final variant = poseVariants[index];
        return _ResolvedPetPoseVariant(
          rect: _resolveUiRectForReferenceSpace(
            rect: variant.rect,
            sceneSize: sceneSize,
            backgroundRect: backgroundRect,
            referenceSpace: referenceSpace,
          ),
          assetPath: variant.assetPath,
          cropRect: variant.cropRect,
          animationFrameAssetPaths: variant.animationFrameAssetPaths,
          animationFrameDurations: variant.animationFrameDurations,
        );
      },
    );
    return _PetSpriteComponent(
      petId: petId,
      poseVariants: resolvedPoseVariants,
      initialPoseIndex: initialPoseIndex,
      contactShadow: contactShadow,
      renderPriority: renderPriority,
      onTap: onTap,
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
    final rect = _homeSceneBackgroundLayoutRect(
      sourceSize: Size(_sourceSize.x, _sourceSize.y),
      sceneSize: _sceneSize,
      fit: fit,
    );
    size = Vector2(rect.width, rect.height);
    position = Vector2(rect.center.dx, rect.center.dy);
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
    int priority = 0,
    required this.entryDelay,
    required this.entryOffset,
    this.onTap,
    this.pressedScale = 0.94,
    Anchor anchor = Anchor.topLeft,
  }) : super(anchor: anchor, priority: priority);

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

  void makeEntryVisibleImmediately() {
    for (final effect in children.whereType<MoveEffect>().toList()) {
      effect.removeFromParent();
    }
    for (final effect in children.whereType<OpacityEffect>().toList()) {
      effect.removeFromParent();
    }
    position = _restPosition.clone();
    opacity = 1;
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
    return _rectForPosition(position);
  }

  Rect get guideSceneRect {
    return _rectForPosition(_restPosition);
  }

  bool get isGuideAnchorReady {
    if (parent == null || _exitStarted || opacity < 0.92) {
      return false;
    }
    return (position.x - _restPosition.x).abs() <= 1.5 &&
        (position.y - _restPosition.y).abs() <= 1.5;
  }

  Rect _rectForPosition(Vector2 rectPosition) {
    final scaledWidth = size.x * scale.x;
    final scaledHeight = size.y * scale.y;
    return Rect.fromLTWH(
      rectPosition.x - (scaledWidth * anchor.x),
      rectPosition.y - (scaledHeight * anchor.y),
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

enum _SceneSpriteBehavior {
  taskNote,
  shopBasket,
  familyPhoto,
  wallBadge,
  staticOverlay,
}

class _SceneSpriteComponent extends _AnimatedSceneComponent
    with HasGameReference<HomeSceneGame> {
  _SceneSpriteComponent({
    required Rect rect,
    required this.assetPath,
    required this.behavior,
    required this.ambientPhase,
    this.cropRect,
    this.renderPriority = _homeSceneUiRenderPriority,
    required super.entryDelay,
    required super.entryOffset,
    super.onTap,
  }) : super(
         position: _positionForRect(rect, behavior),
         size: Vector2(rect.width, rect.height),
         anchor: _anchorForBehavior(behavior),
         priority: renderPriority,
         pressedScale:
             behavior == _SceneSpriteBehavior.taskNote ||
                 behavior == _SceneSpriteBehavior.wallBadge
             ? 0.94
             : 1,
       );

  final String assetPath;
  final _SceneSpriteBehavior behavior;
  final double ambientPhase;
  final _RectFactor? cropRect;
  final int renderPriority;

  Sprite? _sprite;
  final Paint _spritePaint = Paint()..filterQuality = ui.FilterQuality.medium;
  double _ambientTime = 0;
  double? _tapElapsed;
  double? _actionCountdown;
  bool _tapLocked = false;

  Rect? get assetCropRect {
    final clip = cropRect;
    if (clip == null) {
      return null;
    }
    return Rect.fromLTWH(clip.left, clip.top, clip.width, clip.height);
  }

  bool get isCoreHomeEntry {
    return behavior == _SceneSpriteBehavior.taskNote ||
        behavior == _SceneSpriteBehavior.familyPhoto ||
        behavior == _SceneSpriteBehavior.wallBadge ||
        behavior == _SceneSpriteBehavior.shopBasket ||
        (behavior == _SceneSpriteBehavior.staticOverlay && onTap != null);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final image = await game._loadSceneImage(assetPath);
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
      _SceneSpriteBehavior.wallBadge =>
        math.sin((_ambientTime * 1.5) + ambientPhase) * 0.014,
      _SceneSpriteBehavior.staticOverlay => 0,
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
      _SceneSpriteBehavior.wallBadge =>
        math.sin(progress * math.pi * 2.0) * 0.040 * (1 - (progress * 0.3)),
      _SceneSpriteBehavior.staticOverlay => 0,
    };
  }

  double _tapDuration() {
    return switch (behavior) {
      _SceneSpriteBehavior.taskNote => 0.22,
      _SceneSpriteBehavior.shopBasket => 0.22,
      _SceneSpriteBehavior.familyPhoto => 0.24,
      _SceneSpriteBehavior.wallBadge => 0.20,
      _SceneSpriteBehavior.staticOverlay => 0,
    };
  }

  double _tapActionDelay() {
    return switch (behavior) {
      _SceneSpriteBehavior.taskNote => 0.18,
      _SceneSpriteBehavior.shopBasket => 0.20,
      _SceneSpriteBehavior.familyPhoto => 0.21,
      _SceneSpriteBehavior.wallBadge => 0.12,
      _SceneSpriteBehavior.staticOverlay => 0,
    };
  }

  static Anchor _anchorForBehavior(_SceneSpriteBehavior behavior) {
    return switch (behavior) {
      _SceneSpriteBehavior.taskNote => Anchor.topCenter,
      _SceneSpriteBehavior.shopBasket => Anchor.topCenter,
      _SceneSpriteBehavior.familyPhoto => Anchor.center,
      _SceneSpriteBehavior.wallBadge => Anchor.topCenter,
      _SceneSpriteBehavior.staticOverlay => Anchor.center,
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

class _LoadedPetPoseVariant {
  _LoadedPetPoseVariant({
    required this.rect,
    this.sprite,
    this.animationFrames = const <Sprite>[],
    this.animationFrameDurations = const <double>[],
  });

  final Rect rect;
  final Sprite? sprite;
  final List<Sprite> animationFrames;
  final List<double> animationFrameDurations;
}

class _PetSpriteComponent extends _AnimatedSceneComponent
    with HasGameReference<HomeSceneGame> {
  _PetSpriteComponent({
    required this.petId,
    required List<_ResolvedPetPoseVariant> poseVariants,
    required int initialPoseIndex,
    this.contactShadow,
    this.renderPriority = _homePetRenderPriority,
    required super.entryDelay,
    required super.entryOffset,
    super.onTap,
  }) : assert(poseVariants.isNotEmpty),
       poseVariants = List<_ResolvedPetPoseVariant>.unmodifiable(poseVariants),
       _initialPoseIndex = _normalizePoseIndexFor(
         initialPoseIndex,
         poseVariants.length,
       ),
       super(
         position: Vector2(
           _initialPoseRect(poseVariants, initialPoseIndex).left,
           _initialPoseRect(poseVariants, initialPoseIndex).top,
         ),
         size: Vector2(
           _initialPoseRect(poseVariants, initialPoseIndex).width,
           _initialPoseRect(poseVariants, initialPoseIndex).height,
         ),
         priority: renderPriority,
       );

  final int petId;
  final List<_ResolvedPetPoseVariant> poseVariants;
  final int _initialPoseIndex;
  final _PetContactShadowSpec? contactShadow;
  final int renderPriority;

  final List<_LoadedPetPoseVariant> _loadedPoseVariants =
      <_LoadedPetPoseVariant>[];
  final Paint _spritePaint = Paint()..filterQuality = ui.FilterQuality.medium;
  final Paint _shadowPaint = Paint();
  late final math.Random _ambientRandom;
  late _PetMotionSpec _motionSpec;
  _PetAmbientMotionProfile _ambientMotion =
      const _PetAmbientMotionProfile.inactive();
  _ActivePetMotionAction? _activeMotionAction;
  double _animationElapsed = 0;
  double _ambientMotionElapsed = 0;
  double _ambientActivationDelay = 0;
  double _ambientBreathPhase = 0;
  double _ambientFloatPhase = 0;
  double _framePlaybackCooldown = 0;
  double _motionActionElapsed = 0;
  double _speechBubbleElapsed = 0;
  double _completionRewardElapsed = 0;
  double _idleActionCooldown = 0;
  double? _pendingTapCallbackDelay;
  int _animationIndex = 0;
  int _activePoseIndex = 0;
  _PetSpeechBubble? _speechBubble;
  _PetCompletionReward? _completionReward;
  bool _isFrameAnimationPlaying = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _ambientRandom = math.Random(_motionSeed());
    _ambientBreathPhase = _ambientRandom.nextDouble() * math.pi * 2;
    _ambientFloatPhase = _ambientRandom.nextDouble() * math.pi * 2;
    _ambientActivationDelay =
        entryDelay + 0.55 + (_ambientRandom.nextDouble() * 0.60);
    _motionSpec = _petMotionSpecForAssetPath(poseVariants.first.assetPath);

    for (final poseVariant in poseVariants) {
      _loadedPoseVariants.add(await _loadPoseVariant(poseVariant));
    }

    _applyPose(_initialPoseIndex);
    _scheduleInitialFramePlayback();
    _scheduleNextIdleAction();
  }

  @override
  void update(double dt) {
    super.update(dt);

    final activePose = _activePose;
    if (activePose == null) {
      return;
    }

    _updateFramePlayback(activePose, dt);

    _ambientMotionElapsed += dt;
    final tapDelay = _pendingTapCallbackDelay;
    if (tapDelay != null) {
      final nextTapDelay = tapDelay - dt;
      if (nextTapDelay <= 0) {
        _pendingTapCallbackDelay = null;
        onTap?.call();
      } else {
        _pendingTapCallbackDelay = nextTapDelay;
      }
    }
    final speechBubble = _speechBubble;
    if (speechBubble != null) {
      _speechBubbleElapsed += dt;
      if (_speechBubbleElapsed >= speechBubble.duration) {
        _speechBubble = null;
        _speechBubbleElapsed = 0;
      }
    }
    final completionReward = _completionReward;
    if (completionReward != null) {
      _completionRewardElapsed += dt;
      if (_completionRewardElapsed >= completionReward.duration) {
        _completionReward = null;
        _completionRewardElapsed = 0;
      }
    }
    if (_ambientMotionElapsed < _ambientActivationDelay) {
      return;
    }

    final activeMotionAction = _activeMotionAction;
    if (activeMotionAction != null) {
      _motionActionElapsed += dt;
      if (_motionActionElapsed >= activeMotionAction.duration) {
        _activeMotionAction = null;
        _motionActionElapsed = 0;
        if (!activeMotionAction.isTapFeedback) {
          _scheduleNextIdleAction();
        }
      }
      return;
    }

    _idleActionCooldown -= dt;
    if (_idleActionCooldown <= 0) {
      _startRandomIdleAction();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final sprite = _activeSprite;
    if (sprite == null) {
      return;
    }

    _renderContactShadow(canvas);
    _renderCompletionSpotlight(canvas);

    final floatOffset = _currentFloatOffset();
    final breathScale = _currentBreathScale();
    final actionTransform = _currentActionTransform();
    final rewardTransform = _currentCompletionRewardTransform();
    final combinedScaleX =
        breathScale * actionTransform.scaleX * rewardTransform.scaleX;
    final combinedScaleY =
        breathScale * actionTransform.scaleY * rewardTransform.scaleY;

    if (floatOffset != 0 ||
        actionTransform.offsetX != 0 ||
        actionTransform.offsetY != 0 ||
        rewardTransform.offsetX != 0 ||
        rewardTransform.offsetY != 0 ||
        combinedScaleX != 1 ||
        combinedScaleY != 1 ||
        actionTransform.rotation != 0 ||
        rewardTransform.rotation != 0) {
      final centerX = size.x * 0.5;
      final centerY = size.y * 0.5;
      canvas.save();
      canvas.translate(
        actionTransform.offsetX + rewardTransform.offsetX,
        floatOffset + actionTransform.offsetY + rewardTransform.offsetY,
      );
      canvas.translate(centerX, centerY);
      canvas.rotate(actionTransform.rotation + rewardTransform.rotation);
      canvas.scale(combinedScaleX, combinedScaleY);
      canvas.translate(-centerX, -centerY);
    }

    _spritePaint.color = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: opacity.clamp(0, 1).toDouble());
    sprite.render(canvas, size: size, overridePaint: _spritePaint);

    if (floatOffset != 0 ||
        actionTransform.offsetX != 0 ||
        actionTransform.offsetY != 0 ||
        rewardTransform.offsetX != 0 ||
        rewardTransform.offsetY != 0 ||
        combinedScaleX != 1 ||
        combinedScaleY != 1 ||
        actionTransform.rotation != 0 ||
        rewardTransform.rotation != 0) {
      canvas.restore();
    }

    _renderCompletionReward(canvas);
    _renderSpeechBubble(canvas);
  }

  _LoadedPetPoseVariant? get _activePose {
    if (_loadedPoseVariants.isEmpty) {
      return null;
    }
    return _loadedPoseVariants[_activePoseIndex];
  }

  Sprite? get _activeSprite {
    final activePose = _activePose;
    if (activePose == null) {
      return null;
    }
    if (_isFrameAnimationPlaying && activePose.animationFrames.isNotEmpty) {
      return activePose.animationFrames[_animationIndex];
    }
    return activePose.sprite;
  }

  String get activePoseAssetPath => poseVariants[_activePoseIndex].assetPath;

  Rect? get activePoseCropRect {
    final crop = poseVariants[_activePoseIndex].cropRect;
    if (crop == null) {
      return null;
    }
    return Rect.fromLTWH(crop.left, crop.top, crop.width, crop.height);
  }

  Future<_LoadedPetPoseVariant> _loadPoseVariant(
    _ResolvedPetPoseVariant poseVariant,
  ) async {
    final staticSprite = await _loadStaticPoseSprite(poseVariant);
    if (poseVariant.animationFrameAssetPaths.isNotEmpty) {
      final animationFrames = <Sprite>[];
      for (final frameAssetPath in poseVariant.animationFrameAssetPaths) {
        animationFrames.add(Sprite(await game.images.load(frameAssetPath)));
      }
      return _LoadedPetPoseVariant(
        rect: poseVariant.rect,
        sprite: staticSprite,
        animationFrames: animationFrames,
        animationFrameDurations: poseVariant.animationFrameDurations,
      );
    }

    return _LoadedPetPoseVariant(rect: poseVariant.rect, sprite: staticSprite);
  }

  Future<Sprite> _loadStaticPoseSprite(
    _ResolvedPetPoseVariant poseVariant,
  ) async {
    final image = await game.images.load(poseVariant.assetPath);
    final clip = poseVariant.cropRect;
    if (clip == null) {
      return Sprite(image);
    }

    final sourceSize = Vector2(image.width.toDouble(), image.height.toDouble());
    final sourceRect = clip.resolve(sourceSize);
    return Sprite(
      image,
      srcPosition: Vector2(sourceRect.left, sourceRect.top),
      srcSize: Vector2(sourceRect.width, sourceRect.height),
    );
  }

  void _applyPose(int poseIndex) {
    _activePoseIndex = _normalizePoseIndexFor(
      poseIndex,
      _loadedPoseVariants.length,
    );
    final activePose = _activePose;
    if (activePose == null) {
      return;
    }

    position.setValues(activePose.rect.left, activePose.rect.top);
    size.setValues(activePose.rect.width, activePose.rect.height);
    _animationElapsed = 0;
    _animationIndex = 0;
    _framePlaybackCooldown = 0;
    _isFrameAnimationPlaying = false;
    _motionSpec = _petMotionSpecForAssetPath(
      poseVariants[_activePoseIndex].assetPath,
    );
    _refreshAmbientMotionProfile();
  }

  double _frameDurationFor(_LoadedPetPoseVariant pose, int frameIndex) {
    if (frameIndex >= 0 && frameIndex < pose.animationFrameDurations.length) {
      return pose.animationFrameDurations[frameIndex];
    }
    return 0.18;
  }

  void _renderContactShadow(Canvas canvas) {
    final shadow = contactShadow;
    if (shadow == null) {
      return;
    }

    final shadowWidth = size.x * shadow.widthFactor;
    final shadowHeight = size.y * shadow.heightFactor;
    if (shadowWidth <= 0 || shadowHeight <= 0) {
      return;
    }

    final shadowRect = Rect.fromCenter(
      center: Offset(size.x * 0.5, size.y * shadow.centerYFactor),
      width: shadowWidth,
      height: shadowHeight,
    );
    _shadowPaint
      ..color = const Color(
        0xFF3E2A1B,
      ).withValues(alpha: shadow.opacity * opacity.clamp(0, 1).toDouble())
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        math.max(size.y * shadow.blurSigmaFactor, 1),
      );
    canvas.drawOval(shadowRect, _shadowPaint);
  }

  void _renderCompletionSpotlight(Canvas canvas) {
    final reward = _completionReward;
    if (reward == null || reward.duration <= 0) {
      return;
    }

    final progress = (_completionRewardElapsed / reward.duration)
        .clamp(0, 1)
        .toDouble();
    final fadeIn = Curves.easeOut.transform((progress / 0.14).clamp(0, 1));
    final fadeOut = progress < 0.84
        ? 1.0
        : 1 - Curves.easeIn.transform(((progress - 0.84) / 0.16).clamp(0, 1));
    final pulse =
        (0.62 +
            0.38 *
                math.sin(progress * math.pi * (reward.leveledUp ? 8.0 : 6.0))) *
        fadeIn *
        fadeOut;
    if (pulse <= 0) {
      return;
    }

    final effectUnit = _completionRewardEffectUnit();
    final spotlightRect = Rect.fromCenter(
      center: Offset(size.x * 0.5, size.y * 0.88),
      width: effectUnit * (reward.leveledUp ? 2.08 : 1.68),
      height: effectUnit * (reward.leveledUp ? 0.56 : 0.42),
    );
    final paint = Paint()
      ..color = Color(
        reward.leveledUp ? 0xFFFFD45C : 0xFFFFE18A,
      ).withValues(alpha: pulse * (reward.leveledUp ? 0.40 : 0.30))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    canvas.drawOval(spotlightRect, paint);
  }

  void _renderSpeechBubble(Canvas canvas) {
    final bubble = _speechBubble;
    if (bubble == null || bubble.message.trim().isEmpty) {
      return;
    }

    final progress = (_speechBubbleElapsed / bubble.duration)
        .clamp(0, 1)
        .toDouble();
    final fadeIn = Curves.easeOut.transform((progress / 0.18).clamp(0, 1));
    final fadeOut = progress < 0.76
        ? 1.0
        : 1 - Curves.easeIn.transform(((progress - 0.76) / 0.24).clamp(0, 1));
    final opacity = (fadeIn * fadeOut).clamp(0, 1).toDouble();
    if (opacity <= 0) {
      return;
    }

    final message = bubble.message;
    final fontSize = math.max(
      size.y * (bubble.emphasized ? 0.180 : 0.158),
      bubble.emphasized ? 24.0 : 20.0,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(
          color: Color(0xFF4D3623).withValues(alpha: opacity),
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(size.x * 3.2, game.size.x * 0.42));

    final paddingX = fontSize * 0.72;
    final paddingY = fontSize * 0.44;
    final bubbleWidth = textPainter.width + paddingX * 2;
    final bubbleHeight = textPainter.height + paddingY * 2;
    final centerX = size.x * 0.5;
    final popScale =
        1 +
        (bubble.emphasized
            ? 0.18 * _holdPulse(progress, begin: 0.02, end: 0.30)
            : 0.12 * _holdPulse(progress, begin: 0.02, end: 0.26));
    final bottomY = -size.y * 0.14 - (size.y * 0.18 * progress);
    final rect = Rect.fromCenter(
      center: Offset(centerX, bottomY - bubbleHeight * 0.5),
      width: bubbleWidth * popScale,
      height: bubbleHeight * popScale,
    );
    final radius = Radius.circular(bubbleHeight * 0.45);
    final fillPaint = Paint()
      ..color = (bubble.emphasized ? Color(0xFFFFF1BB) : Color(0xFFFFF8E9))
          .withValues(alpha: opacity * 0.96);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(fontSize * 0.08, 1.4)
      ..color = (bubble.emphasized ? Color(0xFFE38A2E) : Color(0xFF8A623C))
          .withValues(alpha: opacity * 0.86);
    final shadowPaint = Paint()
      ..color = Color(0x55382415).withValues(alpha: opacity * 0.36)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    canvas.drawRRect(rrect.shift(Offset(0, fontSize * 0.10)), shadowPaint);
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, borderPaint);

    final tailPath = Path()
      ..moveTo(centerX - fontSize * 0.32, rect.bottom - 1)
      ..lineTo(centerX + fontSize * 0.18, rect.bottom - 1)
      ..lineTo(centerX - fontSize * 0.08, rect.bottom + fontSize * 0.36)
      ..close();
    canvas.drawPath(tailPath, fillPaint);
    canvas.drawPath(tailPath, borderPaint);

    textPainter.paint(
      canvas,
      Offset(rect.left + paddingX, rect.top + paddingY),
    );
  }

  void _renderCompletionReward(Canvas canvas) {
    final reward = _completionReward;
    if (reward == null) {
      return;
    }

    final progress = (_completionRewardElapsed / reward.duration)
        .clamp(0, 1)
        .toDouble();
    final visibleOpacity = progress < 0.78
        ? Curves.easeOut.transform((progress / 0.12).clamp(0, 1))
        : progress < 0.88
        ? 1.0
        : 1 - Curves.easeIn.transform(((progress - 0.88) / 0.12).clamp(0, 1));
    final opacity = visibleOpacity.clamp(0, 1).toDouble();
    if (opacity <= 0) {
      return;
    }

    _renderRewardHalo(canvas, progress, opacity, reward.leveledUp);
    _renderRewardStars(canvas, progress, opacity, reward.leveledUp);
    _renderRewardPoints(canvas, progress, opacity, reward);
  }

  void _renderRewardHalo(
    Canvas canvas,
    double progress,
    double opacity,
    bool leveledUp,
  ) {
    final haloProgress = (progress / (leveledUp ? 0.96 : 0.88))
        .clamp(0, 1)
        .toDouble();
    final haloFade = progress < 0.84
        ? 1.0
        : 1 - Curves.easeIn.transform(((progress - 0.84) / 0.16).clamp(0, 1));
    final haloPulse =
        (0.48 + 0.52 * math.sin(progress * math.pi * (leveledUp ? 6.0 : 4.5))) *
        Curves.easeOut.transform((progress / 0.12).clamp(0, 1)) *
        haloFade;
    if (haloPulse <= 0) {
      return;
    }

    final center = Offset(size.x * 0.5, size.y * 0.54);
    final effectUnit = _completionRewardEffectUnit();
    final baseRadius = effectUnit * (leveledUp ? 1.12 : 0.88);
    final radius = baseRadius * (0.58 + haloProgress * 0.72);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(
        effectUnit * (leveledUp ? 0.052 : 0.038),
        leveledUp ? 4.0 : 3.0,
      )
      ..color = Color(
        leveledUp ? 0xFFFFD55B : 0xFFFFC85A,
      ).withValues(alpha: opacity * haloPulse * (leveledUp ? 0.88 : 0.62));

    canvas.drawCircle(center, radius, paint);
  }

  void _renderRewardStars(
    Canvas canvas,
    double progress,
    double opacity,
    bool leveledUp,
  ) {
    final count = leveledUp ? 14 : 9;
    final center = Offset(size.x * 0.5, size.y * 0.38);
    final minDimension = _completionRewardEffectUnit();
    for (var index = 0; index < count; index++) {
      final stagger = index * (leveledUp ? 0.022 : 0.028);
      final local = ((progress - stagger) / (leveledUp ? 0.84 : 0.76))
          .clamp(0, 1)
          .toDouble();
      if (local <= 0 || local >= 1) {
        continue;
      }

      final arrival = Curves.easeOutCubic.transform(local);
      final angle =
          (-math.pi * 0.95) + (index * math.pi * 1.9 / math.max(count - 1, 1));
      final startRadius = minDimension * (leveledUp ? 1.34 : 1.08);
      final wobble =
          math.sin((local * math.pi * 2.7) + index) * minDimension * 0.045;
      final start = Offset(
        center.dx + math.cos(angle) * startRadius,
        center.dy + math.sin(angle) * startRadius - minDimension * 0.18,
      );
      final target = Offset(
        center.dx + math.cos(angle * 0.55) * minDimension * 0.26,
        center.dy + math.sin(angle * 0.40) * minDimension * 0.17,
      );
      final position = Offset(
        ui.lerpDouble(start.dx, target.dx, arrival)! + wobble,
        ui.lerpDouble(start.dy, target.dy, arrival)! -
            math.sin(local * math.pi) * minDimension * 0.30,
      );
      final starOpacity =
          opacity *
          math.sin(local * math.pi).clamp(0, 1).toDouble() *
          (leveledUp ? 0.96 : 0.82);
      final starSize =
          minDimension * (leveledUp ? 0.118 : 0.092) * (1.08 - local * 0.18);
      _drawRewardStar(
        canvas,
        center: position,
        radius: starSize,
        rotation: (local * math.pi * 1.4) + index,
        opacity: starOpacity,
      );
    }
  }

  void _drawRewardStar(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double rotation,
    required double opacity,
  }) {
    if (radius <= 0 || opacity <= 0) {
      return;
    }

    final path = Path();
    for (var index = 0; index < 10; index++) {
      final isOuter = index.isEven;
      final currentRadius = isOuter ? radius : radius * 0.48;
      final angle = rotation - math.pi / 2 + (index * math.pi / 5);
      final point = Offset(
        center.dx + math.cos(angle) * currentRadius,
        center.dy + math.sin(angle) * currentRadius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final shadowPaint = Paint()
      ..color = Color(0xFF7A4B19).withValues(alpha: opacity * 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final fillPaint = Paint()
      ..color = Color(0xFFFFD75E).withValues(alpha: opacity);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(radius * 0.12, 1)
      ..color = Color(0xFFA96C23).withValues(alpha: opacity * 0.82);

    canvas.drawPath(path.shift(Offset(0, radius * 0.12)), shadowPaint);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  void _renderRewardPoints(
    Canvas canvas,
    double progress,
    double opacity,
    _PetCompletionReward reward,
  ) {
    final local = ((progress - 0.06) / 0.88).clamp(0, 1).toDouble();
    if (local <= 0 || local >= 1) {
      return;
    }

    final textFadeIn = Curves.easeOut.transform((local / 0.10).clamp(0, 1));
    final textFadeOut = local < 0.82
        ? 1.0
        : 1 - Curves.easeIn.transform(((local - 0.82) / 0.18).clamp(0, 1));
    final textOpacity = opacity * textFadeIn * textFadeOut;
    final clampedTextOpacity = textOpacity.clamp(0, 1).toDouble();
    if (textOpacity <= 0) {
      return;
    }

    final label = reward.leveledUp && reward.level != null
        ? '+${reward.points}  Lv.${reward.level}'
        : '+${reward.points}';
    final effectUnit = _completionRewardEffectUnit();
    final fontSize = math.max(
      effectUnit * (reward.leveledUp ? 0.34 : 0.28),
      reward.leveledUp ? 28.0 : 24.0,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Color(
            reward.leveledUp ? 0xFFFF8E2E : 0xFF6B8F2A,
          ).withValues(alpha: clampedTextOpacity),
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1,
          shadows: <Shadow>[
            Shadow(
              color: Color(
                0xFFFFF8E8,
              ).withValues(alpha: clampedTextOpacity * 0.90),
              blurRadius: 5,
            ),
            Shadow(
              color: Color(
                0xFF4B2C14,
              ).withValues(alpha: clampedTextOpacity * 0.22),
              blurRadius: 2,
              offset: Offset(0, fontSize * 0.08),
            ),
          ],
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(size.x * 2.0, game.size.x * 0.40));

    final jump = Curves.easeOutCubic.transform((local / 0.72).clamp(0, 1));
    final x =
        size.x * 0.52 + math.sin(local * math.pi * 0.9) * effectUnit * 0.08;
    final y = size.y * 0.12 - (effectUnit * 0.54 * jump);
    textPainter.paint(canvas, Offset(x, y));
  }

  double _completionRewardEffectUnit() {
    final sceneUnit = math.min(game.size.x, game.size.y) * 0.105;
    final petUnit = math.min(size.x, size.y);
    return math.max(petUnit, sceneUnit);
  }

  void _refreshAmbientMotionProfile() {
    final sceneHeight = math.max(game.size.y, 1);
    final normalizedDepth = ((position.y + size.y) / sceneHeight)
        .clamp(0, 1)
        .toDouble();
    _ambientMotion = _petAmbientMotionProfileForDepth(normalizedDepth);
  }

  void _scheduleNextIdleAction() {
    _idleActionCooldown = _randomBetween(
      _motionSpec.idleDelayMin,
      _motionSpec.idleDelayMax,
    );
  }

  void _scheduleInitialFramePlayback() {
    final activePose = _activePose;
    if (activePose == null || activePose.animationFrames.length < 2) {
      _framePlaybackCooldown = 0;
      _isFrameAnimationPlaying = false;
      return;
    }
    _framePlaybackCooldown = debugInitialFramePlaybackDelay(
      assetPath: poseVariants[_activePoseIndex].assetPath,
      seedLeft: activePose.rect.left,
      seedTop: activePose.rect.top,
      poseVariantCount: poseVariants.length,
      renderPriority: renderPriority,
      entryDelay: entryDelay,
    );
  }

  void _scheduleNextFramePlayback() {
    final activePose = _activePose;
    if (activePose == null || activePose.animationFrames.length < 2) {
      _framePlaybackCooldown = 0;
      return;
    }

    final timing = _petFramePlaybackTimingForAssetPath(
      poseVariants[_activePoseIndex].assetPath,
    );
    _framePlaybackCooldown = _randomBetweenFor(
      _ambientRandom,
      timing.pauseMin,
      timing.pauseMax,
    );
  }

  void _startFramePlayback() {
    _isFrameAnimationPlaying = true;
    _animationElapsed = 0;
    _animationIndex = 0;
    _framePlaybackCooldown = 0;
  }

  void _finishFramePlayback() {
    _isFrameAnimationPlaying = false;
    _animationElapsed = 0;
    _animationIndex = 0;
    _scheduleNextFramePlayback();
  }

  void _updateFramePlayback(_LoadedPetPoseVariant activePose, double dt) {
    final animationFrames = activePose.animationFrames;
    if (animationFrames.length < 2) {
      _framePlaybackCooldown = 0;
      _isFrameAnimationPlaying = false;
      _animationElapsed = 0;
      _animationIndex = 0;
      return;
    }

    if (!_isFrameAnimationPlaying) {
      _animationIndex = 0;
      _animationElapsed = 0;
      _framePlaybackCooldown -= dt;
      if (_framePlaybackCooldown <= 0) {
        _startFramePlayback();
      }
      return;
    }

    _animationElapsed += dt;
    while (_isFrameAnimationPlaying &&
        _animationElapsed >= _frameDurationFor(activePose, _animationIndex)) {
      _animationElapsed -= _frameDurationFor(activePose, _animationIndex);
      if (_animationIndex >= animationFrames.length - 1) {
        _finishFramePlayback();
      } else {
        _animationIndex += 1;
      }
    }
  }

  void _startRandomIdleAction() {
    _scheduleNextIdleAction();
  }

  void playCompletionReaction({
    required String message,
    required int points,
    required bool leveledUp,
    required int? level,
  }) {
    _speechBubble = _PetSpeechBubble(
      message: message,
      duration: leveledUp ? 4.80 : 4.20,
      emphasized: leveledUp,
    );
    _speechBubbleElapsed = 0;
    _completionReward = _PetCompletionReward(
      points: math.max(points, 0),
      leveledUp: leveledUp,
      level: level,
      duration: leveledUp ? 4.60 : 4.00,
    );
    _completionRewardElapsed = 0;
    _activeMotionAction = null;
    _motionActionElapsed = 0;
    _ambientActivationDelay = math.min(
      _ambientActivationDelay,
      _ambientMotionElapsed,
    );
    _idleActionCooldown = math.max(_idleActionCooldown, leveledUp ? 4.7 : 4.1);
    final activePose = _activePose;
    if (activePose != null && activePose.animationFrames.length > 1) {
      _startFramePlayback();
    }
  }

  double _currentMotionWeight() {
    final progress = ((_ambientMotionElapsed - _ambientActivationDelay) / 0.85)
        .clamp(0, 1)
        .toDouble();
    return Curves.easeOut.transform(progress);
  }

  double _currentBreathScale() {
    final weight = _currentMotionWeight();
    final amplitude =
        _motionSpec.breathAmplitude * _ambientMotion.breathAmplitude;
    if (weight <= 0 || amplitude <= 0) {
      return 1;
    }
    return 1 +
        (math.sin(
              (_ambientMotionElapsed *
                      _motionSpec.breathSpeed *
                      _ambientMotion.breathSpeed) +
                  _ambientBreathPhase,
            ) *
            amplitude *
            weight);
  }

  double _currentFloatOffset() {
    final weight = _currentMotionWeight();
    final amplitude =
        _motionSpec.floatAmplitude * _ambientMotion.floatAmplitude;
    if (weight <= 0 || amplitude <= 0) {
      return 0;
    }
    return math.sin(
          (_ambientMotionElapsed * _motionSpec.floatSpeed) + _ambientFloatPhase,
        ) *
        amplitude *
        weight;
  }

  _PetMotionTransform _currentActionTransform() {
    final weight = _currentMotionWeight();
    final activeMotionAction = _activeMotionAction;
    if (weight <= 0 ||
        activeMotionAction == null ||
        activeMotionAction.duration <= 0) {
      return const _PetMotionTransform();
    }
    final progress = (_motionActionElapsed / activeMotionAction.duration)
        .clamp(0, 1)
        .toDouble();
    final unit = math.max(math.min(size.x, size.y) * 0.028, 0.35);
    return _petMotionTransformForAction(
      kind: activeMotionAction.kind,
      progress: progress,
      unit: unit,
      amplitudeScale: _ambientMotion.wobbleAmplitude * weight,
    );
  }

  _PetMotionTransform _currentCompletionRewardTransform() {
    return const _PetMotionTransform();
  }

  double _randomBetween(double min, double max) {
    if (max <= min) {
      return min;
    }
    return min + (_ambientRandom.nextDouble() * (max - min));
  }

  int _motionSeed() {
    return _motionSeedFor(
      assetPath: poseVariants[_initialPoseIndex].assetPath,
      seedLeft: _initialPoseRect(poseVariants, _initialPoseIndex).left,
      seedTop: _initialPoseRect(poseVariants, _initialPoseIndex).top,
      poseVariantCount: poseVariants.length,
      renderPriority: renderPriority,
    );
  }

  @override
  void triggerTapAction() {
    onTap?.call();
  }

  static double debugInitialFramePlaybackDelay({
    required String assetPath,
    required double seedLeft,
    required double seedTop,
    required int poseVariantCount,
    required int renderPriority,
    required double entryDelay,
  }) {
    final timing = _petFramePlaybackTimingForAssetPath(assetPath);
    final random = math.Random(
      _motionSeedFor(
        assetPath: assetPath,
        seedLeft: seedLeft,
        seedTop: seedTop,
        poseVariantCount: poseVariantCount,
        renderPriority: renderPriority,
      ),
    );
    random.nextDouble();
    random.nextDouble();
    random.nextDouble();
    return entryDelay +
        _randomBetweenFor(random, timing.pauseMin, timing.pauseMax);
  }

  static int _motionSeedFor({
    required String assetPath,
    required double seedLeft,
    required double seedTop,
    required int poseVariantCount,
    required int renderPriority,
  }) {
    return assetPath.hashCode ^
        (seedLeft * 1000).round() ^
        (seedTop * 1000).round() ^
        poseVariantCount ^
        renderPriority;
  }

  static Rect _initialPoseRect(
    List<_ResolvedPetPoseVariant> poseVariants,
    int initialPoseIndex,
  ) {
    final normalizedIndex = _normalizePoseIndexFor(
      initialPoseIndex,
      poseVariants.length,
    );
    return poseVariants[normalizedIndex].rect;
  }

  static int _normalizePoseIndexFor(int poseIndex, int poseCount) {
    if (poseCount <= 0) {
      return 0;
    }
    final normalized = poseIndex % poseCount;
    return normalized < 0 ? normalized + poseCount : normalized;
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
  late final _TaskPanelCloseButton _closeButton;
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
    )..paint.filterQuality = ui.FilterQuality.high;
    _panelBoard = boardComponent;
    _panelRoot.add(boardComponent);

    final closeButton =
        _TaskPanelCloseButton(
            size: Vector2.all(_basePanelSize.x * 0.13),
            onPressed: startExit,
          )
          ..anchor = Anchor.center
          ..position = _closeButtonPosition();
    _closeButton = closeButton;
    add(closeButton);
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
      )..paint.filterQuality = ui.FilterQuality.high,
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
    _closeButton.position = _closeButtonPosition();
  }

  Vector2 _closeButtonPosition() {
    final panelCenter = _openPanelTargetPosition();
    return Vector2(
      panelCenter.x + (_basePanelSize.x * 0.43),
      panelCenter.y - (_basePanelSize.y * 0.43),
    );
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
    _closeButton.position = _closeButtonPosition();
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
    _animateContentExit(_closeButton, startDelay: 0.01);
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

class _TaskPanelCloseButton extends PositionComponent with TapCallbacks {
  _TaskPanelCloseButton({required Vector2 size, required this.onPressed})
    : super(size: size, priority: 4);

  final VoidCallback onPressed;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x * 0.5, size.y * 0.5);
    final radius = math.min(size.x, size.y) * 0.5;
    final fillPaint = Paint()..color = const Color(0xFFFFF3DC);
    final borderPaint = Paint()
      ..color = const Color(0xFFA36A22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, size.x * 0.064);
    final iconPaint = Paint()
      ..color = const Color(0xFF8A5414)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.2, size.x * 0.082);
    final shadowPaint = Paint()
      ..color = const Color(0x4D6D451E)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(center.translate(0, size.y * 0.08), radius, shadowPaint);
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);

    final inset = size.x * 0.32;
    canvas.drawLine(
      Offset(inset, inset),
      Offset(size.x - inset, size.y - inset),
      iconPaint,
    );
    canvas.drawLine(
      Offset(size.x - inset, inset),
      Offset(inset, size.y - inset),
      iconPaint,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    onPressed();
    super.onTapDown(event);
  }
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
      )..paint.filterQuality = ui.FilterQuality.high,
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
      )..paint.filterQuality = ui.FilterQuality.high,
    );
    add(
      SpriteComponent(
          sprite: rowFieldSprite,
          position: Vector2(size.x * 0.16 + (fieldWidth * 0.5), size.y * 0.50),
          size: Vector2(fieldWidth, fieldHeight),
          anchor: Anchor.center,
        )
        ..paint.filterQuality = ui.FilterQuality.high
        ..opacity = highlighted ? 0.94 : 0.84,
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
