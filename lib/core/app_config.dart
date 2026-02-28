/// Application configuration for different environments
class AppConfig {
  final String baseUrl;
  final String apiVersion;
  final String environment;
  final bool enableLogging;
  final bool enableAnalytics;
  final bool enableCrashlytics;
  final bool enableRealtime;

  const AppConfig({
    required this.baseUrl,
    required this.apiVersion,
    required this.environment,
    required this.enableLogging,
    this.enableAnalytics = true,
    this.enableCrashlytics = true,
    this.enableRealtime = true,
  });

  /// Development configuration
  static const dev = AppConfig(
    baseUrl: 'http://localhost:8000',
    apiVersion: 'v1',
    environment: 'development',
    enableLogging: true,
    enableAnalytics: true,
    enableCrashlytics: false,
    enableRealtime: false,
  );

  /// Staging configuration
  static const staging = AppConfig(
    baseUrl: 'https://staging-api.ncsrra.com',
    apiVersion: 'v1',
    environment: 'staging',
    enableLogging: true,
    enableAnalytics: true,
    enableCrashlytics: true,
    enableRealtime: true,
  );

  /// Production configuration
  static const production = AppConfig(
    baseUrl: 'https://api.ncsrra.com',
    apiVersion: 'v1',
    environment: 'production',
    enableLogging: false,
    enableAnalytics: true,
    enableCrashlytics: true,
    enableRealtime: true,
  );

  /// Get current environment config
  static AppConfig get current {
    const overrideBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    const enableRealtime = bool.fromEnvironment('ENABLE_REALTIME', defaultValue: false);
    if (overrideBaseUrl.isNotEmpty) {
      return AppConfig(
        baseUrl: overrideBaseUrl,
        apiVersion: '',
        environment: 'custom',
        enableLogging: true,
        enableAnalytics: true,
        enableCrashlytics: false,
        enableRealtime: enableRealtime,
      );
    }

    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'staging':
        return AppConfig(
          baseUrl: staging.baseUrl,
          apiVersion: staging.apiVersion,
          environment: staging.environment,
          enableLogging: staging.enableLogging,
          enableAnalytics: staging.enableAnalytics,
          enableCrashlytics: staging.enableCrashlytics,
          enableRealtime: enableRealtime,
        );
      case 'production':
        return AppConfig(
          baseUrl: production.baseUrl,
          apiVersion: production.apiVersion,
          environment: production.environment,
          enableLogging: production.enableLogging,
          enableAnalytics: production.enableAnalytics,
          enableCrashlytics: production.enableCrashlytics,
          enableRealtime: enableRealtime,
        );
      default:
        return AppConfig(
          baseUrl: dev.baseUrl,
          apiVersion: dev.apiVersion,
          environment: dev.environment,
          enableLogging: dev.enableLogging,
          enableAnalytics: dev.enableAnalytics,
          enableCrashlytics: dev.enableCrashlytics,
          enableRealtime: enableRealtime,
        );
    }
  }

  // Constants for this config
  Duration get connectTimeout => const Duration(seconds: 30);
  Duration get receiveTimeout => const Duration(seconds: 30);
  Duration get dashboardCacheDuration => const Duration(minutes: 1);
  Duration get supplierCacheDuration => const Duration(hours: 1);
  Duration get alertsCacheDuration => const Duration(minutes: 5);
  int get defaultPageSize => 20;
  int get maxPageSize => 100;

  String get fullBaseUrl {
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    if (apiVersion.isEmpty) {
      return normalizedBase;
    }

    if (normalizedBase.endsWith('/api/$apiVersion') ||
        normalizedBase.endsWith('/$apiVersion')) {
      return normalizedBase;
    }

    if (normalizedBase.endsWith('/api') || normalizedBase.contains('/api/')) {
      return '$normalizedBase/$apiVersion';
    }

    return '$normalizedBase/api/$apiVersion';
  }
}
