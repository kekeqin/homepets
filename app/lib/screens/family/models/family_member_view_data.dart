import '../../../models/pet.dart';

class FamilyMemberViewData {
  const FamilyMemberViewData({
    required this.id,
    required this.nickname,
    required this.role,
    this.avatarUrl,
    this.points = 0,
    this.petId,
    this.petType,
    this.petForm,
    this.pet,
    this.needsPetSelection = false,
  });

  factory FamilyMemberViewData.fromJson(Map<String, dynamic> json, {Pet? pet}) {
    final member = maybeFromJson(json, pet: pet);
    if (member == null) {
      throw const FormatException('Missing family member id');
    }
    return member;
  }

  static FamilyMemberViewData? maybeFromJson(
    Map<String, dynamic> json, {
    Pet? pet,
  }) {
    final id = _toInt(json['id']);
    if (id == null) {
      return null;
    }

    final nickname = (json['nickname'] ?? '').toString().trim();
    final role = (json['role'] ?? 'member').toString().trim();
    final petType = (json['pet_type'] ?? pet?.petType ?? '').toString().trim();
    final petForm = (json['pet_form'] ?? pet?.petForm ?? '').toString().trim();

    return FamilyMemberViewData(
      id: id,
      nickname: nickname.isEmpty ? '成员$id' : nickname,
      role: role.isEmpty ? 'member' : role,
      avatarUrl: json['avatar_url'] as String?,
      points: _toInt(json['points']) ?? 0,
      petId: _toInt(json['pet_id']) ?? pet?.id,
      petType: petType.isEmpty ? null : petType,
      petForm: petForm.isEmpty ? null : petForm,
      pet: pet,
      needsPetSelection: json['needs_pet_selection'] == true,
    );
  }

  static List<FamilyMemberViewData> listFromDynamic(
    dynamic data, {
    List<Pet> pets = const <Pet>[],
  }) {
    if (data is! List) {
      return const <FamilyMemberViewData>[];
    }

    final petsById = <int, Pet>{for (final pet in pets) pet.id: pet};
    final petsByOwner = <int, Pet>{for (final pet in pets) pet.ownerId: pet};
    final members = <FamilyMemberViewData>[];

    for (final item in data) {
      if (item is! Map) {
        continue;
      }

      final memberMap = Map<String, dynamic>.from(item);
      final petId = _toInt(memberMap['pet_id']);
      final ownerId = _toInt(memberMap['id']);
      final pet = petId != null
          ? petsById[petId]
          : (ownerId != null ? petsByOwner[ownerId] : null);
      final member = maybeFromJson(memberMap, pet: pet);
      if (member != null) {
        members.add(member);
      }
    }

    return members;
  }

  final int id;
  final String nickname;
  final String role;
  final String? avatarUrl;
  final int points;
  final int? petId;
  final String? petType;
  final String? petForm;
  final Pet? pet;
  final bool needsPetSelection;
}

class PortraitStyle {
  const PortraitStyle({
    required this.scale,
    required this.dx,
    required this.dy,
  });

  final double scale;
  final double dx;
  final double dy;
}

int? _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}
