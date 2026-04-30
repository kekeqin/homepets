class ApiConstants {
  // Real device: http://192.168.1.3:8000  |  Emulator: http://10.0.2.2:8000
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String tokenKey = 'access_token';
  static const String onboardingKey = 'onboarding_done';
}

class RevenueCatConstants {
  static const String testStorePublicSdkKey =
      'test_NFtgmTDZrduESWajnYMSIvXsQeR';
  static const String _iosPublicSdkKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );
  static const String _androidPublicSdkKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const String entitlementId = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT_ID',
    defaultValue: 'premium',
  );

  static const bool _useTestStoreKey = bool.fromEnvironment(
    'REVENUECAT_USE_TEST_STORE',
    defaultValue: !bool.fromEnvironment('dart.vm.product'),
  );

  static String get iosPublicSdkKey => _publicSdkKeyFor(_iosPublicSdkKey);

  static String get androidPublicSdkKey =>
      _publicSdkKeyFor(_androidPublicSdkKey);

  static String _publicSdkKeyFor(String configuredKey) {
    final trimmed = configuredKey.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return _useTestStoreKey ? testStorePublicSdkKey : '';
  }
}
