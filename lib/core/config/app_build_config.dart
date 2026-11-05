class AppBuildConfig {
  AppBuildConfig._();

  static const String buildName = String.fromEnvironment(
    'SCRATCHLESS_BUILD',
    defaultValue: 'store',
  );

  static const bool qaToolsEnabled = buildName == 'qa';
  static const bool storeBuild = !qaToolsEnabled;
  static const bool localPremiumTrialEnabled = qaToolsEnabled;
  static const bool deferredPlaceSearchVisible = qaToolsEnabled;
  static const bool internalDiagnosticsVisible = qaToolsEnabled;

  static const String revenueCatAndroidPublicSdkKey =
      String.fromEnvironment(
    'REVENUECAT_ANDROID_PUBLIC_SDK_KEY',
    defaultValue: '',
  );

  static bool get revenueCatAndroidKeyLooksProduction {
    return revenueCatAndroidPublicSdkKey.startsWith('goog_');
  }

  static bool get revenueCatEnabled {
    return storeBuild && revenueCatAndroidKeyLooksProduction;
  }
}
