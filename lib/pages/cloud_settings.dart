// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/modules/channel_service.dart';
import 'package:sahara_app/modules/resource_service.dart';
import 'package:sahara_app/pages/users_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahara_app/helpers/sync_helper.dart';

class CloudSettings extends StatefulWidget {
  const CloudSettings({super.key});

  @override
  State<CloudSettings> createState() => _CloudSettingsState();
}

class _CloudSettingsState extends State<CloudSettings> {
  final TextEditingController _urlController = TextEditingController();
  bool isSyncing = false;
  String? originalUrl;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUrl = prefs.getString('webApiServiceUrl') ?? '';
    originalUrl = currentUrl; // store the original
    _urlController.text = currentUrl;
  }

  Future<void> _showDeviceNotLinkedDialog(String deviceId) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ColorsUniversal.background,
        title: const Text('Device Not Linked'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This device ID is not linked to the station you input.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            const Text('Device ID:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                deviceId,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please contact your administrator to link this device to the station.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(); // close page
            },
            child: Text('OK', style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor)),
          ),
        ],
      ),
    );
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

    if (resourceSynced.isSuccessfull) {
      try {
        final deviceId = await getSavedOrFetchDeviceId();
        print('📱 Device ID used for sync: $deviceId');

        //checks channel b4 full sync
        final channelResponse = await ChannelService.fetchChannelByDeviceId(deviceId);

        // Check if the channel fetch was successful first
        if (!channelResponse.isSuccessfull) {
          _showError('Failed to fetch channel: ${channelResponse.message}');
          setState(() => isSyncing = false);
          return;
        }
        
        final channel = channelResponse.body;

        // If channelId is 0 or name is null, assume not linked
        if (channel == null || channel.channelId == 0 || channel.channelName.isEmpty) {
          _urlController.text = originalUrl ?? ''; // revert to previous valid URL
          await _showDeviceNotLinkedDialog(deviceId);
          setState(() => isSyncing = false);
          return;
        }

        // Continue full sync
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
        backgroundColor: Colors.white,
        title: const Text('Error'),
        content: Text(msg, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
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
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorsUniversal.buttonsColor, width: 2),
                ),
              ),
              cursorColor: ColorsUniversal.buttonsColor,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: myButton(
                    context,
                    _handleCloudSync,
                    'Save & Sync',
                    isLoading: isSyncing,
                    loadingText: 'Syncing...',
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
