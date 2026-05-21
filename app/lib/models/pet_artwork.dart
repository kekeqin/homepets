const List<String> selectablePetTypes = <String>[
  'cat',
  'dog',
  'hamster',
  'rabbit',
  'turtle',
];

const String _petAvatarAssetBasePath = 'assets/images/pets/';
const String _petHomeAssetBasePath = 'images/pets/';

enum PetGrowthStage { baby, growing, companion }

const Map<PetGrowthStage, String> _petGrowthStagePathSegments =
    <PetGrowthStage, String>{
      PetGrowthStage.baby: 'baby',
      PetGrowthStage.growing: 'growing',
      PetGrowthStage.companion: 'companion',
    };

const Map<String, List<String>> _petPoseVariants = <String, List<String>>{
  'cat': <String>[
    'pets/cat_lying.png',
    'pets/cat_sit.png',
    'pets/cat_sleep.png',
  ],
  'dog': <String>[
    'pets/dog_lying.png',
    'pets/dog_sit.png',
    'pets/dog_sleep.png',
  ],
  'hamster': <String>[
    'pets/hamster_stand.png',
    'pets/hamster_sit.png',
    'pets/hamster_sleep.png',
  ],
  'rabbit': <String>[
    'pets/rabbit_lying.png',
    'pets/rabbit_sit.png',
    'pets/rabbit_sleep.png',
  ],
  'turtle': <String>[
    'pets/turtle_lying.png',
    'pets/turtle_sit.png',
    'pets/turtle_sleep.png',
  ],
};

const Map<String, List<String>> _petHomePoseVariants = <String, List<String>>{
  'cat': <String>[
    'pets/cat_lying.png',
    'pets/cat_sit.png',
    'pets/cat_sleep.png',
  ],
  'dog': <String>[
    'pets/dog_lying.png',
    'pets/dog_sit.png',
    'pets/dog_sleep.png',
  ],
  'hamster': <String>[
    'pets/hamster_stand.png',
    'pets/hamster_sit.png',
    'pets/hamster_sleep.png',
  ],
  'rabbit': <String>[
    'pets/rabbit_lying.png',
    'pets/rabbit_sit.png',
    'pets/rabbit_sleep.png',
  ],
  'turtle': <String>[
    'pets/turtle_lying.png',
    'pets/turtle_sit.png',
    'pets/turtle_sleep.png',
  ],
};

const Map<String, Map<PetGrowthStage, List<String>>>
_petGrowthPoseVariants = <String, Map<PetGrowthStage, List<String>>>{
  'cat': <PetGrowthStage, List<String>>{
    PetGrowthStage.baby: <String>['lying.png', 'sitting.png', 'stage.png'],
    PetGrowthStage.growing: <String>[
      'lying.png',
      'sitting.png',
      'sleeping.png',
    ],
    PetGrowthStage.companion: <String>[
      'sitting.png',
      'stage.png',
      'stretching.png',
    ],
  },
  'dog': <PetGrowthStage, List<String>>{
    PetGrowthStage.baby: <String>['lying.png', 'sitting.png', 'sleeping.png'],
    PetGrowthStage.growing: <String>[
      'lying.png',
      'sitting.png',
      'sleeping.png',
    ],
    PetGrowthStage.companion: <String>['lying.png', 'sitting.png', 'stage.png'],
  },
  'hamster': <PetGrowthStage, List<String>>{
    PetGrowthStage.baby: <String>['lying.png', 'sitting.png', 'sleeping.png'],
    PetGrowthStage.growing: <String>[
      'standing.png',
      'sitting.png',
      'sleeping.png',
    ],
    PetGrowthStage.companion: <String>[
      'lying.png',
      'sleeping.png',
      'stage.png',
    ],
  },
  'rabbit': <PetGrowthStage, List<String>>{
    PetGrowthStage.baby: <String>['lying.png', 'sleeping.png', 'stage.png'],
    PetGrowthStage.growing: <String>[
      'lying.png',
      'sitting.png',
      'sleeping.png',
    ],
    PetGrowthStage.companion: <String>[
      'lying.png',
      'stage.png',
      'stretching.png',
    ],
  },
  'turtle': <PetGrowthStage, List<String>>{
    PetGrowthStage.baby: <String>['crawling.png', 'sleeping.png', 'stage.png'],
    PetGrowthStage.growing: <String>[
      'crawling.png',
      'sitting.png',
      'sleeping.png',
    ],
    PetGrowthStage.companion: <String>[
      'crawling.png',
      'sleeping.png',
      'waving.png',
    ],
  },
};

const Map<String, String> _petTypeLabels = <String, String>{
  'cat': '\u5c0f\u732b',
  'dog': '\u5c0f\u72d7',
  'hamster': '\u4ed3\u9f20',
  'rabbit': '\u5c0f\u767d\u5154',
  'turtle': '\u4e4c\u9f9f',
};

String normalizePetType(String petType, {String fallback = 'dog'}) {
  final normalized = petType.trim().toLowerCase();
  if (_petPoseVariants.containsKey(normalized)) {
    return normalized;
  }
  return fallback;
}

String petTypeLabel(String petType) =>
    _petTypeLabels[normalizePetType(petType)]!;

List<String> petPoseVariantsForType(String petType) {
  final list = _petPoseVariants[normalizePetType(petType)];
  return list ?? _petPoseVariants['dog']!;
}

