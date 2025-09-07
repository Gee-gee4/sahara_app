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

  bool allSuccessful = true;
  String errorMessage = '';

  // Channel
  final channelResponse = await ChannelService.fetchChannelByDeviceId(deviceId);
  if (channelResponse.isSuccessfull && channelResponse.body != null) {
    final channel = channelResponse.body!;
    await prefs.setString('channelName', channel.channelName);
    await prefs.setString('companyName', channel.companyName);
    await prefs.setBool('staffAutoLogOff', channel.staffAutoLogOff);
    await prefs.setInt('noOfDecimalPlaces', channel.noOfDecimalPlaces);
    await prefs.setInt('channelId', channel.channelId);
  } else {
    allSuccessful = false;
    errorMessage = 'Channel: ${channelResponse.message}';
  }

  // Only continue if channel sync was successful
  if (!allSuccessful) {
    throw Exception(errorMessage);
  }

  // Payment modes
  final acceptedModesResponse = await PaymentModeService.fetchPosAcceptedModesByDevice(deviceId);
  if (acceptedModesResponse.isSuccessfull) {
    final modeBox = Hive.box('payment_modes');
    await modeBox.put('acceptedModes', acceptedModesResponse.body.map((m) => m.toJson()).toList());
  } else {
    allSuccessful = false;
    errorMessage = 'Payment Modes: ${acceptedModesResponse.message}';
  }

  // Rewards
  final rewardsResponse = await RedeemRewardsService.fetchRedeemRewards();
  if (rewardsResponse.isSuccessfull) {
    final rewardsBox = Hive.box('redeem_rewards');
    await rewardsBox.put('rewardsList', rewardsResponse.body.map((r) => r.toJson()).toList());
  } else {
    allSuccessful = false;
    errorMessage = 'Rewards: ${rewardsResponse.message}';
  }

  // Staff
  final staffListResponse = await StaffListService.fetchStaffList(deviceId);
  if (staffListResponse.isSuccessfull) {
    final staffBox = Hive.box('staff_list');
    await staffBox.put('staffList', staffListResponse.body.map((e) => e.toJson()).toList());
  } else {
    allSuccessful = false;
    errorMessage = 'Staff: ${staffListResponse.message}';
  }

  // Products
  final productsResponse = await ProductService.fetchProductItems(deviceId);
  if (productsResponse.isSuccessfull) {
    final productsBox = Hive.box('products');
    await productsBox.put('productItems', productsResponse.body.map((p) => p.toJson()).toList());
  } else {
    allSuccessful = false;
    errorMessage = 'Products: ${productsResponse.message}';
  }

  if (!allSuccessful) {
    throw Exception(errorMessage);
  }
}
