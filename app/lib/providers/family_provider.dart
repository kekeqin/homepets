import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/family/models/family_member_view_data.dart';
import '../screens/family/models/family_screen_state.dart';
import '../services/family_service.dart';
import 'auth_provider.dart';

final familyServiceProvider = Provider<FamilyService>((ref) {
  return FamilyService(ref.read(apiClientProvider));
});

final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyScreenState>(
  (ref) => FamilyNotifier(ref, ref.read(familyServiceProvider)),
);

class FamilyNotifier extends StateNotifier<FamilyScreenState> {
  FamilyNotifier(this._ref, this._familyService)
    : super(const FamilyScreenState());

  final Ref _ref;
  final FamilyService _familyService;

  Future<void> loadFamily() async {
    final familyId = _ref.read(authProvider).user?.familyId;
    if (familyId == null) {
      state = state.copyWith(
        loading: false,
        hasFamily: false,
        familyName: '家庭',
        members: const <FamilyMemberViewData>[],
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(loading: true, hasFamily: true, errorMessage: null);

    try {
      final result = await _familyService.fetchFamily(familyId);
      final members = FamilyMemberViewData.listFromDynamic(result.memberMaps)
        ..sort((a, b) => a.id.compareTo(b.id));

      state = state.copyWith(
        loading: false,
        hasFamily: true,
        familyName: result.familyName,
        members: members,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadFamily();
  }

  Future<FamilyMemberViewData> addMember(String nickname) async {
    final familyId = _requireFamilyId();
    final memberMap = await _familyService.addMember(
      familyId: familyId,
      nickname: nickname,
    );
    return FamilyMemberViewData.fromJson(memberMap);
  }

  Future<void> assignMemberPet({
    required int memberId,
    required String petType,
  }) async {
    await _familyService.assignMemberPet(
      familyId: _requireFamilyId(),
      memberId: memberId,
      petType: petType,
    );
  }

  int _requireFamilyId() {
    final familyId = _ref.read(authProvider).user?.familyId;
    if (familyId == null) {
      throw StateError('当前用户还未加入家庭');
    }
    return familyId;
  }
}
