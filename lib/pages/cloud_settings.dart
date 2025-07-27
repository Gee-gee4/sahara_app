// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/modules/resource_service.dart';
import 'package:sahara_app/pages/users_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahara_app/helpers/sync_helper.dart'; // Import your sync helper

class CloudSettings extends StatefulWidget {
  const CloudSettings({super.key});

  @override
  State<CloudSettings> createState() => _CloudSettingsState();
}

class _CloudSettingsState extends State<CloudSettings> {
  final TextEditingController _urlController = TextEditingController();
  bool isSyncing = false;
  

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUrl = prefs.getString('webApiServiceUrl') ?? '';
    _urlController.text = currentUrl;
  }

  Future<void> _handleCloudSync() async {
    final fullUrl = _urlController.text.trim();

    if (!fullUrl.contains('.saharafcs.com')) {
      _showError('Invalid URL');
      return;
    }

    final uri = Uri.parse(fullUrl);
    final host = uri.host;
    final resourceName = host.split('.').first;

    setState(() => isSyncing = true);

    final resourceSynced = await ResourceService.fetchAndSaveConfig(resourceName);

    if (!mounted) return;

    if (resourceSynced) {
      try {
        final deviceId = await getSavedOrFetchDeviceId();
        print('📱 Device ID used for sync: $deviceId');

        await fullResourceSync(deviceId: deviceId, context: context);

        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UsersPage()));
      } catch (e) {
        _showError('Failed to sync all resources.\n${e.toString()}');
      }
    } else {
      _showError('Failed to fetch configuration for "$resourceName"');
    }

    setState(() => isSyncing = false);
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar('Cloud Settings'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'API URL',
                labelStyle: TextStyle(color: ColorsUniversal.buttonsColor),
                // hintText: 'https://cmb.saharafcs.com',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorsUniversal.buttonsColor, width: 2), // selected border
                ),
              ),
              cursorColor: ColorsUniversal.buttonsColor,
            ),
            const SizedBox(height: 16),
            myButton(context, _handleCloudSync, 'Save & Sync', isLoading: isSyncing, loadingText: 'Syncing...'),
                      ],
        ),
      ),
    );
  }
}