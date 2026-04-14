import '../core/api_client.dart';
import '../models/pet.dart';
import '../screens/member/models/member_profile_view_data.dart';

class MemberProfileService {
  MemberProfileService(this._apiClient);

  final ApiClient _apiClient;

  Future<MemberProfileViewData> loadProfile({
    required int familyId,
    required int memberId,
  }) async {
    final results = await Future.wait<dynamic>([
      _apiClient.dio.get('/api/families/$familyId/members'),
      _apiClient.dio.get('/api/families/$familyId/pets'),
      _apiClient.dio.get('/api/families/$familyId/completions'),
    ]);

    final members = _extractList(results[0].data);
    final currentMember = members.firstWhere(
      (member) => member['id'] == memberId,
      orElse: () => <String, dynamic>{'points': 0},
    );

    final pets =
        _extractList(
            results[1].data,
          ).map(Pet.fromJson).where((pet) => pet.ownerId == memberId).toList()
          ..sort((a, b) => b.experience.compareTo(a.experience));

    final completions =
        _extractList(results[2].data)
            .where((completion) => completion['member_id'] == memberId)
            .map(MemberTaskCompletion.fromJson)
            .toList()
          ..sort((a, b) {
            final timeA = a.createdAt;
            final timeB = b.createdAt;
            if (timeA == null && timeB == null) {
              return 0;
            }
            if (timeA == null) {
              return 1;
            }
            if (timeB == null) {
              return -1;
            }
            return timeB.compareTo(timeA);
          });

    return MemberProfileViewData(
      memberPoints: currentMember['points'] as int? ?? 0,
      avatarUrl: currentMember['avatar_url']?.toString(),
      pets: pets,
      completions: completions,
    );
  }

  Future<void> deleteMember({
    required int familyId,
    required int memberId,
  }) async {
    await _apiClient.dio.delete('/api/families/$familyId/members/$memberId');
  }

  Future<void> updateAvatar({
    required int memberId,
    required String? avatarUrl,
  }) async {
    await _apiClient.dio.put(
      '/api/users/$memberId',
      data: {'avatar_url': avatarUrl},
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic payload) {
    if (payload is! List) {
      return const <Map<String, dynamic>>[];
    }
    return payload
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
