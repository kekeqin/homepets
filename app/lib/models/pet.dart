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

  String get displayName {
    if (ownerNickname != null && ownerNickname!.isNotEmpty) {
      return '$ownerNickname的$name';
    }
    return name;
  }

  double get progress {
    if (levelThreshold == null || levelThreshold == 0) {
      return 1.0;
    }
    return (experience / levelThreshold!).clamp(0.0, 1.0);
  }

  String get levelName {
    const names = {1: '成长初期', 2: '活力成长', 3: '稳定进阶', 4: '闪耀阶段', 5: '满级伙伴'};
    return names[level] ?? '成长伙伴';
  }

  String get displayEmoji {
    const petEmojis = {
      'cat': {
        1: '\u{1F431}',
        2: '\u{1F63A}',
        3: '\u{1F638}',
        4: '\u{1F63B}',
        5: '\u{1F431}',
      },
      'dog': {
        1: '\u{1F436}',
        2: '\u{1F415}',
        3: '\u{1F9AE}',
        4: '\u{1F415}\u200D\u{1F9BA}',
        5: '\u{1F436}',
      },
      'rabbit': {
        1: '\u{1F430}',
        2: '\u{1F407}',
        3: '\u{1F955}',
        4: '\u2728',
        5: '\u{1F430}',
      },
      'bird': {
        1: '\u{1F426}',
        2: '\u{1F54A}\uFE0F',
        3: '\u{1FAB6}',
        4: '\u2728',
        5: '\u{1F426}',
      },
      'turtle': {
        1: '\u{1F422}',
        2: '\u{1F422}',
        3: '\u{1F30A}',
        4: '\u2728',
        5: '\u{1F422}',
      },
      'hamster': {
        1: '\u{1F439}',
        2: '\u{1F439}',
        3: '\u{1F330}',
        4: '\u2728',
        5: '\u{1F439}',
      },
      'fish': {
        1: '\u{1F41F}',
        2: '\u{1F420}',
        3: '\u{1F421}',
        4: '\u2728',
        5: '\u{1F41F}',
      },
      'fox': {
        1: '\u{1F98A}',
        2: '\u{1F98A}',
        3: '\u2728',
        4: '\u2728',
        5: '\u{1F98A}',
      },
      'panda': {
        1: '\u{1F43C}',
        2: '\u{1F43C}',
        3: '\u2728',
        4: '\u2728',
        5: '\u{1F43C}',
      },
      'dragon': {
        1: '\u{1F432}',
        2: '\u{1F409}',
        3: '\u2728',
        4: '\u2728',
        5: '\u{1F409}',
      },
    };
    return petEmojis[petType]?[level] ?? '\u{1F43E}';
  }

  bool get hasCrown => level >= 5;
}
