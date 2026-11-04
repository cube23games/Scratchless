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
}
