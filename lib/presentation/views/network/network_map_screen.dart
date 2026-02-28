import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../data/sources/remote/dio_provider.dart';

final networkGraphProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.networkGraph);
  return response.data as Map<String, dynamic>;
});

class NetworkMapScreen extends ConsumerWidget {
  const NetworkMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graphState = ref.watch(networkGraphProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Network Map')),
      body: graphState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed to load network graph: $error')),
        data: (graph) {
          final nodes = (graph['nodes'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
          final edges = (graph['edges'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.hub),
                  title: const Text('Network Topology'),
                  subtitle: Text('${nodes.length} nodes • ${edges.length} edges'),
                ),
              ),
              const SizedBox(height: 12),
              Text('Nodes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...nodes.map(
                (node) => Card(
                  child: ListTile(
                    title: Text((node['label'] ?? '').toString()),
                    subtitle: Text('Type: ${(node['type'] ?? '-').toString()}'),
                    trailing: Chip(
                      label: Text('Risk ${(node['risk'] ?? 0).toString()}'),
                    ),
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
