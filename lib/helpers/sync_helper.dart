import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/modules/channel_service.dart';
import 'package:sahara_app/modules/payment_mode_service.dart';
import 'package:sahara_app/modules/product_service.dart';
import 'package:sahara_app/modules/redeem_rewards_service.dart';
import 'package:sahara_app/modules/staff_list_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> fullResourceSync({
  required String deviceId,
  required BuildContext context,
}) async {
  final prefs = await SharedPreferences.getInstance();

  // Channel
  final channel = await ChannelService.fetchChannelByDeviceId(deviceId);
  if (channel != null) {
    await prefs.setString('channelName', channel.channelName);
    await prefs.setString('companyName', channel.companyName);
    await prefs.setBool('staffAutoLogOff', channel.staffAutoLogOff);
    await prefs.setInt('noOfDecimalPlaces', channel.noOfDecimalPlaces);
    await prefs.setInt('channelId', channel.channelId);
  }

  // Payment modes
  final acceptedModes = await PaymentModeService.fetchPosAcceptedModesByDevice(deviceId);
  final modeBox = Hive.box('payment_modes');
  await modeBox.put('acceptedModes', acceptedModes.map((m) => m.toJson()).toList());

  // Rewards
  final rewards = await RedeemRewardsService.fetchRedeemRewards();
  final rewardsBox = Hive.box('redeem_rewards');
  await rewardsBox.put('rewardsList', rewards.map((r) => r.toJson()).toList());

  // Staff
  final staffList = await StaffListService.fetchStaffList(deviceId);
  final staffBox = Hive.box('staff_list');
  await staffBox.put('staffList', staffList.map((e) => e.toJson()).toList());

  // Products
  final products = await ProductService.fetchProductItems(deviceId);
  final productsBox = Hive.box('products');
  await productsBox.put('productItems', products.map((p) => p.toJson()).toList());
}
