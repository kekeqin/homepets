import 'family_member_view_data.dart';

class FamilyScreenState {
  const FamilyScreenState({
    this.loading = true,
    this.hasFamily = false,
    this.familyName = '家庭',
    this.members = const <FamilyMemberViewData>[],
    this.errorMessage,
  });

  static const _unset = Object();

  final bool loading;
  final bool hasFamily;
  final String familyName;
  final List<FamilyMemberViewData> members;
  final String? errorMessage;

  FamilyScreenState copyWith({
    bool? loading,
    bool? hasFamily,
    String? familyName,
    List<FamilyMemberViewData>? members,
    Object? errorMessage = _unset,
  }) {
    return FamilyScreenState(
      loading: loading ?? this.loading,
      hasFamily: hasFamily ?? this.hasFamily,
      familyName: familyName ?? this.familyName,
      members: members ?? this.members,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
