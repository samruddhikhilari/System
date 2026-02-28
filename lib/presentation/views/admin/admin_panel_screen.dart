import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../data/sources/remote/dio_provider.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _logs = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _sources = <Map<String, dynamic>>[];
  Map<String, dynamic> _policy = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadAdminData);
  }

  Future<void> _loadAdminData() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final responses = await Future.wait([
        dio.get(ApiEndpoints.adminUsers),
        dio.get(ApiEndpoints.adminAuditLogs),
        dio.get(ApiEndpoints.adminIntegrationsHealth),
        dio.get(ApiEndpoints.adminCompliancePolicy),
      ]);

      setState(() {
        _users = (responses[0].data['users'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        _logs = (responses[1].data['logs'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        _sources =
            (responses[2].data['sources'] as List<dynamic>? ?? <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .toList(growable: false);
        _policy = responses[3].data as Map<String, dynamic>;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load admin data: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _updateRole(String userId, String role) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put(
        ApiEndpoints.adminUpdateUserRole(userId),
        data: {'role': role},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User role updated.')));
      await _loadAdminData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Role update failed: $error')));
    }
  }

  Future<void> _toggleMasking(bool value) async {
    final retention = (_policy['retention_days'] ?? 90) as int;
    try {
      final dio = ref.read(dioProvider);
      await dio.put(
        ApiEndpoints.adminCompliancePolicy,
        data: {'retention_days': retention, 'mask_sensitive_data': value},
      );
      await _loadAdminData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Policy update failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'User Management',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._users
                      .take(8)
                      .map(
                        (user) => Card(
                          child: ListTile(
                            title: Text((user['name'] ?? '').toString()),
                            subtitle: Text(
                              '${user['email']} • ${user['role']}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) => _updateRole(
                                (user['id'] ?? '').toString(),
                                value,
                              ),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'analyst',
                                  child: Text('Set Analyst'),
                                ),
                                PopupMenuItem(
                                  value: 'manager',
                                  child: Text('Set Manager'),
                                ),
                                PopupMenuItem(
                                  value: 'admin',
                                  child: Text('Set Admin'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                  Text(
                    'Compliance Policy',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Card(
                    child: SwitchListTile(
                      title: Text(
                        'Mask Sensitive Data (Retention ${_policy['retention_days'] ?? 90} days)',
                      ),
                      value: _policy['mask_sensitive_data'] == true,
                      onChanged: _toggleMasking,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Integrations Health',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ..._sources.map(
                    (source) => Card(
                      child: ListTile(
                        title: Text((source['name'] ?? '').toString()),
                        subtitle: Text(
                          'Last sync: ${source['last_sync_minutes']} min • Error rate: ${source['error_rate']}%',
                        ),
                        trailing: Text(
                          (source['status'] ?? '').toString(),
                          style: TextStyle(
                            color: (source['status'] == 'healthy')
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Audit Log',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ..._logs
                      .take(10)
                      .map(
                        (log) => Card(
                          child: ListTile(
                            dense: true,
                            title: Text(
                              '${log['action']} (${log['entity_type']})',
                            ),
                            subtitle: Text(
                              '${log['actor_email']} • ${log['details'] ?? '-'}',
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
