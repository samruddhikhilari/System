import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/dashboard_model.dart';
import '../../../data/repositories/alert_repository.dart';
import '../../widgets/cards/alert_card.dart';

final alertsProvider = FutureProvider<List<AlertSummary>>((ref) async {
  final repository = ref.watch(alertRepositoryProvider);
  return repository.getAlerts();
});

class AlertCenterScreen extends ConsumerStatefulWidget {
  const AlertCenterScreen({super.key});

  @override
  ConsumerState<AlertCenterScreen> createState() => _AlertCenterScreenState();
}

class _AlertCenterScreenState extends ConsumerState<AlertCenterScreen> {
  final Set<String> _inFlightAlertIds = <String>{};

  Future<void> _handleAcknowledge(AlertSummary alert) async {
    if (_inFlightAlertIds.contains(alert.id)) return;

    setState(() => _inFlightAlertIds.add(alert.id));
    try {
      await ref.read(alertRepositoryProvider).acknowledgeAlert(alert.id);
      ref.invalidate(alertsProvider);
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
      ref.invalidate(alertsProvider);
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
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alert Center')),
      body: alertsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load alerts: $error')),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(child: Text('No active alerts.'));
          }

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final isBusy = _inFlightAlertIds.contains(alert.id);

              return Opacity(
                opacity: isBusy ? 0.6 : 1,
                child: AlertCard(
                  title: alert.title,
                  timestampLabel: alert.timestamp.toLocal().toString(),
                  severity: alert.severity,
                  onAcknowledge: isBusy ? null : () => _handleAcknowledge(alert),
                  onSnooze: isBusy ? null : () => _handleSnooze(alert),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
