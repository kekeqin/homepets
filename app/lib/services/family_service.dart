import '../core/api_client.dart';

class FamilyLoadResult {
  const FamilyLoadResult({required this.familyName, required this.memberMaps});

  final String familyName;
  final List<Map<String, dynamic>> memberMaps;
}

class FamilyService {
  FamilyService(this._apiClient);

  final ApiClient _apiClient;

  Future<FamilyLoadResult> fetchFamily(int familyId) async {
    final responses = await Future.wait<dynamic>([
      _apiClient.dio.get('/api/families/$familyId'),
      _apiClient.dio.get('/api/families/$familyId/members'),
    ]);

    return FamilyLoadResult(
      familyName: _extractFamilyName(responses[0].data),
      memberMaps: _extractMemberMaps(responses[1].data),
    );
  }

  Future<Map<String, dynamic>> addMember({
    required int familyId,
    required String nickname,
  }) async {
    final response = await _apiClient.dio.post(
      '/api/families/$familyId/members',
      data: {'nickname': nickname},
    );
    return _extractMap(response.data, fallbackMessage: '成员信息返回异常');
  }

  Future<void> assignMemberPet({
    required int familyId,
    required int memberId,
    required String petType,
  }) async {
    await _apiClient.dio.put(
      '/api/families/$familyId/members/$memberId/pet',
      data: {'pet_type': petType},
    );
  }

  String _extractFamilyName(dynamic payload) {
    if (payload is Map && payload['name'] is String) {
      final name = (payload['name'] as String).trim();
      if (name.isNotEmpty) {
        return name;
      }
    }
    return '家庭';
  }

  List<Map<String, dynamic>> _extractMemberMaps(dynamic payload) {
    if (payload is! List) {
      return const <Map<String, dynamic>>[];
    }

    final members = <Map<String, dynamic>>[];
    for (final item in payload) {
      if (item is Map) {
        members.add(Map<String, dynamic>.from(item));
      }
    }
    return members;
  }

  Map<String, dynamic> _extractMap(
    dynamic payload, {
    required String fallbackMessage,
  }) {
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw StateError(fallbackMessage);
  }
}
