class ApiConstants {
  // Real device: http://192.168.1.3:8000  |  Emulator: http://10.0.2.2:8000
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String tokenKey = 'access_token';
  static const String onboardingKey = 'onboarding_done';
}

class RevenueCatConstants {
  static const String testStorePublicSdkKey =
      'test_NFtgmTDZrduESWajnYMSIvXsQeR';
  static const String iosPublicSdkKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: testStorePublicSdkKey,
  );
  static const String androidPublicSdkKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: testStorePublicSdkKey,
  );
  static const String entitlementId = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT_ID',
    defaultValue: 'premium',
  );
}
