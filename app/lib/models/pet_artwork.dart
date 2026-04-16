const List<String> selectablePetTypes = <String>[
  'cat',
  'dog',
  'hamster',
  'rabbit',
  'turtle',
];

const Map<String, List<String>> _petPoseVariants = <String, List<String>>{
  'cat': <String>['cat_lie.png', 'cat_sit.png', 'cat_sleep_clean.png'],
  'dog': <String>['dog_lie.png', 'dog_sit.png', 'dog_sleep_clean.png'],
  'hamster': <String>[
    'hamster_lie_.png',
    'hamster_sit.png',
    'hamster_sleep.png',
  ],
  'rabbit': <String>['rabbit_lie.png', 'rabbit_sit.png', 'rabbit_sleep.png'],
  'turtle': <String>['turtle_lie.png', 'turtle_sit.png', 'turtle_sleep.png'],
};

const Map<String, List<String>> _petHomePoseVariants = <String, List<String>>{
  'cat': <String>['cat_lie.png', 'cat_sit.png', 'cat_sleep_clean.png'],
  'dog': <String>['dog_lie.png', 'dog_sit.png', 'dog_sleep_clean.png'],
  'hamster': <String>[
    'hamster_lie_.png',
    'hamster_sit.png',
    'hamster_sleep.png',
  ],
  'rabbit': <String>['rabbit_sit.png', 'rabbit_sleep.png'],
  'turtle': <String>['turtle_sleep.png'],
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
    return 'assets/images/pets/dog_lie.png';
  }
  final index = poseIndex % variants.length;
  return 'assets/images/pets/${variants[index]}';
}

String petHomeAssetPath(String petType, int poseIndex) {
  final variants = petHomePoseVariantsForType(petType);
  if (variants.isEmpty) {
    return 'images/pets/dog_lie.png';
  }
  final index = poseIndex % variants.length;
  return 'images/pets/${variants[index]}';
}

String petDisplayName(String petType) =>
    _petTypeLabels[normalizePetType(petType)] ?? '\u5c0f\u5ba0\u7269';
