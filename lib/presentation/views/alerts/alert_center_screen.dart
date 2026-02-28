import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/dashboard_model.dart';
import '../../../data/repositories/alert_repository.dart';
import '../../widgets/cards/alert_card.dart';

final alertsProvider = FutureProvider<List<AlertSummary>>((ref) async {
  final repository = ref.watch(alertRepositoryProvider);
  return repository.getAlerts();
});

class AlertCenterScreen extends ConsumerWidget {
  const AlertCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alert Center')),
      body: alertsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load alerts: $error')),
        data: (alerts) => ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];

            return AlertCard(
              title: alert.title,
              timestampLabel: alert.timestamp.toLocal().toString(),
              severity: alert.severity,
              onAcknowledge: () {
                ref.read(alertRepositoryProvider).acknowledgeAlert(alert.id);
              },
              onSnooze: () {
                ref.read(alertRepositoryProvider).snoozeAlert(
                  alert.id,
                  const Duration(minutes: 30),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
