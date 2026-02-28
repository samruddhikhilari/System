/// API endpoint constants
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
    static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String organizations = '/auth/organizations';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary';
  static const String liveAlerts = '/alerts/live';
  static const String heatmapTiles = '/heatmap/tiles';

  // Network
  static const String networkGraph = '/network/graph';
  static const String networkNode = '/network/node';
  static const String networkSpof = '/network/spof';

  // Suppliers
  static const String suppliers = '/suppliers';
  static String supplierById(String id) => '/suppliers/$id';
  static String supplierRiskHistory(String id) => '/suppliers/$id/risk-history';
  static String supplierDependencies(String id) =>
      '/suppliers/$id/dependencies';
  static String supplierFinancial(String id) => '/suppliers/$id/financial';
  static String supplierRecommendations(String id) =>
      '/suppliers/$id/recommendations';

  // Risk
  static const String riskBreakdown = '/risk/breakdown';
  static const String riskSignals = '/risk/signals';
  static const String riskSectorComparison = '/risk/sector-comparison';
  static const String riskScenarios = '/risk/scenarios';

  // Prediction
  static String predictionSupplier(String id) => '/prediction/supplier/$id';
  static String predictionSector(String name) => '/prediction/sector/$name';
  static String predictionProductionImpact(String id) =>
      '/prediction/production-impact/$id';
  static const String predictionCompareScenarios =
      '/prediction/compare-scenarios';

  // Simulation
  static const String simulationRun = '/simulation/run';
  static String simulationReport(String id) => '/simulation/$id/report';
  static const String simulationHistory = '/simulation/history';

  // Recommendations
  static String recommendationAlternatives(String id) =>
      '/recommendations/alternatives/$id';
  static const String recommendationOptimize = '/recommendations/optimize';
  static String recommendationSafetyStock(String id) =>
      '/recommendations/safety-stock/$id';
  static String recommendationDiversification(String id) =>
      '/recommendations/diversification/$id';

  // Routes
  static const String routeOptimize = '/routes/optimize';
  static const String routeRiskOverlay = '/routes/risk-overlay';
  static String routePortCongestion(String portId) =>
      '/routes/ports/$portId/congestion';

  // Vulnerability
  static const String vulnerabilityNationalFragility =
      '/vulnerability/national-fragility';
  static const String vulnerabilityCriticalNodes =
      '/vulnerability/critical-nodes';
  static const String vulnerabilitySingleSourceComponents =
      '/vulnerability/single-source-components';
  static const String vulnerabilitySectorFragility =
      '/vulnerability/sector-fragility';
  static const String vulnerabilityPolicyRecommendations =
      '/vulnerability/policy-recommendations';

  // Alerts
  static const String alerts = '/alerts';
  static String alertById(String id) => '/alerts/$id';
  static String alertAcknowledge(String id) => '/alerts/$id/acknowledge';
  static String alertSnooze(String id) => '/alerts/$id/snooze';
  static const String alertPreferences = '/alerts/preferences';

  // Reports
  static const String reportsGenerate = '/reports/generate';
  static String reportStatus(String id) => '/reports/$id/status';
  static String reportDownload(String id) => '/reports/$id/download';
  static const String reports = '/reports';
  static const String reportsSchedule = '/reports/schedule';

  // WebSocket
  static const String wsAlerts = '/ws/alerts';
}
