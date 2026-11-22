/// Environment separation for Alpha/Dev, Staging (Beta), and Production
/// (Stage P0 / Sprint 4: Beta Environment Isolation).
enum AppEnvironment {
  dev,
  staging,
  prod,
}

class AppEnvironmentConfig {
  static const String kBuildVersion = '5.0.0+20';
  static const String kRawEnvName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );

  final AppEnvironment environment;
  final String buildVersion;

  const AppEnvironmentConfig({
    required this.environment,
    this.buildVersion = kBuildVersion,
  });

  factory AppEnvironmentConfig.fromDartDefine([String? overrideEnv]) {
    final String raw = (overrideEnv ?? kRawEnvName).trim().toLowerCase();
    switch (raw) {
      case 'dev':
      case 'development':
      case 'alpha':
        return const AppEnvironmentConfig(environment: AppEnvironment.dev);
      case 'staging':
      case 'beta':
        return const AppEnvironmentConfig(environment: AppEnvironment.staging);
      case 'prod':
      case 'production':
      default:
        return const AppEnvironmentConfig(environment: AppEnvironment.prod);
    }
  }

  bool get isDev => environment == AppEnvironment.dev;
  bool get isStagingBeta => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.prod;

  /// Isolates local storage keys and cloud prefixes so Beta/Dev never mix with Production data.
  String get storageKeyPrefix {
    switch (environment) {
      case AppEnvironment.dev:
        return 'dev_';
      case AppEnvironment.staging:
        return 'staging_';
      case AppEnvironment.prod:
        return 'prod_';
    }
  }

  /// Prevents Beta/Dev builds from dispatching live notifications to Production users.
  bool get allowsProductionPushNotifications => isProduction;

  String get environmentBadgeLabel {
    switch (environment) {
      case AppEnvironment.dev:
        return 'Development (Alpha)';
      case AppEnvironment.staging:
        return 'Staging (Beta)';
      case AppEnvironment.prod:
        return 'Production';
    }
  }

  String get buildInfoSummary => '$buildVersion • $environmentBadgeLabel';
}
