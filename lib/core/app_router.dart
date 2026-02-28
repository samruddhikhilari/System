import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants/app_constants.dart';
import '../presentation/views/splash/splash_screen.dart';
import '../presentation/views/onboarding/onboarding_screen.dart';
import '../presentation/views/login/login_screen.dart';
import '../presentation/views/register/register_screen.dart';
import '../presentation/views/dashboard/dashboard_screen.dart';
import '../presentation/views/prediction/prediction_screen.dart';
import '../presentation/views/simulation/simulation_screen.dart';
import '../presentation/views/recommendations/recommendations_screen.dart';
import '../presentation/views/network/network_map_screen.dart';
import '../presentation/views/supplier/supplier_detail_screen.dart';
import '../presentation/views/risk/risk_intelligence_screen.dart';
import '../presentation/views/alerts/alert_center_screen.dart';
import '../presentation/views/reports/reports_screen.dart';
import '../presentation/views/settings/settings_screen.dart';
import '../presentation/views/profile/profile_screen.dart';
import '../presentation/views/admin/admin_panel_screen.dart';
import '../presentation/views/manager/manager_console_screen.dart';

/// Router configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding/:step',
        name: 'onboarding',
        builder: (context, state) {
          final step = int.tryParse(state.pathParameters['step'] ?? '1') ?? 1;
          return OnboardingScreen(step: step);
        },
      ),

      // Login
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Register
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Dashboard (Auth Required)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Network Map (Auth Required)
      GoRoute(
        path: '/network-map',
        name: 'network-map',
        builder: (context, state) => const NetworkMapScreen(),
      ),

      // Supplier Detail (Auth Required)
      GoRoute(
        path: '/supplier/:id',
        name: 'supplier',
        builder: (context, state) {
          final supplierId = state.pathParameters['id'] ?? '';
          return SupplierDetailScreen(supplierId: supplierId);
        },
      ),

      // Risk Intelligence (Auth Required)
      GoRoute(
        path: '/risk-intelligence',
        name: 'risk-intelligence',
        builder: (context, state) => const RiskIntelligenceScreen(),
      ),

      // Prediction (Auth Required)
      GoRoute(
        path: '/prediction',
        name: 'prediction',
        builder: (context, state) => const PredictionScreen(),
      ),

      // Simulation (Auth Required)
      GoRoute(
        path: '/simulation',
        name: 'simulation',
        builder: (context, state) => const SimulationScreen(),
      ),

      // Recommendations (Auth Required)
      GoRoute(
        path: '/recommendations',
        name: 'recommendations',
        builder: (context, state) => const RecommendationsScreen(),
      ),

      // Route Optimization (Auth Required)
      GoRoute(
        path: '/route-optimization',
        name: 'route-optimization',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Route Optimization'))),
      ),

      // Vulnerability Scanner (Auth Required)
      GoRoute(
        path: '/vulnerability-scanner',
        name: 'vulnerability-scanner',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Vulnerability Scanner'))),
      ),

      // Alerts (Auth Required)
      GoRoute(
        path: '/alerts',
        name: 'alerts',
        builder: (context, state) => const AlertCenterScreen(),
      ),

      // Reports (Auth Required)
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),

      // Settings (Auth Required)
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Admin (Admin Role Required)
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminPanelScreen(),
      ),

      // Manager Console (Manager/Admin Role Required)
      GoRoute(
        path: '/manager',
        name: 'manager',
        builder: (context, state) => const ManagerConsoleScreen(),
      ),

      // Profile (Auth Required)
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],

    // Redirect logic
    redirect: (context, state) async {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.keyAccessToken);
      final role = await storage.read(key: AppConstants.keyUserRole);
      final isAuthed = token != null && token.isNotEmpty;

      const publicRoutes = {'/splash', '/login', '/register'};
      final isPublic = publicRoutes.contains(state.matchedLocation) ||
          state.matchedLocation.startsWith('/onboarding');

      if (!isAuthed && !isPublic) {
        return '/login';
      }
      if (isAuthed &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register' ||
              state.matchedLocation == '/splash')) {
        return '/dashboard';
      }

      if (state.matchedLocation == '/admin' && role != 'admin') {
        return '/dashboard';
      }

      if (state.matchedLocation == '/manager' && role != 'manager' && role != 'admin') {
        return '/dashboard';
      }

      return null;
    },

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
          ],
        ),
      ),
    ),
  );
});
