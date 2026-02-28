import 'package:flutter/material.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.title,
    required this.timestampLabel,
    required this.severity,
    this.onAcknowledge,
    this.onSnooze,
  });

  final String title;
  final String timestampLabel;
  final String severity;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onSnooze;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity.toLowerCase()) {
      'critical' => Colors.red,
      'high' => Colors.orange,
      'medium' => Colors.amber,
      _ => Colors.blue,
    };

    return Card(
      child: ListTile(
        leading: Container(width: 4, height: 48, color: color),
        title: Text(title),
        subtitle: Text(timestampLabel),
        trailing: Wrap(
          spacing: 6,
          children: [
            ActionChip(label: const Text('Ack'), onPressed: onAcknowledge),
            ActionChip(label: const Text('Snooze'), onPressed: onSnooze),
          ],
        ),
      ),
    );
  }
}
