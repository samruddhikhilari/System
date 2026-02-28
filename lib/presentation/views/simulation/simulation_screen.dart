import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../data/sources/remote/dio_provider.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  double _iterations = 1000;
  bool _running = false;
  Map<String, dynamic>? _result;

  Future<void> _runSimulation() async {
    setState(() => _running = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        ApiEndpoints.simulationRun,
        data: {
          'iterations': _iterations.toInt(),
          'disruption_type': 'supplier_failure',
          'region': 'west',
        },
      );
      setState(() {
        _result = response.data as Map<String, dynamic>;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Simulation failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cascade Simulation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Monte Carlo Iterations: ${_iterations.toInt()}'),
          Slider(
            value: _iterations,
            min: 100,
            max: 10000,
            divisions: 99,
            onChanged: (value) => setState(() => _iterations = value),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _running ? null : _runSimulation,
            child: _running
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Run Simulation'),
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            alignment: Alignment.center,
            child: const Text('Animated network cascade visualization'),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Suppliers Affected'),
              trailing: Text('${_result?['suppliers_affected'] ?? '-'}'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Revenue Impact (Cr)'),
              trailing: Text('${_result?['revenue_impact_cr'] ?? '-'}'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Duration (days)'),
              trailing: Text('${_result?['duration_days'] ?? '-'}'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Confidence'),
              trailing: Text('${_result?['confidence'] ?? '-'}'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _result == null
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Simulation result captured for reporting.')),
                    );
                  },
            icon: const Icon(Icons.download),
            label: const Text('Export Simulation Results'),
          ),
        ],
      ),
    );
  }
}
