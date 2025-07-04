// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/modules/channel_service.dart';
import 'package:sahara_app/modules/payment_mode_service.dart';
import 'package:sahara_app/modules/redeem_rewards_service.dart';
import 'package:sahara_app/modules/staff_list_service.dart';
import 'package:sahara_app/pages/users_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart'; // We’ll create this for getDeviceId()

class PosSettingsPage extends StatefulWidget {
  const PosSettingsPage({super.key});

  @override
  State<PosSettingsPage> createState() => _PosSettingsPageState();
}

enum OperationMode { manual, auto }

enum ReceiptNumber { single, double }

class _PosSettingsPageState extends State<PosSettingsPage> {
  bool _printPolicies = false;
  OperationMode _mode = OperationMode.manual;
  ReceiptNumber _receipt = ReceiptNumber.single;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: myAppBar('POS Settings'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Operation Mode', style: TextStyle(fontSize: 16)),
            RadioListTile<OperationMode>(
              activeColor: ColorsUniversal.buttonsColor,
              tileColor: ColorsUniversal.fillWids,
              title: const Text('Manual'),
              value: OperationMode.manual,
              groupValue: _mode,
              onChanged: (value) => setState(() => _mode = value!),
            ),
            RadioListTile<OperationMode>(
              activeColor: ColorsUniversal.buttonsColor,
              tileColor: ColorsUniversal.fillWids,
              title: const Text('Auto'),
              value: OperationMode.auto,
              groupValue: _mode,
              onChanged: (value) => setState(() => _mode = value!),
            ),
            const SizedBox(height: 12),
            const Text('Number of Receipts', style: TextStyle(fontSize: 16)),
            RadioListTile<ReceiptNumber>(
              activeColor: ColorsUniversal.buttonsColor,
              tileColor: ColorsUniversal.fillWids,
              title: const Text('Single'),
              value: ReceiptNumber.single,
              groupValue: _receipt,
              onChanged: (value) => setState(() => _receipt = value!),
            ),
            RadioListTile<ReceiptNumber>(
              activeColor: ColorsUniversal.buttonsColor,
              tileColor: ColorsUniversal.fillWids,
              title: const Text('Double'),
              value: ReceiptNumber.double,
              groupValue: _receipt,
              onChanged: (value) => setState(() => _receipt = value!),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Print Policies', style: TextStyle(fontSize: 16)),
                Switch(
                  activeColor: ColorsUniversal.appBarColor,
                  value: _printPolicies,
                  onChanged: (value) => setState(() => _printPolicies = value),
                ),
              ],
            ),
            const Spacer(),
            myButton(context, () async {
              final modeString = _mode == OperationMode.manual ? 'manual' : 'auto';
              final receiptCount = _receipt == ReceiptNumber.single ? 1 : 2;

              await SharedPrefsHelper.savePosSettings(
                mode: modeString,
                receiptCount: receiptCount,
                printPolicies: _printPolicies,
              );

              // final deviceId = await getDeviceId();
              // final isAllowed = await DummyValidator.isDeviceAllowed(deviceId);
              // if (isAllowed) {
              //   final prefs = await SharedPreferences.getInstance();
              //   final channel = prefs.getString('channel') ?? 'Station';
              final deviceId = '044ba7ee5cdd86c5';
              //fetch channel details
              final channel = await ChannelService.fetchChannelByDeviceId(deviceId);
              //fetch prdt payment modes
              final acceptedProductModes =
                  await PaymentModeService.fetchPosAcceptedModesByDevice(deviceId);
              print('✅ Accepted payment modes:');
              for (var mode in acceptedProductModes) {
                print('  • ${mode.payModeDisplayName} (${mode.payModeCategory})');
              }
              //fetch redeem rewards
              final redeemRewards = await RedeemRewardsService.fetchRedeemRewards();
              print('✅ Redeem rewards found:');
              for (var reward in redeemRewards) {
                print(
                  '  • ${reward.rewardName} (${reward.rewardGroup.rewardGroupName})',
                );
              }
              //fetch staff list
              final staffList = await StaffListService.fetchStaffList(deviceId);
              print('✅ The Staff List is:');
              for (var staff in staffList) {
                print('  •${staff.staffName} (${staff.staffPin})');
              }

              if (channel != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('channel', channel.channelName);
                showDialog(
                  // ignore: use_build_context_synchronously
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: ColorsUniversal.background,
                    title: Text(channel.channelName),
                    // content: Text('$channel station found. Proceed?'),
                    actions: [
                      TextButton(
                        child: Text(
                          'OK',
                          style: TextStyle(color: Colors.brown[800], fontSize: 17),
                        ),
                        onPressed: () async {
                          //this saves the data
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('channelName', channel.channelName);
                          await prefs.setString('companyName', channel.companyName);
                          await prefs.setBool(
                            'staffAutoLogOff',
                            channel.staffAutoLogOff,
                          );
                          await prefs.setInt(
                            'noOfDecimalPlaces',
                            channel.noOfDecimalPlaces,
                          );
                          await prefs.setInt('channelId', channel.channelId);

                          //save payment modes to hive
                          final box = Hive.box('payment_modes');
                          final modesAsMaps = acceptedProductModes
                              .map((mode) => mode.toJson())
                              .toList();
                          await box.put('acceptedModes', modesAsMaps);
                          print(
                            '✅ Saved ${modesAsMaps.length} payment modes to Hive',
                          );

                          // Save redeem rewards to Hive
                          final rewards =
                              await RedeemRewardsService.fetchRedeemRewards();
                          final rewardsBox = Hive.box('redeem_rewards');

                          // Convert each reward to a map and save
                          final rewardsAsMaps = rewards
                              .map((r) => r.toJson())
                              .toList();
                          await rewardsBox.put('rewardsList', rewardsAsMaps);

                          print(
                            '✅ Saved ${rewardsAsMaps.length} redeem rewards to Hive',
                          );

                          // Save staff list to Hive
                          final staffBox = Hive.box('staff_list');

                          // Convert staff list to List<Map<String, dynamic>>
                          final staffAsMaps = staffList
                              .map((staff) => staff.toJson())
                              .toList();

                          // Save to Hive under key 'staffList'
                          await staffBox.put('staffList', staffAsMaps);

                          print(
                            '✅ Saved ${staffAsMaps.length} staff records to Hive',
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => UsersPage()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              } else {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Validation Failed'),
                      content: Text(
                        'This device is not registered.\nDevice ID: $deviceId',
                        style: TextStyle(fontSize: 17),
                      ),
                      actions: [
                        TextButton(
                          child: Text(
                            'OK',
                            style: TextStyle(color: Colors.brown[800], fontSize: 17),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              }
            }, 'NEXT'),
          ],
        ),
      ),
    );
  }
}
