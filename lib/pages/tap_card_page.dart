// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/uid_converter.dart';
import 'package:sahara_app/models/customer_account_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/complete_card_init_service.dart';
import 'package:sahara_app/modules/customer_account_details_service.dart';
import 'package:sahara_app/modules/initialize_card_service.dart';
import 'package:sahara_app/modules/nfc_functions.dart';
import 'package:sahara_app/pages/card_details_page.dart';
import 'package:sahara_app/pages/settings_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class TapCardPage extends StatefulWidget {
  const TapCardPage({super.key, required this.user, required this.action});
  final StaffListModel user;
  final TapCardAction action;

  @override
  State<TapCardPage> createState() => _TapCardPageState();
}

bool isProcessing = false;
String result = '';

class _TapCardPageState extends State<TapCardPage> {
  @override
  void initState() {
    super.initState();
    // Don't call functions here - let the button handle it
    switch (widget.action) {
      case TapCardAction.initialize:
        result = "Initialize card";
        break;
      case TapCardAction.format:
        result = "Format card";
        break;
      case TapCardAction.viewUID:
        result = "Card UID";
        break;
      case TapCardAction.changePin:
        result = "Change card PIN";
        break;
      case TapCardAction.cardDetails:
        result = "Card details";
        break;
    }
  }

