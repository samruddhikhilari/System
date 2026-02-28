/// Application-wide constants
class AppConstants {
  AppConstants._();
  
  // App Info
  static const String appName = 'N-SCRRA';
  static const String appFullName = 'National Supply Chain Risk & Resilience Analyzer';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyOrgId = 'org_id';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keySelectedOrg = 'selected_org';
  
  // API Headers
  static const String headerAuthorization = 'Authorization';
  static const String headerOrgId = 'X-Org-ID';
  static const String headerDeviceId = 'X-Device-ID';
  static const String headerContentType = 'Content-Type';
  
  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds
  
  // Token
  static const int tokenExpiry = 900; // 15 minutes in seconds
  static const int refreshTokenExpiry = 604800; // 7 days in seconds
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int defaultInitialPage = 1;
  
  // Refresh Intervals
  static const int dashboardRefreshInterval = 60; // seconds
  static const int alertRefreshInterval = 30; // seconds
  
  // Risk Thresholds
  static const int riskLow = 30;
  static const int riskMedium = 60;
  static const int riskHigh = 80;
  static const int riskCritical = 100;
  
  // Alert Severity
  static const String severityCritical = 'critical';
  static const String severityHigh = 'high';
  static const String severityMedium = 'medium';
  static const String severityLow = 'low';
  static const String severityInfo = 'info';
  
  // Login
  static const int maxLoginAttempts = 5;
  static const int loginLockoutDuration = 900; // 15 minutes in seconds
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;
  
  // Chart
  static const int defaultChartAnimationDuration = 1200; // milliseconds
  
  // Map
  static const double defaultMapZoom = 5.0;
  static const double minMapZoom = 4.0;
  static const double maxMapZoom = 15.0;
  
  // Network Graph
  static const int maxGraphNodes = 10000;
  static const double minZoomForLabels = 0.4;
  static const double minZoomForEdges = 0.2;
  
  // Simulation
  static const int monteCarloIterations = 1000;
  static const int maxSimulationDuration = 90; // days
}
