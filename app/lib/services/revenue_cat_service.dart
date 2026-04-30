import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/constants.dart';

class RevenueCatConfigurationException implements Exception {
  const RevenueCatConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RevenueCatUnavailableException implements Exception {
  const RevenueCatUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RevenueCatService {
  RevenueCatService({TargetPlatform? platform})
    : _platform = platform ?? defaultTargetPlatform;

  final TargetPlatform _platform;
  CustomerInfoUpdateListener? _customerInfoUpdateListener;

  String get entitlementId => RevenueCatConstants.entitlementId;

  bool get isSupportedPlatform =>
      _platform == TargetPlatform.iOS || _platform == TargetPlatform.android;

  String? get _publicSdkKey {
    final key = switch (_platform) {
      TargetPlatform.iOS => RevenueCatConstants.iosPublicSdkKey,
      TargetPlatform.android => RevenueCatConstants.androidPublicSdkKey,
      _ => '',
    };
    final trimmed = key.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool get hasPublicSdkKey => _publicSdkKey != null;

  Future<void> initialize({
    CustomerInfoUpdateListener? onCustomerInfoUpdated,
  }) async {
    if (!isSupportedPlatform) {
      throw const RevenueCatUnavailableException('订阅服务当前仅支持 iOS 和 Android。');
    }

    final publicSdkKey = _publicSdkKey;
    if (publicSdkKey == null) {
      throw const RevenueCatConfigurationException(
        '请通过 --dart-define 配置 RevenueCat public SDK key。',
      );
    }

    final isConfigured = await Purchases.isConfigured;
    if (!isConfigured) {
      await Purchases.configure(PurchasesConfiguration(publicSdkKey));
    }

    if (onCustomerInfoUpdated != null && _customerInfoUpdateListener == null) {
      _customerInfoUpdateListener = onCustomerInfoUpdated;
      Purchases.addCustomerInfoUpdateListener(onCustomerInfoUpdated);
    }
  }

  Future<Offerings> fetchOfferings() {
    return Purchases.getOfferings();
  }

  Future<CustomerInfo> fetchCustomerInfo() {
    return Purchases.getCustomerInfo();
  }

  Future<CustomerInfo> purchasePackage(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return result.customerInfo;
  }

  Future<CustomerInfo> restorePurchases() {
    return Purchases.restorePurchases();
  }

  bool hasActiveEntitlement(CustomerInfo? customerInfo) {
    return customerInfo?.entitlements.active.containsKey(entitlementId) ??
        false;
  }

  void dispose() {
    final listener = _customerInfoUpdateListener;
    if (listener == null) {
      return;
    }
    Purchases.removeCustomerInfoUpdateListener(listener);
    _customerInfoUpdateListener = null;
  }
}
