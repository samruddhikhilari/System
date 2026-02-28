import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../data/repositories/alert_repository.dart';
import '../../../data/sources/remote/dio_provider.dart';
import '../../../services/websocket_service.dart';

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
  StreamSubscription<Map<String, dynamic>>? _eventsSubscription;
  bool _liveRefreshInProgress = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadAll();
      await ref.read(alertRepositoryProvider).initializeRealtime();
      _eventsSubscription =
          ref.read(webSocketServiceProvider).alertsStream.listen(_handleLiveEvent);
    });
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAll({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _loading = true);
    }
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
      if (mounted && showLoader) {
        setState(() => _loading = false);
      }
    }
  }

  void _handleLiveEvent(Map<String, dynamic> event) {
    final eventName = (event['event'] ?? '').toString();
    if (eventName != 'sla_breach' &&
        eventName != 'alert_assigned' &&
        eventName != 'approval_submitted' &&
        eventName != 'approval_decided' &&
        eventName != 'mitigation_applied') {
      return;
    }

    if (!mounted) {
      return;
    }

    final payload = event['data'] is Map<String, dynamic>
        ? event['data'] as Map<String, dynamic>
        : (event['alert'] is Map<String, dynamic>
              ? event['alert'] as Map<String, dynamic>
              : <String, dynamic>{});

    if (eventName == 'sla_breach') {
      final title = (payload['title'] ?? 'Alert').toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('SLA breach detected: $title')));
    } else if (eventName == 'approval_submitted') {
      final title = (payload['title'] ?? 'Mitigation').toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('New approval request: $title')));
    } else if (eventName == 'approval_decided') {
      final status = (payload['status'] ?? '').toString();
      final title = (payload['title'] ?? 'Mitigation').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval updated: $title ($status)')),
      );
    }

    unawaited(_refreshFromLive());
  }

  Future<void> _refreshFromLive() async {
    if (!mounted || _liveRefreshInProgress) {
      return;
    }
    _liveRefreshInProgress = true;
    try {
      await _loadAll(showLoader: false);
    } finally {
      _liveRefreshInProgress = false;
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
