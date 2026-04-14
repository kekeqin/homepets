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
    this.needsPetSelection = false,
  });

  factory FamilyMemberViewData.fromJson(Map<String, dynamic> json) {
    final member = maybeFromJson(json);
    if (member == null) {
      throw const FormatException('Missing family member id');
    }
    return member;
  }

  static FamilyMemberViewData? maybeFromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id']);
    if (id == null) {
      return null;
    }

    final nickname = (json['nickname'] ?? '').toString().trim();
    final role = (json['role'] ?? 'member').toString().trim();
    final petType = (json['pet_type'] ?? '').toString().trim();
    final petForm = (json['pet_form'] ?? '').toString().trim();

    return FamilyMemberViewData(
      id: id,
      nickname: nickname.isEmpty ? '成员$id' : nickname,
      role: role.isEmpty ? 'member' : role,
      avatarUrl: json['avatar_url'] as String?,
      points: _toInt(json['points']) ?? 0,
      petId: _toInt(json['pet_id']),
      petType: petType.isEmpty ? null : petType,
      petForm: petForm.isEmpty ? null : petForm,
      needsPetSelection: json['needs_pet_selection'] == true,
    );
  }

  static List<FamilyMemberViewData> listFromDynamic(dynamic data) {
    if (data is! List) {
      return const <FamilyMemberViewData>[];
    }

    final members = <FamilyMemberViewData>[];
    for (final item in data) {
      if (item is! Map) {
        continue;
      }
      final member = maybeFromJson(Map<String, dynamic>.from(item));
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
