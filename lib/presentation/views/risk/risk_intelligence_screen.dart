import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../data/sources/remote/dio_provider.dart';

final riskBreakdownProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.riskBreakdown);
  return response.data as Map<String, dynamic>;
});

class RiskIntelligenceScreen extends ConsumerWidget {
  const RiskIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskState = ref.watch(riskBreakdownProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Intelligence')),
      body: riskState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load risk data: $error')),
        data: (riskData) {
          final factors = (riskData['factors'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
          final signals = (riskData['signals'] as List<dynamic>? ?? <dynamic>[])
              .map((item) => item.toString())
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('Overall Risk Score'),
                  trailing: Text('${riskData['overall_score'] ?? 0}'),
                ),
              ),
              const SizedBox(height: 12),
              Text('Factor Breakdown', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...factors.map(
                (factor) => Card(
                  child: ListTile(
                    title: Text((factor['name'] ?? '').toString()),
                    subtitle: Text('Score: ${factor['score']}'),
                    trailing: Text('Δ ${factor['delta']}'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Signals', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...signals.map(
                (signal) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.bolt_outlined),
                    title: Text(signal),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
