import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/supplier_model.dart';
import '../../../data/repositories/supplier_repository.dart';

final supplierDetailProvider =
    FutureProvider.family<SupplierModel, String>((ref, supplierId) async {
      final repository = ref.watch(supplierRepositoryProvider);
      return repository.getSupplierDetail(supplierId);
    });

final supplierDependenciesProvider =
    FutureProvider.family<List<SupplierDependency>, String>((ref, supplierId) async {
      final repository = ref.watch(supplierRepositoryProvider);
      return repository.getDependencies(supplierId);
    });

final supplierRecommendationsProvider =
    FutureProvider.family<List<SupplierRecommendation>, String>((ref, supplierId) async {
      final repository = ref.watch(supplierRepositoryProvider);
      return repository.getRecommendations(supplierId);
    });

class SupplierDetailScreen extends ConsumerWidget {
  final String supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplierState = ref.watch(supplierDetailProvider(supplierId));
    final dependenciesState = ref.watch(supplierDependenciesProvider(supplierId));
    final recommendationsState = ref.watch(
      supplierRecommendationsProvider(supplierId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Details')),
      body: supplierState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Failed: $error')),
        data: (supplier) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.business)),
              title: Text(supplier.name),
              subtitle: Text(supplier.location),
              trailing: Chip(label: Text('Risk ${supplier.riskScore.toStringAsFixed(0)}')),
            ),
            const SizedBox(height: 16),
            Text('Dependencies', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            dependenciesState.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Text('Dependencies unavailable: $error'),
              data: (dependencies) => Column(
                children: dependencies
                    .map(
                      (dependency) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Depends on ${dependency.dependentSupplierId}'),
                        trailing: Text('Weight ${dependency.weight.toStringAsFixed(2)}'),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Recommendations', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            recommendationsState.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Text('Recommendations unavailable: $error'),
              data: (recommendations) => Column(
                children: recommendations
                    .map(
                      (recommendation) => Card(
                        child: ListTile(
                          title: Text(recommendation.title),
                          subtitle: Text(recommendation.description),
                          trailing: Text(recommendation.priority.toUpperCase()),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
