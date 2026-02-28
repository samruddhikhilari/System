import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool isGenerating = false;
  String? lastReportId;

  Future<void> _generateReport() async {
    setState(() => isGenerating = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    setState(() {
      isGenerating = false;
      lastReportId = 'RPT-${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: isGenerating ? null : _generateReport,
            icon: const Icon(Icons.description_outlined),
            label: isGenerating
                ? const Text('Generating...')
                : const Text('Generate New Report'),
          ),
          const SizedBox(height: 16),
          if (lastReportId != null)
            Card(
              child: ListTile(
                title: Text('Latest report: $lastReportId'),
                subtitle: const Text('Status: Ready for export'),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export started')),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