List<String> petHomePoseVariantsForType(String petType) {
  final normalized = normalizePetType(petType);
  final list = _petHomePoseVariants[normalized] ?? _petPoseVariants[normalized];
  return list ?? _petPoseVariants['dog']!;
}

PetGrowthStage petGrowthStageForLevel(int level) {
  if (level <= 1) {
    return PetGrowthStage.baby;
  }
  if (level <= 3) {
    return PetGrowthStage.growing;
  }
  return PetGrowthStage.companion;
}

String petGrowthStageLabel(PetGrowthStage stage) {
  return switch (stage) {
    PetGrowthStage.baby => '\u5e7c\u5d3d\u671f',
    PetGrowthStage.growing => '\u6210\u957f\u671f',
    PetGrowthStage.companion => '\u4f19\u4f34\u671f',
  };
}

List<String> petGrowthPoseVariantsForType(
  String petType,
  PetGrowthStage stage,
) {
  final normalized = normalizePetType(petType);
  final stageMap =
      _petGrowthPoseVariants[normalized] ?? _petGrowthPoseVariants['dog']!;
  return stageMap[stage] ?? stageMap[PetGrowthStage.growing]!;
}

List<String> petGrowthHomePoseVariantsForType(String petType, int level) {
  return petGrowthPoseVariantsForType(petType, petGrowthStageForLevel(level));
}

int deterministicPetGrowthPoseIndex(String petType, int level, int seed) {
  final variants = petGrowthHomePoseVariantsForType(petType, level);
  final adjustedSeed =
      (seed ^ petType.hashCode ^ petGrowthStageForLevel(level).index) &
      0x7fffffff;
  return variants.isEmpty ? 0 : adjustedSeed % variants.length;
}

String _petGrowthAssetRelativePath(String petType, int level, int poseIndex) {
  final normalized = normalizePetType(petType);
  final stage = petGrowthStageForLevel(level);
  final stageSegment = _petGrowthStagePathSegments[stage]!;
  final variants = petGrowthPoseVariantsForType(normalized, stage);
  if (variants.isEmpty) {
    return 'grow/dog/growing/lying.png';
  }
  final index = poseIndex % variants.length;
  return 'grow/$normalized/$stageSegment/${variants[index]}';
}

int deterministicPetPoseIndex(String petType, int seed) {
  final variants = petPoseVariantsForType(petType);
  final adjustedSeed = (seed ^ petType.hashCode) & 0x7fffffff;
  return variants.isEmpty ? 0 : adjustedSeed % variants.length;
}

int deterministicHomePetPoseIndex(String petType, int seed) {
  final variants = petHomePoseVariantsForType(petType);
  final adjustedSeed = (seed ^ petType.hashCode) & 0x7fffffff;
  return variants.isEmpty ? 0 : adjustedSeed % variants.length;
}

String petAvatarAssetPath(String petType, int poseIndex) {
  final variants = petPoseVariantsForType(petType);
  if (variants.isEmpty) {
    return '${_petAvatarAssetBasePath}pets/dog_lying.png';
  }
  final index = poseIndex % variants.length;
  return '$_petAvatarAssetBasePath${variants[index]}';
}

String petGrowthAvatarAssetPath(String petType, int level, int poseIndex) {
  return '$_petAvatarAssetBasePath${_petGrowthAssetRelativePath(petType, level, poseIndex)}';
}

String petHomeAssetPath(String petType, int poseIndex) {
  final variants = petHomePoseVariantsForType(petType);
  if (variants.isEmpty) {
    return '${_petHomeAssetBasePath}pets/dog_lying.png';
  }
  final index = poseIndex % variants.length;
  return '$_petHomeAssetBasePath${variants[index]}';
}

String petGrowthHomeAssetPath(String petType, int level, int poseIndex) {
  return '$_petHomeAssetBasePath${_petGrowthAssetRelativePath(petType, level, poseIndex)}';
}

String petGrowthHomeAssetPathForPose(
  String petType,
  int level,
  String poseName,
) {
  final normalized = normalizePetType(petType);
  final stage = petGrowthStageForLevel(level);
  final stageSegment = _petGrowthStagePathSegments[stage]!;
  return '$_petHomeAssetBasePath'
      'grow/$normalized/$stageSegment/${poseName.trim()}';
}

String petDetailAvatarAssetPathForHomeAssetPath(String assetPath) {
  if (assetPath.startsWith('assets/')) {
    return assetPath;
  }
  if (assetPath.startsWith('images/')) {
    return 'assets/$assetPath';
  }
  return assetPath;
}

String defaultHomePetDetailAvatarAssetPath(String petType, int petId) {
  return petDetailAvatarAssetPathForHomeAssetPath(
    petHomeAssetPath(petType, deterministicHomePetPoseIndex(petType, petId)),
  );
}

String defaultGrowthPetDetailAvatarAssetPath(
  String petType,
  int level,
  int petId,
) {
  return petDetailAvatarAssetPathForHomeAssetPath(
    petGrowthHomeAssetPath(
      petType,
      level,
      deterministicPetGrowthPoseIndex(petType, level, petId),
    ),
  );
}

String petDisplayName(String petType) =>
    _petTypeLabels[normalizePetType(petType)] ?? '\u5c0f\u5ba0\u7269';
