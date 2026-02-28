import 'package:flutter/material.dart';

class SupplierCard extends StatelessWidget {
  const SupplierCard({
    super.key,
    required this.name,
    required this.location,
    required this.riskScore,
    this.logoUrl,
    this.onView,
    this.onRecommend,
  });

  final String name;
  final String location;
  final double riskScore;
  final String? logoUrl;
  final VoidCallback? onView;
  final VoidCallback? onRecommend;

  @override
  Widget build(BuildContext context) {
    final riskText = riskScore >= 80
        ? 'High'
        : riskScore >= 60
            ? 'Elevated'
            : 'Low';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
                  child: logoUrl == null ? const Icon(Icons.business) : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 10),
            Text('Location: $location'),
            Text('Risk: $riskText (${riskScore.toStringAsFixed(0)})'),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(onPressed: onView, child: const Text('View')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: onRecommend, child: const Text('Actions')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
