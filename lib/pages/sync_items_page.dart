// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/helpers/sync_helper.dart';
import 'package:sahara_app/modules/channel_service.dart';
import 'package:sahara_app/modules/payment_mode_service.dart';
import 'package:sahara_app/modules/product_service.dart';
import 'package:sahara_app/modules/redeem_rewards_service.dart';
import 'package:sahara_app/modules/staff_list_service.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncItemsPage extends StatefulWidget {
  const SyncItemsPage({super.key});

  @override
  State<SyncItemsPage> createState() => _SyncItemsPageState();
}

class _SyncItemsPageState extends State<SyncItemsPage> {
  final List<_SyncItem> syncItems = [
    _SyncItem(label: 'Channel', icon: Icons.device_hub, syncMethod: 'channel'),
    _SyncItem(label: 'Products', icon: Icons.shopping_bag, syncMethod: 'products'),
    _SyncItem(label: 'Staff', icon: Icons.people, syncMethod: 'staff'),
    _SyncItem(label: 'Payment Modes', icon: Icons.payment, syncMethod: 'payment_modes'),
    _SyncItem(label: 'Redeem Rewards', icon: Icons.redeem, syncMethod: 'rewards'),
  ];

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitCircle(
              size: 50,
              duration: Duration(milliseconds: 1000),
              itemBuilder: (context, index) {
                final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
                final color = colors[index % colors.length];
                return DecoratedBox(
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                );
              },
            ),
            SizedBox(height: 16),
            Text(message, style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              message.contains('No Internet Connectivity') ? Icons.wifi_off : Icons.error_outline,
              color: message.contains('No Internet Connectivity') ? Colors.orange : Colors.red,
              size: 24,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        content: Text(message, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
              child: Text('Retry', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: hexToColor('8f9c68'),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> handleSync(String method) async {
    // Store context locally before async operations
    final currentContext = context;
    if (!currentContext.mounted) return;

    // Show loading dialog with specific message
    String itemName = syncItems.firstWhere((item) => item.syncMethod == method).label;
    _showLoadingDialog('Syncing $itemName...');

    try {
      final deviceId = await getSavedOrFetchDeviceId();
      print('📱 Device ID used for sync: $deviceId');

      switch (method) {
        case 'channel':
          final channelResponse = await ChannelService.fetchChannelByDeviceId(deviceId);

          // Close loading dialog first
          if (currentContext.mounted) Navigator.pop(currentContext);

          if (!channelResponse.isSuccessfull) {
            _showErrorDialog('Channel Sync Failed', channelResponse.message, onRetry: () => handleSync(method));
            return;
          }

          if (channelResponse.body == null) {
            _showErrorDialog(
              'Channel Sync Failed',
              'No channel data received from server',
              onRetry: () => handleSync(method),
            );
            return;
          }

          final channel = channelResponse.body!;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('channelName', channel.channelName);
          await prefs.setString('companyName', channel.companyName);
          await prefs.setBool('staffAutoLogOff', channel.staffAutoLogOff);
          await prefs.setInt('noOfDecimalPlaces', channel.noOfDecimalPlaces);
          await prefs.setInt('channelId', channel.channelId);
          break;

        case 'products':
          final productsRes = await ProductService.fetchProductItems(deviceId);

          // Close loading dialog first
          if (currentContext.mounted) Navigator.pop(currentContext);

          if (!productsRes.isSuccessfull) {
            _showErrorDialog('Products Sync Failed', productsRes.message, onRetry: () => handleSync(method));
            return;
          }

          final products = productsRes.body;
          final productsBox = Hive.box('products');
          final productsAsMaps = products.map((p) => p.toJson()).toList();
          await productsBox.put('productItems', productsAsMaps);
          break;

        case 'staff':
          final newStaffListRes = await StaffListService.fetchStaffList(deviceId);

          // Close loading dialog first
          if (currentContext.mounted) Navigator.pop(currentContext);

          if (!newStaffListRes.isSuccessfull) {
            _showErrorDialog('Staff Sync Failed', newStaffListRes.message, onRetry: () => handleSync(method));
            return;
          }

          final newStaffList = newStaffListRes.body;
          final staffBox = Hive.box('staff_list');
          final staffAsMaps = newStaffList.map((e) => e.toJson()).toList();
          await staffBox.put('staffList', staffAsMaps);
          break;

        case 'payment_modes':
          final acceptedModesRes = await PaymentModeService.fetchPosAcceptedModesByDevice(deviceId);

          // Close loading dialog first
          if (currentContext.mounted) Navigator.pop(currentContext);

          if (!acceptedModesRes.isSuccessfull) {
            _showErrorDialog('Payment Modes Sync Failed', acceptedModesRes.message, onRetry: () => handleSync(method));
            return;
          }

          final acceptedModes = acceptedModesRes.body;
          final modeBox = Hive.box('payment_modes');
          final modesAsMaps = acceptedModes.map((m) => m.toJson()).toList();
          await modeBox.put('acceptedModes', modesAsMaps);
          break;

        case 'rewards':
          final rewardsRes = await RedeemRewardsService.fetchRedeemRewards();

          // Close loading dialog first
          if (currentContext.mounted) Navigator.pop(currentContext);

          if (!rewardsRes.isSuccessfull) {
            _showErrorDialog('Rewards Sync Failed', rewardsRes.message, onRetry: () => handleSync(method));
            return;
          }

          final rewards = rewardsRes.body;
          final rewardsBox = Hive.box('redeem_rewards');
          final rewardsAsMaps = rewards.map((r) => r.toJson()).toList();
          await rewardsBox.put('rewardsList', rewardsAsMaps);
          break;
      }

      // Show success message
      _showSuccessSnackBar('Successfully synced $itemName');
    } catch (e) {
      // Make sure loading dialog is closed
      if (currentContext.mounted) {
        try {
          Navigator.pop(currentContext);
        } catch (_) {
          // Dialog might already be closed
        }
      }

      // Show error dialog for unexpected errors
      _showErrorDialog(
        'Sync Error',
        'An unexpected error occurred: ${e.toString()}',
        onRetry: () => handleSync(method),
      );

      print('❌ Error syncing $method: $e');
    }
  }

  Future<void> _handleSyncAll() async {
    final currentContext = context;
    if (!currentContext.mounted) return;

    _showLoadingDialog('Syncing all resources...');

    try {
      final deviceId = await getSavedOrFetchDeviceId();
      print('📱 Device ID used for sync all: $deviceId');

      await fullResourceSync(deviceId: deviceId, context: context);

      // Close loading dialog
      if (currentContext.mounted) Navigator.pop(currentContext);

      _showSuccessSnackBar('All resources synced successfully');
    } catch (e) {
      // Make sure loading dialog is closed
      if (currentContext.mounted) {
        try {
          Navigator.pop(currentContext);
        } catch (_) {
          // Dialog might already be closed
        }
      }

      // Parse the error to get user-friendly message
      String userFriendlyMessage = _parseErrorMessage(e.toString());

      // Show error dialog
      _showErrorDialog('Sync All Failed', userFriendlyMessage, onRetry: _handleSyncAll);

      print('❌ Error syncing all resources: $e');
    }
  }

  // Add this helper method to extract user-friendly error messages
  String _parseErrorMessage(String errorString) {
    // Handle "Exception: Channel: No Internet Connectivity" format
    if (errorString.contains('Exception:') && errorString.contains(':')) {
      // Split by 'Exception:' and take the part after the second ':'
      final parts = errorString.split('Exception:');
      if (parts.length > 1) {
        final afterException = parts[1].trim();
        final colonParts = afterException.split(':');
        if (colonParts.length > 1) {
          // Return everything after the first colon (the actual error message)
          return colonParts.sublist(1).join(':').trim();
        } else {
          // No colon found after Exception:, return as is
          return afterException;
        }
      }
    }
    // Handle other common error patterns
    if (errorString.contains('No Internet Connectivity')) {
      return 'No Internet Connectivity';
    } else if (errorString.contains('Connection reset') || errorString.contains('reset by peer')) {
      return 'Connection was interrupted. Please check your internet and try again.';
    } else if (errorString.contains('Connection refused')) {
      return 'Unable to connect to server. Please check your settings.';
    } else if (errorString.contains('timeout')) {
      return 'Connection timed out. Please try again.';
    } else if (errorString.contains('SocketException')) {
      return 'Network connection problem. Please check your internet.';
    } else if (errorString.contains('HttpException')) {
      return 'Server connection problem. Please try again.';
    } else if (errorString.contains('FormatException')) {
      return 'Received invalid data from server. Please try again.';
    }

    // If no pattern matches, return a generic friendly message
    return 'Something went wrong during sync. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: myAppBar(
        'Sync Items',
        actions: [
          ElevatedButton.icon(
            onPressed: _handleSyncAll,
            icon: Icon(Icons.sync, color: Colors.white),
            label: const Text('Sync All', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsUniversal.buttonsColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: syncItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = syncItems[index];
            return GestureDetector(
              onTap: () => handleSync(item.syncMethod),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.brown[50],
                elevation: 4,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 40, color: Colors.brown[800]),
                      const SizedBox(height: 10),
                      Text(
                        item.label,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SyncItem {
  final String label;
  final IconData icon;
  final String syncMethod;

  _SyncItem({required this.label, required this.icon, required this.syncMethod});
}
