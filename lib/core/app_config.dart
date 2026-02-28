/// Application configuration for different environments
class AppConfig {
  final String baseUrl;
  final String apiVersion;
  final String environment;
  final bool enableLogging;
  final bool enableAnalytics;
  final bool enableCrashlytics;

  const AppConfig({
    required this.baseUrl,
    required this.apiVersion,
    required this.environment,
    required this.enableLogging,
    this.enableAnalytics = true,
    this.enableCrashlytics = true,
  });

  /// Development configuration
  static const dev = AppConfig(
    baseUrl: 'http://localhost:8000',
    apiVersion: 'v1',
    environment: 'development',
    enableLogging: true,
    enableAnalytics: true,
    enableCrashlytics: false,
  );

  /// Staging configuration
  static const staging = AppConfig(
    baseUrl: 'https://staging-api.ncsrra.com',
    apiVersion: 'v1',
    environment: 'staging',
    enableLogging: true,
    enableAnalytics: true,
    enableCrashlytics: true,
  );

  /// Production configuration
  static const production = AppConfig(
    baseUrl: 'https://api.ncsrra.com',
    apiVersion: 'v1',
    environment: 'production',
    enableLogging: false,
    enableAnalytics: true,
    enableCrashlytics: true,
  );

  /// Get current environment config
  static AppConfig get current {
    const overrideBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (overrideBaseUrl.isNotEmpty) {
      return AppConfig(
        baseUrl: overrideBaseUrl,
        apiVersion: '',
        environment: 'custom',
        enableLogging: true,
        enableAnalytics: true,
        enableCrashlytics: false,
      );
    }

    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'staging':
        return staging;
      case 'production':
        return production;
      default:
        return dev;
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
