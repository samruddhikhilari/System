import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../data/sources/remote/dio_provider.dart';

class ManagerConsoleScreen extends ConsumerStatefulWidget {
  const ManagerConsoleScreen({super.key});

  @override
  ConsumerState<ManagerConsoleScreen> createState() => _ManagerConsoleScreenState();
}

class _ManagerConsoleScreenState extends ConsumerState<ManagerConsoleScreen> {
  bool _loading = true;
  Map<String, dynamic> _queue = <String, dynamic>{};
  Map<String, dynamic> _sla = <String, dynamic>{};
  List<Map<String, dynamic>> _pendingApprovals = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadAll);
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio.get(ApiEndpoints.managerQueue),
        dio.get(ApiEndpoints.managerSla),
        dio.get(ApiEndpoints.managerApprovals),
      ]);
      setState(() {
        _queue = results[0].data as Map<String, dynamic>;
        _sla = results[1].data as Map<String, dynamic>;
        _pendingApprovals = (results[2].data['pending'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load manager console: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decideApproval(String id, bool approved) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        ApiEndpoints.managerApprovalDecision(id),
        data: {
          'approved': approved,
          'reason': approved ? null : 'Rejected from manager console',
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approved ? 'Mitigation approved.' : 'Mitigation rejected.')),
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Decision failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = (_queue['summary'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final queueItems = (_queue['queue'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Manager Console')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Queue Summary', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Active: ${summary['active'] ?? 0}')),
                      Chip(label: Text('Ack: ${summary['acknowledged'] ?? 0}')),
                      Chip(label: Text('Resolved: ${summary['resolved'] ?? 0}')),
                      Chip(label: Text('SLA Breaches: ${summary['sla_breaches'] ?? 0}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      title: const Text('MTTA / MTTR'),
                      subtitle: Text(
                        'MTTA: ${_sla['mtta_minutes'] ?? 0} min  •  '
                        'MTTR: ${_sla['mttr_minutes'] ?? 0} min',
                      ),
                      trailing: Text('SLA ${_sla['sla_compliance_percent'] ?? 0}%'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Team Queue', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...queueItems.take(8).map(
                    (item) => Card(
                      child: ListTile(
                        title: Text((item['title'] ?? '').toString()),
                        subtitle: Text(
                          'Severity: ${item['severity']} • Status: ${item['status']}\n'
                          'Owner: ${item['owner_email'] ?? 'unassigned'} • '
                          'Elapsed: ${item['elapsed_minutes']} min',
                        ),
                        trailing: item['sla_breached'] == true
                            ? const Icon(Icons.warning_amber_rounded, color: Colors.red)
                            : const Icon(Icons.check_circle_outline, color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Pending Approvals', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_pendingApprovals.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text('No pending approvals'),
                      ),
                    ),
                  ..._pendingApprovals.map(
                    (item) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (item['title'] ?? '').toString(),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text((item['description'] ?? '').toString()),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _decideApproval((item['id'] ?? '').toString(), false),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _decideApproval((item['id'] ?? '').toString(), true),
                                  child: const Text('Approve'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
