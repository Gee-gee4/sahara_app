import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/modules/channel_service.dart';
import 'package:sahara_app/modules/payment_mode_service.dart';
import 'package:sahara_app/modules/product_service.dart';
import 'package:sahara_app/modules/redeem_rewards_service.dart';
import 'package:sahara_app/modules/staff_list_service.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncItemsPage extends StatefulWidget {
  const SyncItemsPage({super.key});

  @override
  State<SyncItemsPage> createState() => _SyncItemsPageState();
}

class _SyncItemsPageState extends State<SyncItemsPage> {
  final deviceId = '044ba7ee5cdd86c5';

  final List<_SyncItem> syncItems = [
    _SyncItem(label: 'Channel', icon: Icons.device_hub, syncMethod: 'channel'),
    _SyncItem(label: 'Products', icon: Icons.shopping_bag, syncMethod: 'products'),
    _SyncItem(label: 'Staff', icon: Icons.people, syncMethod: 'staff'),
    _SyncItem(
      label: 'Payment Modes',
      icon: Icons.payment,
      syncMethod: 'payment_modes',
    ),
    _SyncItem(label: 'Redeem Rewards', icon: Icons.redeem, syncMethod: 'rewards'),
  ];

  Future<void> handleSync(String method) async {
    // Store context locally before async operations
    final currentContext = context;
    
    if (!currentContext.mounted) return;
    
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      switch (method) {
        case 'channel':
          final channel = await ChannelService.fetchChannelByDeviceId(deviceId);
          if (channel != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('channelName', channel.channelName);
            await prefs.setString('companyName', channel.companyName);
            await prefs.setBool('staffAutoLogOff', channel.staffAutoLogOff);
            await prefs.setInt('noOfDecimalPlaces', channel.noOfDecimalPlaces);
            await prefs.setInt('channelId', channel.channelId);
          } else {
            throw Exception('Channel not found');
          }
          break;
        case 'products':
          final products = await ProductService.fetchProductItems(deviceId);
          final productsBox = Hive.box('products');
          final productsAsMaps = products.map((p) => p.toJson()).toList();
          await productsBox.put('productItems', productsAsMaps);
          break;

        case 'staff':
          final newStaffList = await StaffListService.fetchStaffList(deviceId);
          final staffBox = Hive.box('staff_list');
          final staffAsMaps = newStaffList.map((e) => e.toJson()).toList();
          await staffBox.put('staffList', staffAsMaps);
          break;

        case 'payment_modes':
          final acceptedModes =
              await PaymentModeService.fetchPosAcceptedModesByDevice(deviceId);
          final modeBox = Hive.box('payment_modes');
          final modesAsMaps = acceptedModes.map((m) => m.toJson()).toList();
          await modeBox.put('acceptedModes', modesAsMaps);
          break;

        case 'rewards':
          final rewards = await RedeemRewardsService.fetchRedeemRewards();
          final rewardsBox = Hive.box('redeem_rewards');
          final rewardsAsMaps = rewards.map((r) => r.toJson()).toList();
          await rewardsBox.put('rewardsList', rewardsAsMaps);
          break;
      }

      if (currentContext.mounted) {
        Navigator.of(currentContext).pop();
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Synced $method')),
        );
      }
    } catch (e) {
      if (currentContext.mounted) {
        Navigator.of(currentContext).pop();
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('❌ Failed to sync $method: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar('Sync Items'),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.brown[100],
                elevation: 4,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 40, color: Colors.brown[800]),
                      const SizedBox(height: 10),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
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

  _SyncItem({
    required this.label,
    required this.icon,
    required this.syncMethod,
  });
}