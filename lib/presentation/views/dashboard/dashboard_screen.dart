import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/dashboard_model.dart';
import '../../../data/repositories/alert_repository.dart';
import '../../viewmodels/dashboard/dashboard_viewmodel.dart';
import '../../widgets/charts/nri_gauge.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/cards/sector_risk_card.dart';
import '../../widgets/cards/alert_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final Set<String> _inFlightAlertIds = <String>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardViewModelProvider.notifier).load();
      ref.read(dashboardViewModelProvider.notifier).startAutoRefresh();
    });
  }

  @override
  void dispose() {
    ref.read(dashboardViewModelProvider.notifier).stopAutoRefresh();
    super.dispose();
  }

  Future<void> _handleAcknowledge(AlertSummary alert) async {
    if (_inFlightAlertIds.contains(alert.id)) return;

    setState(() => _inFlightAlertIds.add(alert.id));
    try {
      await ref.read(alertRepositoryProvider).acknowledgeAlert(alert.id);
      await ref.read(dashboardViewModelProvider.notifier).load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert acknowledged.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to acknowledge alert: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _inFlightAlertIds.remove(alert.id));
      }
    }
  }

  Future<void> _handleSnooze(AlertSummary alert) async {
    if (_inFlightAlertIds.contains(alert.id)) return;

    setState(() => _inFlightAlertIds.add(alert.id));
    try {
      await ref.read(alertRepositoryProvider).snoozeAlert(
            alert.id,
            const Duration(minutes: 30),
          );
      await ref.read(dashboardViewModelProvider.notifier).load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert snoozed for 30 minutes.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to snooze alert: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _inFlightAlertIds.remove(alert.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider);
    final summary = state.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supply Chain Command Center'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.push('/alerts'),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        child: RefreshIndicator(
          onRefresh: () => ref.read(dashboardViewModelProvider.notifier).load(),
          child: ListView(
            children: [
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (summary != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'National Risk Index',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: NriGauge(
                              value: summary.nriScore,
                              delta: summary.nriDelta,
                              updatedAt: summary.lastUpdated,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Sector-Wise Risk Overview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 130,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: summary.sectors
                        .map(
                          (sector) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SectorRiskCard(
                              sector: sector.sector,
                              riskScore: sector.riskScore,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Live Alerts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...summary.activeAlerts.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Opacity(
                      opacity: _inFlightAlertIds.contains(alert.id) ? 0.6 : 1,
                      child: AlertCard(
                        title: alert.title,
                        timestampLabel: alert.timestamp.toLocal().toString(),
                        severity: alert.severity,
                        onAcknowledge: _inFlightAlertIds.contains(alert.id)
                            ? null
                            : () => _handleAcknowledge(alert),
                        onSnooze: _inFlightAlertIds.contains(alert.id)
                            ? null
                            : () => _handleSnooze(alert),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(child: Icon(Icons.person)),
                  SizedBox(height: 8),
                  Text('John Doe', style: TextStyle(color: Colors.white)),
                  Text(
                    'john@company.com',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Network Map'),
              onTap: () => context.push('/network-map'),
            ),
            ListTile(
              title: const Text('Risk Intelligence'),
              onTap: () => context.push('/risk-intelligence'),
            ),
            ListTile(
              title: const Text('Alerts'),
              onTap: () => context.push('/alerts'),
            ),
            ListTile(
              title: const Text('Reports'),
              onTap: () => context.push('/reports'),
            ),
            ListTile(
              title: const Text('Manager Console'),
              onTap: () => context.push('/manager'),
            ),
            ListTile(
              title: const Text('Admin Panel'),
              onTap: () => context.push('/admin'),
            ),
            const Divider(),
            ListTile(
              title: const Text('Settings'),
              onTap: () => context.push('/settings'),
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () => context.push('/profile'),
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
