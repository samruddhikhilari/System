import 'dart:math';

import 'package:flutter/material.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  double _iterations = 1000;
  bool _running = false;
  int? _suppliersAffected;
  double? _revenueImpact;
  int? _durationDays;

  Future<void> _runSimulation() async {
    setState(() => _running = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final random = Random();
    setState(() {
      _suppliersAffected = 18 + random.nextInt(40);
      _revenueImpact = 4.5 + random.nextDouble() * 21;
      _durationDays = 5 + random.nextInt(30);
      _running = false;
    });
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
              trailing: Text('${_suppliersAffected ?? '-'}'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Revenue Impact (Cr)'),
              trailing: Text(_revenueImpact?.toStringAsFixed(1) ?? '-'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Duration (days)'),
              trailing: Text('${_durationDays ?? '-'}'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download),
            label: const Text('Export Simulation Results'),
          ),
        ],
      ),
    );
  }
}
