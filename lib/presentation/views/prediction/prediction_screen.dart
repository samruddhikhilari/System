import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  String _window = '1m';

  @override
  Widget build(BuildContext context) {
    final lineData = _buildLineData();

    return Scaffold(
      appBar: AppBar(title: const Text('Prediction')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('1 week'),
                selected: _window == '1w',
                onSelected: (_) => setState(() => _window = '1w'),
              ),
              ChoiceChip(
                label: const Text('1 month'),
                selected: _window == '1m',
                onSelected: (_) => setState(() => _window = '1m'),
              ),
              ChoiceChip(
                label: const Text('3 months'),
                selected: _window == '3m',
                onSelected: (_) => setState(() => _window = '3m'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(lineData),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              title: Text('Economic Impact'),
              subtitle: Text('Estimated downside: ₹12.4 Cr (P95), ₹7.8 Cr (P80)'),
            ),
          ),
          const Card(
            child: ListTile(
              title: Text('Backtesting'),
              subtitle: Text('MAE: 4.1, RMSE: 6.7, Coverage(95%): 93.2%'),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineData() {
    final base = [20.0, 28.0, 34.0, 41.0, 38.0, 52.0, 49.0];
    final p80Upper = base.map((v) => v + 7).toList(growable: false);
    final p80Lower = base.map((v) => v - 7).toList(growable: false);
    final p95Upper = base.map((v) => v + 12).toList(growable: false);
    final p95Lower = base.map((v) => v - 12).toList(growable: false);

    LineChartBarData band(List<double> upper, List<double> lower, Color color) {
      return LineChartBarData(
        spots: [
          ...upper.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value)),
          ...lower.asMap().entries.toList().reversed.map(
                (entry) => FlSpot(entry.key.toDouble(), entry.value),
              ),
        ],
        isCurved: true,
        barWidth: 0,
        color: Colors.transparent,
        belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.3)),
      );
    }

    return LineChartData(
      gridData: const FlGridData(show: true),
      lineBarsData: [
        band(p95Upper, p95Lower, Colors.blueGrey),
        band(p80Upper, p80Lower, Colors.lightBlue),
        LineChartBarData(
          spots: base.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value)).toList(),
          isCurved: true,
          barWidth: 3,
          color: Colors.blue,
          dotData: const FlDotData(show: false),
        ),
      ],
      titlesData: const FlTitlesData(show: true),
    );
  }
}
