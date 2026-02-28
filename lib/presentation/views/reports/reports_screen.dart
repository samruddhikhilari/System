import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../data/sources/remote/dio_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _loading = true;
  bool _generating = false;
  String _period = 'weekly';
  String _format = 'csv';
  List<Map<String, dynamic>> _reports = <Map<String, dynamic>>[];
  int _reportsPage = 1;
  static const int _reportsPageSize = 10;
  bool _hasNextReportsPage = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadReports);
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        ApiEndpoints.reports,
        queryParameters: {
          'page': _reportsPage,
          'page_size': _reportsPageSize,
        },
      );
      setState(() {
        _reports = (response.data['reports'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        final pagination =
            response.data['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};
        _hasNextReportsPage = pagination['has_next'] == true;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reports: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _generateReport() async {
    setState(() => _generating = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        ApiEndpoints.reportsGenerate,
        data: {
          'period': _period,
          'output_format': _format,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report generated.')));
      _reportsPage = 1;
      await _loadReports();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  Future<void> _downloadReport(String id) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiEndpoints.reportDownload(id));
      final fileName = (response.data['file_name'] ?? 'report').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report ready: $fileName')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate KPI Report',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _period,
                                  decoration: const InputDecoration(
                                    labelText: 'Period',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'weekly',
                                      child: Text('Weekly'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'monthly',
                                      child: Text('Monthly'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _period = value);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _format,
                                  decoration: const InputDecoration(
                                    labelText: 'Format',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'csv',
                                      child: Text('CSV'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'pdf',
                                      child: Text('PDF'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _format = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _generating ? null : _generateReport,
                            icon: const Icon(Icons.description_outlined),
                            label: _generating
                                ? const Text('Generating...')
                                : const Text('Generate Report'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Recent Reports', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Page $_reportsPage'),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _reportsPage > 1
                            ? () {
                                setState(() => _reportsPage -= 1);
                                _loadReports();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        onPressed: _hasNextReportsPage
                            ? () {
                                setState(() => _reportsPage += 1);
                                _loadReports();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  if (_reports.isEmpty)
                    const Card(
                      child: ListTile(title: Text('No reports generated yet.')),
                    ),
                  ..._reports.map(
                    (report) => Card(
                      child: ListTile(
                        title: Text(
                          'KPI ${((report['period'] ?? '').toString()).toUpperCase()} • ${((report['output_format'] ?? '').toString()).toUpperCase()}',
                        ),
                        subtitle: Text(
                          'Status: ${report['status']} • By: ${report['generated_by']}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _downloadReport((report['id'] ?? '').toString()),
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
