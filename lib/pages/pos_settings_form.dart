// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/modules/channel_service.dart';
import 'package:sahara_app/modules/payment_mode_service.dart';
import 'package:sahara_app/modules/product_service.dart';
import 'package:sahara_app/modules/redeem_rewards_service.dart';
import 'package:sahara_app/modules/staff_list_service.dart';
import 'package:sahara_app/pages/auto_mode_settings.dart';
import 'package:sahara_app/pages/pos_settings_helper.dart';
import 'package:sahara_app/pages/users_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class PosSettingsForm extends StatefulWidget {
  final bool showSyncButton;

  const PosSettingsForm({super.key, this.showSyncButton = true});

  @override
  State<PosSettingsForm> createState() => _PosSettingsFormState();
}

enum OperationMode { manual, auto }

enum ReceiptNumber { single, double }

class _PosSettingsFormState extends State<PosSettingsForm> {
  bool _printPolicies = false;
  OperationMode _mode = OperationMode.manual;
  ReceiptNumber _receipt = ReceiptNumber.single;
  bool isSyncing = false;
  bool isFinalSync = false;

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _stationNameController = TextEditingController();
  final TextEditingController _fetchingTimeController = TextEditingController();

  Future<void> showProgressDialog(BuildContext context, String message) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ColorsUniversal.background,
        content: Row(
          children: [
            SpinKitCircle(
              duration: Duration(milliseconds: 1000),
              itemBuilder: (context, index) {
                final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
                final color = colors[index % colors.length];
                return DecoratedBox(
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                );
              },
            ),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _printPolicies = prefs.getBool('printPolicies') ?? false;
      _mode = prefs.getString('mode') == 'auto' ? OperationMode.auto : OperationMode.manual;
      _receipt = (prefs.getInt('receiptCount') ?? 1) == 2 ? ReceiptNumber.double : ReceiptNumber.single;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mode', _mode == OperationMode.manual ? 'manual' : 'auto');
    await prefs.setInt('receiptCount', _receipt == ReceiptNumber.single ? 1 : 2);
    await prefs.setBool('printPolicies', _printPolicies);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Operation Mode', style: TextStyle(fontSize: 16)),
                    RadioListTile(
                      activeColor: ColorsUniversal.buttonsColor,
                      tileColor: Colors.brown[100],
                      title: const Text('Manual'),
                      value: OperationMode.manual,
                      groupValue: _mode,
                      onChanged: (value) => setState(() => _mode = value!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile(
                      activeColor: ColorsUniversal.buttonsColor,
                      tileColor: Colors.brown[100],
                      title: const Text('Auto'),
                      value: OperationMode.auto,
                      groupValue: _mode,
                      onChanged: (value) => setState(() => _mode = value!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
                    ),
                    if (_mode == OperationMode.auto) ...[
                      AutoModeSettings(
                        borderColor: ColorsUniversal.buttonsColor,
                        urlController: _urlController,
                        stationNameController: _stationNameController,
                        fetchingTimeController: _fetchingTimeController,
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('Number of Receipts', style: TextStyle(fontSize: 16)),
                    RadioListTile(
                      activeColor: ColorsUniversal.buttonsColor,
                      tileColor: Colors.brown[100],
                      title: const Text('Single'),
                      value: ReceiptNumber.single,
                      groupValue: _receipt,
                      onChanged: (value) => setState(() => _receipt = value!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile(
                      activeColor: ColorsUniversal.buttonsColor,
                      tileColor: Colors.brown[100],
                      title: const Text('Double'),
                      value: ReceiptNumber.double,
                      groupValue: _receipt,
                      onChanged: (value) => setState(() => _receipt = value!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
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
                  ],
                ),
              ),
            ),

            if (widget.showSyncButton)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: myButton(
                  context,
                  () async {
                    final rootContext = context;
                    setState(() => isSyncing = true);

                    try {
                      // Convert settings to saveable format
                      final modeString = _mode == OperationMode.manual ? 'manual' : 'auto';
                      final receiptCount = _receipt == ReceiptNumber.single ? 1 : 2;
                      
                      // saves the ACTUAL values from the text fields
                      await PosSettingsHelper.saveSettings(
                        url: _urlController.text,
                        stationName: _stationNameController.text,
                        fetchingTime: _fetchingTimeController.text,
                      );

                      print('💾 Final settings saved:');
                      print('  URL: ${_urlController.text}');
                      print('  Station: ${_stationNameController.text}');
                      print('  Duration: ${_fetchingTimeController.text}');

                      // Save POS settings to shared preferences
                      await SharedPrefsHelper.savePosSettings(
                        mode: modeString,
                        receiptCount: receiptCount,
                        printPolicies: _printPolicies,
                      );
                      
                      final deviceId = await getSavedOrFetchDeviceId();
                      print('📱 Device ID: $deviceId');

                      // Fetch channel details by device ID
                      final channelResponse = await ChannelService.fetchChannelByDeviceId(deviceId);

                      // Check if the channel fetch was successful
                      if (!channelResponse.isSuccessfull) {
                        // Check if it's specifically a "device not registered" error
                        if (channelResponse.message.contains('Channel Details Not Set') || 
                            channelResponse.message.contains('Device not registered') ||
                            channelResponse.message.contains('not registered') ||
                            channelResponse.message.contains('not found')) {
                          
                          // Show device registration dialog
                          if (rootContext.mounted) {
                            showDialog(
                              context: rootContext,
                              builder: (_) => AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text('Device Not Registered'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'This device is not registered in the system.',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Device ID:',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: SelectableText(
                                        deviceId,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Please contact your administrator to register this device.',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    child: Text(
                                      'Copy Device ID',
                                      style: TextStyle(color: Colors.brown[600], fontSize: 16),
                                    ),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: deviceId));
                                      ScaffoldMessenger.of(rootContext).showSnackBar(
                                        const SnackBar(
                                          content: Text('Device ID copied to clipboard'),
                                          duration: Duration(seconds: 2),
                                        )
                                      );
                                    },
                                  ),
                                  TextButton(
                                    child: Text(
                                      'OK', 
                                      style: TextStyle(color: Colors.brown[800], fontSize: 17),
                                    ),
                                    onPressed: () => Navigator.pop(rootContext),
                                  ),
                                ],
                              ),
                            );
                          }
                        } else if (channelResponse.message.contains('No Internet Connectivity')) {
                          // Show internet connectivity error
                          if (rootContext.mounted) {
                            showDialog(
                              context: rootContext,
                              builder: (_) => AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text('No Internet Connection'),
                                content: const Text(
                                  'Internet connection is required to sync with the server. Please check your connection and try again.',
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.pop(rootContext),
                                  ),
                                ],
                              ),
                            );
                          }
                        } else {
                          // Show generic error for other issues
                          if (rootContext.mounted) {
                            showDialog(
                              context: rootContext,
                              builder: (_) => AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text('Error'),
                                content: Text(channelResponse.message),
                                actions: [
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.pop(rootContext),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                        return; // Stop execution here
                      }

                      // If we reach here, channel fetch was successful
                      final channel = channelResponse.body;
                      if (channel != null) {
                        // Fetch other data (payment modes, rewards, staff, products)
                        final acceptedProductModes = await PaymentModeService.fetchPosAcceptedModesByDevice(deviceId);
                        print('✅ Accepted payment modes:');
                        for (var mode in acceptedProductModes.body) {
                          print('  • ${mode.payModeDisplayName} (${mode.payModeCategory})');
                        }

                        final redeemRewards = await RedeemRewardsService.fetchRedeemRewards();
                        print('✅ Redeem rewards found:');
                        for (var reward in redeemRewards.body) {
                          print('  • ${reward.rewardName} (${reward.rewardGroup.rewardGroupName})');
                        }

                        final staffList = await StaffListService.fetchStaffList(deviceId);
                        print('✅ The Staff List is:');
                        for (var staff in staffList.body) {
                          print('  •${staff.staffName} (${staff.staffPin})');
                        }

                        final productItems = await ProductService.fetchProductItems(deviceId);
                        print('✅ Product categories fetched:');
                        for (var category in productItems.body) {
                          print('📦 Category: ${category.productCategoryName}');
                          for (var product in category.products) {
                            print('   • Product: ${product.productName}');
                            for (var variation in product.productVariations) {
                              print('     - ${variation.productVariationName}: KES ${variation.productVariationPrice}');
                            }
                          }
                        }

                        // Save basic channel info to shared prefs
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('channel', channel.channelName);

                        if (!rootContext.mounted) return;

                        // Show channel confirmation dialog
                        showDialog(
                          context: rootContext,
                          builder: (_) => AlertDialog(
                            backgroundColor: ColorsUniversal.background,
                            title: Text(channel.channelName),
                            actions: [
                              TextButton(
                                child: Text('OK', style: TextStyle(color: Colors.brown[800], fontSize: 17)),
                                onPressed: () async {
                                  if (!rootContext.mounted) return;
                                  // Use full-screen loader instead
                                  setState(() => isFinalSync = true);

                                  try {
                                    // Save all channel details to shared preferences
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setString('channelName', channel.channelName);
                                    await prefs.setString('companyName', channel.companyName);
                                    await prefs.setBool('staffAutoLogOff', channel.staffAutoLogOff);
                                    await prefs.setInt('noOfDecimalPlaces', channel.noOfDecimalPlaces);
                                    await prefs.setInt('channelId', channel.channelId);

                                    // Save payment modes to Hive
                                    final box = Hive.box('payment_modes');
                                    final modesAsMaps = acceptedProductModes.body.map((mode) => mode.toJson()).toList();
                                    await box.put('acceptedModes', modesAsMaps);
                                    print('✅ Saved ${modesAsMaps.length} payment modes to Hive');

                                    // Save redeem rewards to Hive
                                    final rewardsBox = Hive.box('redeem_rewards');
                                    final rewardsAsMaps = redeemRewards.body.map((r) => r.toJson()).toList();
                                    await rewardsBox.put('rewardsList', rewardsAsMaps);
                                    print('✅ Saved ${rewardsAsMaps.length} redeem rewards to Hive');

                                    // Save staff list to Hive
                                    final staffBox = Hive.box('staff_list');
                                    final staffAsMaps = staffList.body.map((staff) => staff.toJson()).toList();
                                    await staffBox.put('staffList', staffAsMaps);
                                    print('✅ Saved ${staffAsMaps.length} staff records to Hive');

                                    // Save products to Hive
                                    final productsBox = Hive.box('products');
                                    final productsAsMaps = productItems.body.map((p) => p.toJson()).toList();
                                    await productsBox.put('productItems', productsAsMaps);
                                    print('✅ Saved ${productsAsMaps.length} product categories to Hive');

                                    // Navigate to UsersPage
                                    if (rootContext.mounted) {
                                      setState(() => isFinalSync = false);

                                      // Mark setup as complete
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setBool('isSetupComplete', true);
                                      Navigator.push(rootContext, MaterialPageRoute(builder: (_) => UsersPage()));
                                    }
                                  } catch (e) {
                                    print('❌ Error saving data: $e');
                                    if (rootContext.mounted) {
                                      setState(() => isFinalSync = false);
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      if (rootContext.mounted) Navigator.pop(rootContext);
                      if (rootContext.mounted) Navigator.pop(rootContext);
                      print('❌ Error in POS setup: $e');
                    } finally {
                      setState(() => isSyncing = false);
                    }
                  },
                  'NEXT',
                  isLoading: isSyncing,
                  loadingText: 'Syncing...',
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: myButton(context, () async {
                  await _saveSettings();
                  if (context.mounted) Navigator.pop(context);
                }, 'Save Settings'),
              ),
          ],
        ),
        if (isFinalSync)
          Center(
            child: SpinKitCircle(
              size: 70,
              duration: Duration(milliseconds: 1000),
              itemBuilder: (context, index) {
                final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
                final color = colors[index % colors.length];
                return DecoratedBox(
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _stationNameController.dispose();
    _fetchingTimeController.dispose();
    super.dispose();
  }
}
