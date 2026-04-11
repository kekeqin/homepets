class Pet {
  final int id;
  final String name;
  final String petType;
  final String petForm;
  final int level;
  final int experience;
  final String? imageUrl;
  final int ownerId;
  final String? ownerNickname;
  final int familyId;
  final int? levelThreshold;
  final String? nextLevelImage;
  final String? emoji;

  Pet({
    required this.id,
    required this.name,
    required this.petType,
    required this.petForm,
    required this.level,
    required this.experience,
    this.imageUrl,
    required this.ownerId,
    this.ownerNickname,
    required this.familyId,
    this.levelThreshold,
    this.nextLevelImage,
    this.emoji,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as int,
      name: json['name'] as String,
      petType: json['pet_type'] as String,
      petForm: json['pet_form'] as String? ?? 'pet',
      level: json['level'] as int,
      experience: json['experience'] as int,
      imageUrl: json['image_url'] as String?,
      ownerId: json['owner_id'] as int,
      ownerNickname: json['owner_nickname'] as String?,
      familyId: json['family_id'] as int,
      levelThreshold: json['level_threshold'] as int?,
      nextLevelImage: json['next_level_image'] as String?,
      emoji: json['emoji'] as String?,
    );
  }

  bool get isEgg => petForm == 'egg';

  String get displayName {
    if (ownerNickname != null && ownerNickname!.isNotEmpty) {
      return '$ownerNickname的$name';
    }
    return name;
  }

  double get progress {
    if (levelThreshold == null || levelThreshold == 0) return 1.0;
    return (experience / levelThreshold!).clamp(0.0, 1.0);
  }

  String get levelName {
    const names = {0: '蛋蛋期', 1: '跑跑怪', 2: '捣蛋鬼', 3: '大魔王', 4: '大魔王', 5: '大魔王'};
    return names[level] ?? '大魔王';
  }

  String get displayEmoji {
    if (isEgg || level == 0) return '🥚';
    const petEmojis = {
      'cat': {1: '🐱', 2: '😺', 3: '😼', 4: '😸', 5: '🐱'},
      'dog': {1: '🐶', 2: '🐕', 3: '🦮', 4: '🐺', 5: '🐶'},
      'rabbit': {1: '🐰', 2: '🐇', 3: '🐹', 4: '🦔', 5: '🐰'},
      'bird': {1: '🐤', 2: '🐦', 3: '🦅', 4: '🦜', 5: '🐦'},
      'turtle': {1: '🐢', 2: '🐢', 3: '🦕', 4: '🐉', 5: '🐢'},
      'hamster': {1: '🐹', 2: '🐹', 3: '🐿️', 4: '🦡', 5: '🐹'},
      'fish': {1: '🐟', 2: '🐠', 3: '🐡', 4: '🦈', 5: '🐟'},
      'fox': {1: '🦊', 2: '🦊', 3: '🐺', 4: '🦁', 5: '🦊'},
      'panda': {1: '🐼', 2: '🐼', 3: '🐻', 4: '🐻‍❄️', 5: '🐼'},
      'dragon': {1: '🦎', 2: '🐍', 3: '🐲', 4: '🐉', 5: '🐉'},
    };
    return petEmojis[petType]?[level] ?? '🐾';
  }

  bool get hasCrown => level >= 5;
}
