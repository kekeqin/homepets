import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickstarpet/core/api_client.dart';
import 'package:pickstarpet/core/auth_session_bus.dart';
import 'package:pickstarpet/models/user.dart';
import 'package:pickstarpet/providers/auth_provider.dart';
import 'package:pickstarpet/providers/family_provider.dart' as family_provider;
import 'package:pickstarpet/providers/subscription_provider.dart';
import 'package:pickstarpet/services/apple_sign_in_service.dart';
import 'package:pickstarpet/services/auth_service.dart';
import 'package:pickstarpet/services/family_service.dart';

void main() {
  test('addMemberWithPet keeps pet returned by one-step member API', () async {
    final service = _FakeFamilyService(
      memberResponse: const <String, dynamic>{
        'id': 2,
        'nickname': '小宝',
        'role': 'child',
        'points': 0,
        'pet_id': 10,
        'pet_type': 'dog',
        'needs_pet_selection': false,
      },
      familyResult: _familyResult(
        members: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 2,
            'nickname': '小宝',
            'role': 'child',
            'points': 0,
            'pet_id': 10,
            'pet_type': 'dog',
            'needs_pet_selection': false,
          },
        ],
        pets: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 10,
            'name': '团团',
            'pet_type': 'dog',
            'level': 1,
            'experience': 0,
            'owner_id': 2,
            'family_id': 99,
            'created_at': '2026-05-18T00:00:00Z',
            'level_threshold': 100,
          },
        ],
      ),
    );
    final notifier = _notifier(service);

    final member = await notifier.addMemberWithPet(
      nickname: '小宝',
      petType: 'dog',
      petName: '团团',
    );

    expect(service.addMemberCalls, 1);
    expect(service.assignMemberPetCalls, 0);
    expect(member.petType, 'dog');
    expect(member.pet?.name, '团团');
    expect(notifier.state.members.single.pet?.name, '团团');
  });

  test('addMemberWithPet falls back to assigning pet for split API', () async {
    final service = _FakeFamilyService(
      memberResponse: const <String, dynamic>{
        'id': 2,
        'nickname': '小宝',
        'role': 'child',
        'points': 0,
        'pet_id': null,
        'pet_type': null,
        'needs_pet_selection': true,
      },
      familyResult: _familyResult(
        members: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 2,
            'nickname': '小宝',
            'role': 'child',
            'points': 0,
            'pet_id': 10,
            'pet_type': 'rabbit',
            'needs_pet_selection': false,
          },
        ],
        pets: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 10,
            'name': '团团',
            'pet_type': 'rabbit',
            'level': 1,
            'experience': 0,
            'owner_id': 2,
            'family_id': 99,
            'created_at': '2026-05-18T00:00:00Z',
            'level_threshold': 100,
          },
        ],
      ),
    );
    final notifier = _notifier(service);

    final member = await notifier.addMemberWithPet(
      nickname: '小宝',
      petType: 'rabbit',
      petName: '团团',
    );

    expect(service.addMemberCalls, 1);
    expect(service.assignMemberPetCalls, 1);
    expect(service.assignedMemberId, 2);
    expect(member.petType, 'rabbit');
    expect(member.pet?.name, '团团');
  });

  test(
    'assignMemberPet refreshes family and binds pet to existing owner',
    () async {
      final service = _FakeFamilyService(
        memberResponse: const <String, dynamic>{
          'id': 2,
          'nickname': '小宝',
          'role': 'child',
          'points': 0,
          'pet_id': null,
          'pet_type': null,
          'needs_pet_selection': true,
        },
        familyResult: _familyResult(
          members: const <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'nickname': '家长',
              'role': 'admin',
              'points': 0,
              'pet_id': 20,
              'pet_type': 'cat',
              'needs_pet_selection': false,
            },
          ],
          pets: const <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 20,
              'name': '米米',
              'pet_type': 'cat',
              'level': 1,
              'experience': 0,
              'owner_id': 1,
              'family_id': 99,
              'created_at': '2026-05-18T00:00:00Z',
              'level_threshold': 100,
            },
          ],
        ),
      );
      final notifier = _notifier(service);

      await notifier.assignMemberPet(
        memberId: 1,
        petType: 'cat',
        petName: '团团',
      );

      expect(service.assignMemberPetCalls, 1);
      expect(service.assignedMemberId, 1);
      expect(notifier.state.members.single.petType, 'cat');
      expect(notifier.state.members.single.pet?.name, '米米');
    },
  );

  test('write operations are blocked when trial requires membership', () async {
    final service = _FakeFamilyService(
      memberResponse: const <String, dynamic>{
        'id': 2,
        'nickname': '小宝',
        'role': 'child',
        'points': 0,
        'pet_id': null,
        'pet_type': null,
        'needs_pet_selection': true,
      },
      familyResult: _familyResult(
        members: const <Map<String, dynamic>>[],
        pets: const <Map<String, dynamic>>[],
      ),
    );
    final notifier = _notifier(service, subscriptionAllowed: false);

    await expectLater(
      notifier.addMemberWithPet(nickname: '小宝', petType: 'cat', petName: '团团'),
      throwsA(isA<StateError>()),
    );
    expect(service.addMemberCalls, 0);
    expect(service.assignMemberPetCalls, 0);
  });
}