  Future<void> initializeCard() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      result = "Starting initialization...";
    });

    final nfc = NfcFunctions(); // Changed from NfcModule() to NfcFunctions()

    try {
      // Step 1: Prompt user for PIN
      String? pin = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Set Your PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter a 4-digit PIN for your card:'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(hintText: 'Enter 4-digit PIN', border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('OK')),
            ],
          );
        },
      );

      if (pin == null || pin.length != 4) {
        setState(() {
          result = "❌ PIN entry cancelled or invalid";
          isProcessing = false;
        });
        return;
      }

      setState(() => result = "📱 Waiting for card...\nPlace your blank card on the phone");

      // Step 2: Poll for card
      final tag = await FlutterNfcKit.poll();
      if (tag.type != NFCTagType.mifare_classic) {
        setState(() {
          result = "❌ Not a MIFARE Classic card";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      // Step 3: Get card UID and fetch account details
      final rawUID = tag.id;
      final convertedUID = UIDConverter.convertToPOSFormat(rawUID);
      final imei = 'd66e5cf98b2ae46c';
      final staffId = widget.user.staffId; // Use your user's staff ID

      setState(() => result = "🔍 Fetching account details for card...");

      // Fetch account data
      final accountData = await InitializeCardService.fetchCardData(
        cardUID: convertedUID,
        imei: imei,
        staffID: staffId,
      );

      if (accountData == null) {
        setState(() {
          result =
              "❌ No account found for this card.\nUID: $convertedUID\nPlease assign this card to an account first.";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      setState(() => result = "📝 Initializing card with account ${accountData.customerAccountNumber}...");

      // Step 4: Write account number to Sector 1, Block 0
      final accountNo = accountData.customerAccountNumber.toString();
      final result1 = await nfc.writeSectorBlock(
        sectorIndex: 1,
        blockSectorIndex: 0,
        data: '$accountNo;',
        useDefaultKeys: true,
      );

      if (result1.status != NfcMessageStatus.success) {
        throw Exception("Failed to write account number: ${result1.data}");
      }

      // Step 5: Write PIN to Sector 2, Block 0
      final result2 = await nfc.writeSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        data: '$pin;',
        useDefaultKeys: true,
      );

      if (result2.status != NfcMessageStatus.success) {
        throw Exception("Failed to write PIN: ${result2.data}");
      }

      // Step 6: Write max attempts (3) to Sector 2, Block 1
      final result3 = await nfc.writeSectorBlock(sectorIndex: 2, blockSectorIndex: 1, data: '3;', useDefaultKeys: true);

      if (result3.status != NfcMessageStatus.success) {
        throw Exception("Failed to write lock count: ${result3.data}");
      }

      // Step 7: Write initialization flag (1) to Sector 2, Block 2
      final result4 = await nfc.writeSectorBlock(sectorIndex: 2, blockSectorIndex: 2, data: '1;', useDefaultKeys: true);

      if (result4.status != NfcMessageStatus.success) {
        throw Exception("Failed to write init status: ${result4.data}");
      }

      // Step 8: Change keys for both sectors to POS keys
      final changeKey1 = await nfc.changeKeys(sectorIndex: 1, fromDefault: true);
      if (changeKey1.status != NfcMessageStatus.success) {
        throw Exception("Failed to change keys for sector 1: ${changeKey1.data}");
      }

      final changeKey2 = await nfc.changeKeys(sectorIndex: 2, fromDefault: true);
      if (changeKey2.status != NfcMessageStatus.success) {
        throw Exception("Failed to change keys for sector 2: ${changeKey2.data}");
      }

      // Step 9: Success!
      await FlutterNfcKit.finish();
      // Complete initialization in portal
      setState(() => result = "📡 Completing initialization in portal...");

      final completed = await CompleteCardInitService.completeInitializeCard(
        uid: convertedUID,
        accountNo: accountData.customerAccountNumber,
        staffId: staffId,
      );

      if (!completed) {
        print("⚠️ Warning: Card initialized but portal update failed");
      }

      setState(() {
        result =
            '''
✅ Card initialized successfully!
${completed ? '✅ Portal updated successfully!' : '⚠️ Portal update failed (card still works)'}

// ... rest of your success message
''';
        isProcessing = false;
      });

      setState(() {
        result =
            '''
✅ Card initialized successfully!

👤 Customer: ${accountData.customerName}
📞 Phone: ${accountData.customerPhone}
📧 Email: ${accountData.customerEmail}
🏦 Account: ${accountData.customerAccountNumber}
💳 Type: ${accountData.accountCreditTypeName}
🔐 PIN: $pin
🔢 Max attempts: 3
✅ Status: Initialized

🔑 Keys: POS system keys set
🏪 Ready for POS use!

🔧 Debug Info:
📱 App UID: $rawUID
🏪 POS UID: $convertedUID
''';
        isProcessing = false;
      });
    } catch (e) {
      await FlutterNfcKit.finish();
      setState(() {
        result = "❌ Initialization failed:\n$e";
        isProcessing = false;
      });
    }
  }

  //FORMAT CARD
  Future<void> formatCard() async {
    if (isProcessing) return;

    if (!mounted) return;
    setState(() {
      isProcessing = true;
      result = "⚠️ FORMATTING CARD...\nThis will erase ALL data!";
    });

    // Show confirmation dialog
    if (!mounted) return;
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('⚠️ Format Card'),
          content: const Text(
            'This will completely erase all data on the card and reset it to factory defaults.\n\n'
            'Are you sure you want to continue?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('FORMAT'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (confirmed != true) {
      setState(() {
        result = "❌ Format cancelled";
        isProcessing = false;
      });
      return;
    }

    final nfc = NfcFunctions();

    try {
      if (!mounted) return;
      setState(() => result = "📱 Waiting for card to format...\nPlace your card on the phone");

      final tag = await FlutterNfcKit.poll();
      final rawUID = tag.id;

      if (tag.type != NFCTagType.mifare_classic) {
        if (!mounted) return;
        setState(() {
          result = "❌ Not a MIFARE Classic card";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      if (!mounted) return;
      setState(() => result = "🗑️ Formatting card...\nErasing all data and resetting keys");

      // Format sectors
      List<String> formatResults = [];

      for (int sector in [1, 2]) {
        bool formatted = false;

        try {
          final result = await nfc.formatSector(sectorIndex: sector, useDefaultKeys: false);
          if (result.status == NfcMessageStatus.success) {
            formatResults.add("✅ Sector $sector: ${result.data}");
            formatted = true;
          }
        } catch (_) {}

        if (!formatted) {
          try {
            final result = await nfc.formatSector(sectorIndex: sector, useDefaultKeys: true);
            if (result.status == NfcMessageStatus.success) {
              formatResults.add("✅ Sector $sector: ${result.data}");
              formatted = true;
            } else {
              formatResults.add("❌ Sector $sector: ${result.data}");
            }
          } catch (e) {
            formatResults.add("❌ Sector $sector: Error - $e");
          }
        }
      }

      await FlutterNfcKit.finish();

      if (!mounted) return;
      setState(() => result = "📡 Removing card assignment from portal...");

      final convertedUID = UIDConverter.convertToPOSFormat(rawUID);
      final staffId = widget.user.staffId;

      final apiSuccess = await InitializeCardService.formatCardAPI(cardUID: convertedUID, staffId: staffId);

      if (!mounted) return;
      setState(() {
        result =
            '''
🎉 Card Format Complete!

${formatResults.join('\n')}

🔓 All keys reset to default (FF FF FF FF FF FF)
💳 Card ready for new assignment

${apiSuccess ? '✅ Portal: Card unassigned successfully' : '⚠️ Portal: Unassignment failed (card still formatted)'}
''';
        isProcessing = false;
      });
    } catch (e) {
      await FlutterNfcKit.finish();
      if (!mounted) return;
      setState(() {
        result = "❌ Format failed:\n$e";
        isProcessing = false;
      });
    }
  }

  //CHANGE PIN
  //CHANGE CARD PIN
  Future<void> changeCardPIN() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      result = "🔐 Preparing to change PIN...";
    });

    //  Show PIN change dialog
    Map<String, String>? pinData = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final oldPinController = TextEditingController();
        final newPinController = TextEditingController();
        final confirmPinController = TextEditingController();

        return AlertDialog(
          title: const Text('🔐 Change Card PIN'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter your current PIN and new PIN:'),
                const SizedBox(height: 16),

                // Old PIN field
                TextField(
                  controller: oldPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Current PIN',
                    hintText: 'Enter current 4-digit PIN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),

                // New PIN field
                TextField(
                  controller: newPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'New PIN',
                    hintText: 'Enter new 4-digit PIN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),

                // Confirm new PIN field
                TextField(
                  controller: confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New PIN',
                    hintText: 'Re-enter new PIN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                // Validate inputs
                String oldPin = oldPinController.text;
                String newPin = newPinController.text;
                String confirmPin = confirmPinController.text;

                if (oldPin.length != 4 || newPin.length != 4 || confirmPin.length != 4) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('All PINs must be exactly 4 digits')));
                  return;
                }

                if (newPin != confirmPin) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('New PIN and confirmation do not match')));
                  return;
                }

                if (oldPin == newPin) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('New PIN must be different from current PIN')));
                  return;
                }

                Navigator.of(context).pop({'oldPin': oldPin, 'newPin': newPin});
              },
              child: const Text('Change PIN'),
            ),
          ],
        );
      },
    );

    if (pinData == null) {
      setState(() {
        result = "❌ PIN change cancelled";
        isProcessing = false;
      });
      return;
    }

    final nfc = NfcFunctions();

    try {
      setState(() => result = "📱 Waiting for card...\nPlace your card on the phone");

      // Step 2: Poll for card
      final tag = await FlutterNfcKit.poll();
      if (tag.type != NFCTagType.mifare_classic) {
        setState(() {
          result = "❌ Not a MIFARE Classic card";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      setState(() => result = "🔍 Verifying current PIN...");

      // Step 3: Read current PIN from Sector 2, Block 0 (using POS keys)
      final currentPinResult = await nfc.readSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        useDefaultKeys: false, // Use POS keys
      );

      if (currentPinResult.status != NfcMessageStatus.success) {
        throw Exception("Failed to read current PIN: ${currentPinResult.data}");
      }

      // Step 4: Verify the old PIN matches
      String storedPin = currentPinResult.data.replaceAll(';', '').trim();
      String enteredOldPin = pinData['oldPin']!;

      if (storedPin != enteredOldPin) {
        setState(() {
          result =
              "❌ PIN Change Failed!\n\n"
              "Incorrect current PIN entered.\n"
              "Stored PIN: '$storedPin'\n"
              "Entered PIN: '$enteredOldPin'\n\n"
              "Please try again with correct current PIN.";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      setState(() => result = "✅ Current PIN verified!\n🔄 Writing new PIN...");

      // Step 5: Write new PIN to Sector 2, Block 0
      final newPinResult = await nfc.writeSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        data: '${pinData['newPin']!};',
        useDefaultKeys: false, // Use POS keys
      );

      if (newPinResult.status != NfcMessageStatus.success) {
        throw Exception("Failed to write new PIN: ${newPinResult.data}");
      }

      // Step 6: Verify the new PIN was written correctly
      final verifyResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

      String newStoredPin = verifyResult.data.replaceAll(';', '').trim();

      await FlutterNfcKit.finish();

      setState(() {
        result =
            "✅ PIN Changed Successfully!\n\n"
            "📊 PIN Change Details:\n"
            "• Old PIN: ${pinData['oldPin']!}\n"
            "• New PIN: ${pinData['newPin']!}\n"
            "• Verified: $newStoredPin\n\n"
            "🔒 Your card PIN has been updated!\n"
            "💡 Remember your new PIN for future use.";
        isProcessing = false;
      });
    } catch (e) {
      await FlutterNfcKit.finish();
      setState(() {
        result =
            "❌ PIN change failed:\n$e\n\n"
            "💡 Make sure:\n"
            "• Card is properly positioned\n"
            "• Card was previously initialized\n"
            "• Current PIN is correct";
        isProcessing = false;
      });
    }
  }

  /// C A R D  D E T A I L S
  Future<CustomerAccountDetailsModel?> fetchCustomerAccountDetails({
    required String accountNo,
    required String deviceId,
  }) async {
    final url = Uri.parse('https://cmb.saharafcs.com/api/CustomerAccountDetails/$accountNo/$deviceId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CustomerAccountDetailsModel.fromJson(data);
      } else {
        print('❌ Failed to fetch account details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching customer account details: $e');
      return null;
    }
  }

  //C A R D  U I D
  void viewUID(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          title: Text("Scanning..."),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text("Hold card near device")),
            ],
          ),
        ),
      );

      // Poll for card
      NFCTag tag = await FlutterNfcKit.poll();

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Get UID
      final appUID = tag.id;
      final posUID = UIDConverter.convertToPOSFormat(appUID);

      // Show result
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Card Identifier"),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UID', style: TextStyle(fontSize: 20, color: Colors.black54)),
                Text(': $posUID', style: TextStyle(fontSize: 20, color: Colors.black54)),
              ],
            ),
            //  Column(
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     Text("App Format (Hex): $appUID"),
            //     const SizedBox(height: 8),
            //     Text("POS Format (Decimal): $posUID"),
            //   ],
            // ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog first
                  Navigator.of(context).pop(); // Then pop the page below it
                },
                child: Text("OK", style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
      }

      await FlutterNfcKit.finish();
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // close any open dialogs
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: Text("Failed to read card: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK", style: TextStyle(fontSize: 20, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(
                'Hold the Card/Tag at the \nreader and keep it there',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
              RotatedBox(
                quarterTurns: -2,
                child: Image.asset('assets/images/nfc_scan.png', fit: BoxFit.fitHeight, height: 300),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      // This takes all available space except what the button needs
                      child: SingleChildScrollView(
                        child: Text(result, style: const TextStyle(fontStyle: FontStyle.italic,fontSize: 14, color: Colors.black87)),
                      ),
                    ),
                    Padding(
                      // Replace SizedBox with Padding for better control
                      padding: const EdgeInsets.only(bottom: 12,left: 8,right: 8),
                      child: myButton(
                        context,
                        () async {
                          switch (widget.action) {
                            case TapCardAction.initialize:
                              initializeCard();
                              break;
                            case TapCardAction.format:
                              formatCard();
                              break;
                            case TapCardAction.viewUID:
                              viewUID(context);
                              break;
                            case TapCardAction.changePin:
                              changeCardPIN();
                              break;
                            case TapCardAction.cardDetails:
                              print("📡 Scanning card...");

                              try {
                                // 🟢 Start NFC polling
                                // ignore: unused_local_variable
                                final tag = await FlutterNfcKit.poll();

                                final nfc = NfcFunctions();
                                final response = await nfc.readSectorBlock(
                                  sectorIndex: 1,
                                  blockSectorIndex: 0,
                                  useDefaultKeys: false,
                                );

                                // 🛑 Stop polling when done (very important)
                                await FlutterNfcKit.finish();

                                if (response.status != NfcMessageStatus.success) {
                                  print("❌ Failed to read account number from card: ${response.data}");
                                  return;
                                }

                               final accountNo = response.data.replaceAll(RegExp(r'[^0-9]'), '');

                                print("🎯 Account number read from card: $accountNo");

                                final deviceId = '044ba7ee5cdd86c5'; // Eventually get from prefs

                                final details = await CustomerAccountDetailsService.fetchCustomerAccountDetails(
                                  accountNo: accountNo,
                                  deviceId: deviceId,
                                );

                                if (details == null) {
                                  print("❌ Could not fetch details.");
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CardDetailsPage(user: widget.user, details: details),
                                  ),
                                );
                              } catch (e) {
                                print("❌ Exception occurred: $e");
                                await FlutterNfcKit.finish(); // Make sure to always end session
                              }

                              break;
                          }
                        },
                        'TAP AGAIN !',
                        buttonTextStyle: const TextStyle(fontSize: 25, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
