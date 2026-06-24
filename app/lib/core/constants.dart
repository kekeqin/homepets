class ApiConstants {
  static const bool isProductionBuild = bool.fromEnvironment('dart.vm.product');
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _developmentBaseUrl = 'http://10.0.2.2:8000';
  static const String productionBaseUrl = 'https://pickstarpet.kkqin.com';

  static String get baseUrl {
    final configuredBaseUrl = _configuredBaseUrl.trim();
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }
    return isProductionBuild ? productionBaseUrl : _developmentBaseUrl;
  }

  static const String tokenKey = 'access_token';
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
