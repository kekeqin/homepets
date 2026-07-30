class ApiConstants {
  static const bool isProductionBuild = bool.fromEnvironment('dart.vm.product');
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _developmentBaseUrl = 'http://10.0.2.2:8000';
  static const String productionBaseUrl = 'https://pickstarpet.kkqin.com';

  /// 推广阶段：隐藏首页「7 天免费体验」提示条。
  /// 推广结束后改为 `false` 即可恢复显示。
  static const bool hideHomeFreeTrialBanner = true;

  static String get baseUrl => resolveBaseUrl(
    isProductionBuild: isProductionBuild,
    configuredBaseUrl: _configuredBaseUrl,
  );

  static String resolveBaseUrl({
    required bool isProductionBuild,
    required String configuredBaseUrl,
  }) {
    final trimmedConfiguredBaseUrl = configuredBaseUrl.trim();
    if (trimmedConfiguredBaseUrl.isNotEmpty) {
      return trimmedConfiguredBaseUrl;
    }
    return isProductionBuild ? productionBaseUrl : _developmentBaseUrl;
  }

  static const String tokenKey = 'access_token';
}

class RevenueCatConstants {
  static const String testStorePublicSdkKey =
      'test_NFtgmTDZrduESWajnYMSIvXsQeR';
  static const String productionIosPublicSdkKey =
      'appl_uyBVQtCCjYuTiMMjfzAHKHZGcoD';
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

  static String get iosPublicSdkKey => _publicSdkKeyFor(
    _iosPublicSdkKey,
    productionDefaultKey: productionIosPublicSdkKey,
  );

  static String get androidPublicSdkKey =>
      _publicSdkKeyFor(_androidPublicSdkKey);

  static String _publicSdkKeyFor(
    String configuredKey, {
    String productionDefaultKey = '',
  }) {
    final trimmed = configuredKey.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return _useTestStoreKey ? testStorePublicSdkKey : productionDefaultKey;
  }
}
