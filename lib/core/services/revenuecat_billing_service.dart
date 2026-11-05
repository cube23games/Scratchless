import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import '../config/app_build_config.dart';

typedef PremiumEntitlementListener = void Function(bool isPremium);

class RevenueCatBillingService {
  RevenueCatBillingService._();

  static final RevenueCatBillingService instance =
      RevenueCatBillingService._();

  static const String premiumEntitlementId = 'premium';

  PremiumEntitlementListener? _listener;
  bool _configured = false;
  bool _initializing = false;

  bool get isConfigured => _configured;

  Future<void> initialize({
    required PremiumEntitlementListener onPremiumChanged,
  }) async {
    _listener = onPremiumChanged;

    if (!AppBuildConfig.revenueCatEnabled) {
      return;
    }

    if (_configured) {
      await refreshEntitlement();
      return;
    }

    if (_initializing) {
      return;
    }

    _initializing = true;
    final stopwatch = Stopwatch()..start();

    try {
      rc.Purchases.logLevel = rc.LogLevel.warn;

      final configuration = rc.PurchasesConfiguration(
        AppBuildConfig.revenueCatAndroidPublicSdkKey,
      )
        ..entitlementVerificationMode =
            rc.EntitlementVerificationMode.informational;

      await rc.Purchases.configure(configuration);

      _configured = true;

      rc.Purchases.addCustomerInfoUpdateListener(
        _handleCustomerInfo,
      );
    } catch (error) {
      debugPrint(
        'RevenueCat configuration unavailable; '
        'ScratchLess remains Free: $error',
      );
      return;
    } finally {
      stopwatch.stop();
      _initializing = false;

      debugPrint(
        'RevenueCat foundation initialization: '
        '${stopwatch.elapsedMilliseconds}ms',
      );
    }

    await refreshEntitlement();
  }

  Future<void> refreshEntitlement() async {
    if (!_configured) {
      return;
    }

    try {
      final customerInfo =
          await rc.Purchases.getCustomerInfo().timeout(
        const Duration(seconds: 4),
      );

      _handleCustomerInfo(customerInfo);
    } catch (error) {
      debugPrint(
        'RevenueCat entitlement refresh unavailable; '
        'keeping current access: $error',
      );
    }
  }

  void _handleCustomerInfo(rc.CustomerInfo customerInfo) {
    final entitlement =
        customerInfo.entitlements.all[premiumEntitlementId];

    final responseVerified =
        customerInfo.entitlements.verification ==
            rc.VerificationResult.verified;

    final trustedPremium =
        responseVerified &&
        entitlement != null &&
        entitlement.isActive;

    _listener?.call(trustedPremium);
  }
}
