// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/modules/channel_service.dart';
import 'package:sahara_app/modules/resource_service.dart';
import 'package:sahara_app/pages/users_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.link_off, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Device Not Registered')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This device is not registered with the selected station.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Device ID:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                deviceId,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorsUniversal.fillWids,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorsUniversal.buttonsColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: ColorsUniversal.buttonsColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please contact your administrator to register this device with the station.',
                      style: TextStyle(color: ColorsUniversal.buttonsColor,),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(); // close page
            },
            child: Text(
              'OK',
              style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCloudSync() async {
    final fullUrl = _urlController.text.trim();

    if (!fullUrl.contains('.saharafcs.com')) {
      _showError(
        'Invalid URL Format',
        'Please enter a valid Sahara FCS URL (e.g., https://station.saharafcs.com)',
      );
      return;
    }

    final uri = Uri.parse(fullUrl);
    final host = uri.host;
    final resourceName = host.split('.').first;

    setState(() => isSyncing = true);

    try {
      // First, try to fetch the configuration for the resource
      final resourceSynced = await ResourceService.fetchAndSaveConfig(resourceName);

      if (!mounted) return;

      if (!resourceSynced.isSuccessfull) {
        // Handle different types of resource fetch failures
        if (resourceSynced.message.contains('No Internet Connectivity')) {
          _showError(
            'No Internet Connection',
            'Please check your internet connection and try again.',
          );
        } else if (resourceSynced.message.contains('404') || 
                   resourceSynced.message.contains('not found')) {
          _showError(
            'Station Not Found',
            'The station "$resourceName" was not found.\n\nPlease check the URL and make sure the station name is correct.',
          );
        } else if (resourceSynced.message.contains('500')) {
          _showError(
            'Server Error',
            'The server is experiencing issues. Please try again later.',
          );
        } else {
          _showError(
            'Configuration Error',
            'Unable to load configuration for "$resourceName".\n\n${resourceSynced.message}',
          );
        }
        setState(() => isSyncing = false);
        return;
      }

      // Resource configuration successful, now check device registration
      final deviceId = await getSavedOrFetchDeviceId();
      print('📱 Device ID used for sync: $deviceId');

      final channelResponse = await ChannelService.fetchChannelByDeviceId(deviceId);

      if (!channelResponse.isSuccessfull) {
        // Check if it's specifically a "device not registered" error
        if (channelResponse.message.contains('Channel Details Not Set') ||
            channelResponse.message.contains('not found') ||
            channelResponse.message.contains('not registered')) {
          
          // Revert URL to original before showing dialog
          _urlController.text = originalUrl ?? '';
          await _showDeviceNotLinkedDialog(deviceId);
          setState(() => isSyncing = false);
          return;
        } else if (channelResponse.message.contains('No Internet Connectivity')) {
          _showError(
            'Connection Lost',
            'Internet connection was lost during sync. Please try again.',
          );
        } else {
          _showError(
            'Device Check Failed',
            'Unable to verify device registration: ${channelResponse.message}',
          );
        }
        setState(() => isSyncing = false);
        return;
      }

      final channel = channelResponse.body;

      // Double-check if the channel data indicates the device is properly registered
      if (channel == null || channel.channelId == 0 || channel.channelName.isEmpty) {
        // Revert URL to original before showing dialog
        _urlController.text = originalUrl ?? '';
        await _showDeviceNotLinkedDialog(deviceId);
        setState(() => isSyncing = false);
        return;
      }

      // Everything looks good, proceed with full sync
      await fullResourceSync(deviceId: deviceId, context: context);

      if (!mounted) return;
      
      // Show success and navigate to users page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully synced channel'),
          //${channel.channelName}
          backgroundColor:  hexToColor('8f9c68'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UsersPage()),
      );

    } catch (e) {
      if (!mounted) return;
      print('❌ Unexpected error in cloud sync: $e');
      
      _showError(
        'Sync Error',
        'An unexpected error occurred during sync.\n\n${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => isSyncing = false);
      }
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _getErrorIcon(title),
              color: _getErrorColor(title),
              size: 24,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16, height: 1.4),
        ),
        actions: [
          TextButton(
            child: Text(
              'OK',
              style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  IconData _getErrorIcon(String title) {
    if (title.contains('Internet') || title.contains('Connection')) {
      return Icons.wifi_off;
    } else if (title.contains('Not Found') || title.contains('Station')) {
      return Icons.search_off;
    } else if (title.contains('Server')) {
      return Icons.cloud_off;
    } else {
      return Icons.error_outline;
    }
  }

  Color _getErrorColor(String title) {
    if (title.contains('Internet') || title.contains('Connection')) {
      return Colors.orange;
    } else if (title.contains('Server')) {
      return ColorsUniversal.appBarColor;
    } else {
      return Colors.orange[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: myAppBar('Cloud Settings'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Station URL',
                labelStyle: TextStyle(color: ColorsUniversal.buttonsColor),
                hintText: 'https://station.saharafcs.com',
                // helperText: 'Enter your station\'s complete URL',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorsUniversal.buttonsColor),
                ),
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
                    'Connect & Sync',
                    isLoading: isSyncing,
                    loadingText: 'Connecting...',
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