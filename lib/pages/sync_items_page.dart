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

  Future<void> handleSync(String method) async {
    // Store context locally before async operations
    final currentContext = context;

    if (!currentContext.mounted) return;

    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (_) => Center(
        child: SpinKitCircle(
          size: 70,
          duration: Duration(milliseconds: 1000),
          itemBuilder: (context, index) {
            final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
            final color = colors[index % colors.length];
            return DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            );
          },
        ),
      ),
    );

    try {
      final deviceId = await getSavedOrFetchDeviceId();
      print('📱 Device ID used for sync: $deviceId');

      switch (method) {
        case 'channel':
          final channelResponse = await ChannelService.fetchChannelByDeviceId(deviceId);
          if (channelResponse.isSuccessfull && channelResponse.body != null) {
            final channel = channelResponse.body!;
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
          final newStaffListRes = await StaffListService.fetchStaffList(deviceId);
          if(!newStaffListRes.isSuccessfull){
            showDialog(context: context, builder: (_)=> Dialog(child: Text(newStaffListRes.message),));
            return;
          }
          final newStaffList = newStaffListRes.body;
          final staffBox = Hive.box('staff_list');
          final staffAsMaps = newStaffList.map((e) => e.toJson()).toList();
          await staffBox.put('staffList', staffAsMaps);
          break;

        case 'payment_modes':
          final acceptedModes = await PaymentModeService.fetchPosAcceptedModesByDevice(deviceId);
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
          SnackBar(
            backgroundColor: hexToColor('8f9c68'),
            content: Text('Successfully synced $method'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (currentContext.mounted) {
        Navigator.of(currentContext).pop();
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.grey,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text(' Failed to sync $method: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar(
        'Sync Items',
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => Center(
                  child: SpinKitCircle(
                    size: 70,
                    duration: const Duration(milliseconds: 1000),
                    itemBuilder: (context, index) {
                      final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
                      final color = colors[index % colors.length];
                      return DecoratedBox(
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      );
                    },
                  ),
                ),
              );

              try {
                final deviceId = await getSavedOrFetchDeviceId();
                print('📱 Device ID used for sync: $deviceId');

                await fullResourceSync(deviceId: deviceId, context: context);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: hexToColor('8f9c68'),
                    content: const Text('All resources synced successfully'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    // content: Text('All resources synced successfully'),
                    // behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sync failed: ${e.toString()}'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.grey,
                  ),
                );
              }
            },
            icon: Icon(Icons.sync, color: ColorsUniversal.fillWids),
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
                      Text(item.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
