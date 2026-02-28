import 'package:flutter/material.dart';

class SectorRiskCard extends StatelessWidget {
  const SectorRiskCard({
    super.key,
    required this.sector,
    required this.riskScore,
  });

  final String sector;
  final double riskScore;

  @override
  Widget build(BuildContext context) {
    final color = riskScore <= 30
        ? Colors.green
        : riskScore <= 60
            ? Colors.amber
            : riskScore <= 80
                ? Colors.orange
                : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                riskScore.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Text(sector),
          ],
        ),
      ),
    );
  }
}
