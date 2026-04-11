class User {
  final int id;
  final String? phone;
  final String nickname;
  final String role;
  final String? avatarUrl;
  final int points;
  final int? familyId;

  User({
    required this.id,
    this.phone,
    required this.nickname,
    required this.role,
    this.avatarUrl,
    this.points = 0,
    this.familyId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      phone: json['phone'] as String?,
      nickname: json['nickname'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      points: json['points'] as int? ?? 0,
      familyId: json['family_id'] as int?,
    );
  }

  bool get isAdmin => role == 'admin';
}