family_provider.FamilyNotifier _notifier(
  _FakeFamilyService service, {
  bool subscriptionAllowed = true,
}) {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(
        (_) => _FakeAuthNotifier(
          AuthState(
            isAuthenticated: true,
            isInitialized: true,
            user: User(
              id: 1,
              phone: '13800000001',
              nickname: '家长',
              role: 'admin',
              familyId: 99,
            ),
          ),
        ),
      ),
      family_provider.familyServiceProvider.overrideWithValue(service),
      coreMutationBlockedProvider.overrideWithValue(!subscriptionAllowed),
    ],
  );
  addTearDown(container.dispose);
  return container.read(family_provider.familyProvider.notifier);
}

FamilyLoadResult _familyResult({
  required List<Map<String, dynamic>> members,
  required List<Map<String, dynamic>> pets,
}) {
  return FamilyLoadResult(
    familyName: 'JJJHA',
    memberMaps: members,
    petMaps: pets,
  );
}

class _FakeFamilyService extends FamilyService {
  _FakeFamilyService({required this.memberResponse, required this.familyResult})
    : super(_FakeApiClient());

  final Map<String, dynamic> memberResponse;
  final FamilyLoadResult familyResult;
  int addMemberCalls = 0;
  int assignMemberPetCalls = 0;
  int? assignedMemberId;

  @override
  Future<FamilyLoadResult> fetchFamily(int familyId) async {
    return familyResult;
  }

  @override
  Future<Map<String, dynamic>> addMember({
    required int familyId,
    required String nickname,
    String? petType,
    String? petName,
  }) async {
    addMemberCalls += 1;
    expect(familyId, 99);
    expect(nickname, '小宝');
    expect(petType, isNotNull);
    expect(petName, '团团');
    return memberResponse;
  }

  @override
  Future<void> assignMemberPet({
    required int familyId,
    required int memberId,
    required String petType,
    required String petName,
  }) async {
    assignMemberPetCalls += 1;
    assignedMemberId = memberId;
    expect(familyId, 99);
    expect(petName, '团团');
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(AuthState initialState)
    : super(_FakeAuthService(), _FakeAppleSignInService(), AuthSessionBus()) {
    state = initialState;
  }
}

class _FakeAppleSignInService extends AppleSignInService {}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(_FakeApiClient());

  static final _user = User(
    id: 1,
    phone: '13800000001',
    nickname: '家长',
    role: 'admin',
    familyId: 99,
  );

  @override
  Future<String?> getSavedToken() async => 'token';

  @override
  Future<User> getMe() async => _user;
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(AuthSessionBus());
}
