import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/alert_repository.dart';
import '../../../data/repositories/auth_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool criticalAlerts = true;
  bool highPriority = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      criticalAlerts = prefs.getBool('settings_critical_alerts') ?? true;
      highPriority = prefs.getBool('settings_high_priority') ?? true;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_critical_alerts', criticalAlerts);
    await prefs.setBool('settings_high_priority', highPriority);
    await ref.read(alertRepositoryProvider).updatePreferences({
      'critical_alerts': criticalAlerts,
      'high_priority': highPriority,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Account',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Profile'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {},
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Notifications',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Critical Alerts'),
            value: criticalAlerts,
            onChanged: (value) {
              setState(() => criticalAlerts = value);
              _savePrefs();
            },
          ),
          SwitchListTile(
            title: const Text('High Priority'),
            value: highPriority,
            onChanged: (value) {
              setState(() => highPriority = value);
              _savePrefs();
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Display',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('System Default'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {},
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await ref.read(authRepositoryProvider).logout();
                if (mounted) {
                  context.go('/login');
                }
              },
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
