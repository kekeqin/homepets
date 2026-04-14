import '../core/api_client.dart';
import '../screens/pet/models/pet_history_entry.dart';

class PetDetailService {
  PetDetailService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PetHistoryEntry>> loadHistory(int petId) async {
    try {
      final response = await _apiClient.dio.get('/api/pets/$petId/history');
      return _parseHistory(response.data);
    } catch (_) {
      return const <PetHistoryEntry>[];
    }
  }

  List<PetHistoryEntry> _parseHistory(dynamic payload) {
    if (payload is! List) {
      return const <PetHistoryEntry>[];
    }

    return payload
        .whereType<Map>()
        .map(
          (item) => PetHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
