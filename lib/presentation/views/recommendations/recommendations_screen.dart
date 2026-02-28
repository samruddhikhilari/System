import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../data/sources/remote/dio_provider.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  bool _loading = true;
  final Set<String> _inFlight = <String>{};
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadRecommendations);
  }

  Future<void> _loadRecommendations() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiEndpoints.recommendationsOptimize);
      final list =
          (response.data['recommendations'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
      setState(() => _items = list);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load recommendations: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _applyMitigation(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString();
    if (id.isEmpty || _inFlight.contains(id)) return;

    setState(() => _inFlight.add(id));
    try {
      final dio = ref.read(dioProvider);
      await dio.post(ApiEndpoints.mitigationApply(id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mitigation applied successfully.')),
      );
      await _loadRecommendations();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot apply mitigation: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _inFlight.remove(id));
      }
    }
  }

  List<Map<String, dynamic>> _byCategory(String category) {
    return _items
        .where((item) => (item['category'] ?? '').toString() == category)
        .toList(growable: false);
  }

  Widget _buildCategoryList(List<Map<String, dynamic>> items) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const Center(child: Text('No recommendations available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final id = (item['id'] ?? '').toString();
          final status = (item['status'] ?? 'proposed').toString();
          final requiresApproval = item['requires_approval'] == true;
          final isBusy = _inFlight.contains(id);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item['title'] ?? '').toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text((item['description'] ?? '').toString()),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          'Risk -${item['estimated_risk_reduction'] ?? 0}%',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Cost +${item['cost_impact_percent'] ?? 0}%',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Service +${item['service_impact_percent'] ?? 0}%',
                        ),
                      ),
                      Chip(label: Text('Status: $status')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: (status == 'applied' || isBusy)
                          ? null
                          : () => _applyMitigation(item),
                      icon: const Icon(Icons.playlist_add_check),
                      label: Text(
                        requiresApproval && status == 'proposed'
                            ? 'Apply (Needs Approval)'
                            : status == 'applied'
                            ? 'Applied'
                            : 'Apply Mitigation',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recommendations'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Alternatives'),
              Tab(text: 'Route Optimization'),
              Tab(text: 'Safety Stock'),
              Tab(text: 'Diversification'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCategoryList(_byCategory('alternative_supplier')),
            _buildCategoryList(_byCategory('route_optimization')),
            _buildCategoryList(_byCategory('safety_stock')),
            _buildCategoryList(_byCategory('diversification')),
          ],
        ),
      ),
    );
  }
}
