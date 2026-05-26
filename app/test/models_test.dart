import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/models/pet_artwork.dart';
import 'package:homepets/models/subscription_status.dart';
import 'package:homepets/models/user.dart';
import 'package:homepets/providers/auth_provider.dart';
import 'package:homepets/providers/subscription_provider.dart';

void main() {
  test('User model parses JSON correctly', () {
    final user = User.fromJson({
      'id': 1,
      'phone': '13800000001',
      'nickname': '爸爸',
      'role': 'admin',
      'avatar_url': null,
      'family_id': 1,
    });

    expect(user.id, 1);
    expect(user.phone, '13800000001');
    expect(user.nickname, '爸爸');
    expect(user.role, 'admin');
    expect(user.isAdmin, true);
    expect(user.familyId, 1);
  });

  test('User model child role', () {
    final user = User.fromJson({
      'id': 2,
      'phone': null,
      'nickname': '小明',
      'role': 'child',
      'avatar_url': null,
      'family_id': 1,
    });

    expect(user.isAdmin, false);
    expect(user.phone, isNull);
  });

  test('SubscriptionStatus parses backend entitlement response', () {
    final status = SubscriptionStatus.fromJson({
      'status': 'trial_expiring',
      'access_allowed': true,
      'paywall_required': false,
      'reason': null,
      'scope': 'family',
      'family_id': 12,
      'trial_started_at': '2026-05-16T00:00:00Z',
      'trial_ends_at': '2026-05-23T00:00:00Z',
      'trial_days_remaining': 2,
      'is_premium_active': false,
      'entitlement_id': 'premium',
      'product_id': null,
      'subscription_expires_at': null,
      'will_renew': false,
      'last_verified_at': '2026-05-16T00:00:00Z',
      'revenuecat_app_user_id': 'family_12',
    });

    expect(status.isTrialActive, true);
    expect(status.isTrialExpiring, true);
    expect(status.blocksCoreAccess, false);
    expect(status.trialDaysRemaining, 2);
    expect(status.revenueCatAppUserId, 'family_12');
  });

  test('SubscriptionStatus marks expired trial as blocking', () {
    final status = SubscriptionStatus.fromJson({
      'status': 'trial_expired_unsubscribed',
      'access_allowed': false,
      'paywall_required': true,
      'reason': 'trial_expired',
      'scope': 'family',
      'trial_days_remaining': 0,
      'is_premium_active': false,
      'entitlement_id': 'premium',
      'will_renew': false,
      'revenuecat_app_user_id': 'family_12',
    });

    expect(status.blocksCoreAccess, true);
    expect(status.reason, 'trial_expired');
  });

  test('home guide is blocked in entitlement read-only mode', () {
    expect(homeGuideBlockedByEntitlement(const AuthState()), isFalse);

    expect(
      homeGuideBlockedByEntitlement(const AuthState(viewOnly: true)),
      isTrue,
    );
  });

  test('Pet artwork maps levels to growth stage asset paths', () {
    expect(petGrowthStageForLevel(1), PetGrowthStage.baby);
    expect(petGrowthStageForLevel(2), PetGrowthStage.growing);
    expect(petGrowthStageForLevel(3), PetGrowthStage.growing);
    expect(petGrowthStageForLevel(4), PetGrowthStage.companion);
    expect(petGrowthStageForLevel(5), PetGrowthStage.companion);

    expect(
      petGrowthAvatarAssetPath('dog', 1, 0),
      'assets/images/pets/grow/dog/baby/lying.png',
    );
    expect(
      petGrowthAvatarAssetPath('dog', 2, 0),
      'assets/images/pets/grow/dog/growing/lying.png',
    );
    expect(
      petGrowthAvatarAssetPath('dog', 5, 0),
      'assets/images/pets/grow/dog/companion/lying.png',
    );
  });
}
