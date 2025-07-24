// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
  const TapCardPage({super.key, required this.user, required this.action, this.extraData});
  final StaffListModel user;
  final TapCardAction action;
  final Map<String, String>? extraData;

  @override
  State<TapCardPage> createState() => _TapCardPageState();
}

class _TapCardPageState extends State<TapCardPage> {

void showLoadingSpinner(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: SpinKitCircle(
        size: 70,
        duration: Duration(milliseconds: 1000),
        itemBuilder: (context, index) {
          final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
          return DecoratedBox(
            decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle),
          );
        },
      ),
    ),
  );
}

  bool isProcessing = false;
  String result = '';
  @override
  void initState() {
    super.initState();
    switch (widget.action) {
      case TapCardAction.initialize:
        result = "Initialize card";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          initializeCard();
        });
        break;
      case TapCardAction.format:
        result = "Formatting card...";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          formatCard(); //  auto-run like _autoViewUID
        });
        break;
      case TapCardAction.viewUID:
        result = "Card UID";
        // Auto-start UID scanning with timeout
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoViewUID(context);
        });

        break;
      case TapCardAction.changePin:
        result = "Change card PIN";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          changeCardPIN(); // Auto-start change PIN
        });
        break;

      case TapCardAction.cardDetails:
        result = "Card details";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleCardDetails(context); //  Auto-start card details scan
        });
        break;
    }
  }

  /// I N I T I A L I Z E  C A R D

  Future<void> initializeCard() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      result = "Starting initialization...";
    });

    final nfc = NfcFunctions();
    showLoadingSpinner(context);

    try {
      setState(() => result = "📱 Waiting for card...\nPlace your card on the phone");

      // Step 1: Poll for card
      final tag = await FlutterNfcKit.poll();
      if (tag.type != NFCTagType.mifare_classic) {
        setState(() {
          result = "❌ Not a MIFARE Classic card";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      final rawUID = tag.id;
      final convertedUID = UIDConverter.convertToPOSFormat(rawUID);

      // Step 2: CHECK IF CARD IS ALREADY INITIALIZED
      setState(() => result = "🔍 Checking if card is already initialized...");

      try {
        // Try to read initialization flag with POS keys
        final initStatusResult = await nfc.readSectorBlock(
          sectorIndex: 2,
          blockSectorIndex: 2,
          useDefaultKeys: false, // Use POS keys
        );

        if (initStatusResult.status == NfcMessageStatus.success && initStatusResult.data.trim().startsWith('1')) {
          // Card is already initialized! Read existing data
          final accountResult = await nfc.readSectorBlock(sectorIndex: 1, blockSectorIndex: 0, useDefaultKeys: false);

          final pinResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

          await FlutterNfcKit.finish();

          // Extract data
          String accountNumber = accountResult.data.replaceAll(';', '').trim();
          String pin = pinResult.data.replaceAll(';', '').trim();

          // Fetch customer details for this account
          final imei = 'd66e5cf98b2ae46c';
          final staffId = widget.user.staffId;

          final accountData = await InitializeCardService.fetchCardData(
            cardUID: convertedUID,
            imei: imei,
            staffID: staffId,
          );

          setState(() {
            result =
                "⚠️ Card Already Initialized!\n\n"
                "📱 Card UID: $convertedUID\n"
                "🏦 Account: $accountNumber\n"
                "👤 Customer: ${accountData?.customerName ?? 'Unknown'}\n"
                "📞 Phone: ${accountData?.customerPhone ?? 'N/A'}\n"
                "🔐 PIN: $pin\n"
                "✅ Status: Already Active\n\n"
                "This card is already assigned and initialized.";
            isProcessing = false;
          });

          // Show dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('Card Already Initialized', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              content: Text(
                'Account: $accountNumber\n'
                'Customer: ${accountData?.customerName ?? 'Unknown'}\n',
                // 'Phone: ${accountData?.customerPhone ?? 'N/A'}\n\n',
                style: TextStyle(fontSize: 17),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); //pop the dialog
                    Navigator.of(context).pop(); //pop the page
                  },
                  child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
                ),
              ],
            ),
          );
          return; // STOP - Do not proceed with initialization
        }
      } catch (e) {
        // Reading with POS keys failed - card is probably not initialized
        print("📝 Card not initialized yet (POS key read failed): $e");
      }

      // Step 3: Card is not initialized, proceed with normal flow
      setState(() => result = "✅ Card is blank - ready for initialization\n\n🔍 Checking account assignment...");

      final imei = 'd66e5cf98b2ae46c';
      final staffId = widget.user.staffId;

      // Fetch account data
      final accountData = await InitializeCardService.fetchCardData(
        cardUID: convertedUID,
        imei: imei,
        staffID: staffId,
      );

      // Check if account exists
      if (accountData == null ||
          // ignore: unnecessary_null_comparison
          accountData.customerAccountNumber == null ||
          accountData.customerAccountNumber == 0 ||
          accountData.customerAccountNumber.toString().isEmpty) {
        await FlutterNfcKit.finish();

        setState(() {
          result =
              "❌ No valid account found for this card.\n\n"
              "📱 App UID: $rawUID\n"
              "🏪 POS UID: $convertedUID\n"
              "🏦 Account Number: ${accountData?.customerAccountNumber ?? 'null'}\n\n"
              "Please assign this card to a valid account first.";
          isProcessing = false;
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Failed'),
            content: const Text('Could not find the associated account number', style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); //Pop the dialog
                  Navigator.of(context).pop(); //Pop the page
                },
                child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
        return;
      }

      // Account found! End current session and get PIN
      await FlutterNfcKit.finish();

      setState(
        () => result =
            "✅ Account found: ${accountData.customerAccountNumber}\n\n👤 Customer: ${accountData.customerName}\n\n🔐 Please set a PIN for this card...",
      );

      String? pin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Set Pin'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Setting Pin for:', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Customer Name: ${accountData.customerName}\nAccount: ${accountData.customerAccountNumber}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter 4-digit Pin',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); //pop dialog
                  Navigator.of(context).pop(); //pop page
                },
                child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: Text('Set PIN', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          );
        },
      );

      if (pin == null || pin.length != 4) {
        setState(() {
          result = "❌ PIN setup cancelled or invalid";
          isProcessing = false;
        });
        return;
      }

      // Start new session for writing
      setState(() => result = "📱 Ready to write data...\nPlace your card on the phone again");

      final tag2 = await FlutterNfcKit.poll();
      if (tag2.type != NFCTagType.mifare_classic) {
        setState(() {
          result = "❌ Not a MIFARE Classic card";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      final rawUID2 = tag2.id;
      if (rawUID2 != rawUID) {
        setState(() {
          result = "⚠️ Different card detected!\n\nOriginal: $rawUID\nCurrent: $rawUID2\n\nPlease use the same card.";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      // Proceed with writing data
      setState(() => result = "📝 Initializing card with account ${accountData.customerAccountNumber}...");

      final accountNo = accountData.customerAccountNumber.toString();
      print("📝 Writing account number: $accountNo");

      final result1 = await nfc.writeSectorBlock(
        sectorIndex: 1,
        blockSectorIndex: 0,
        data: '$accountNo;',
        useDefaultKeys: true,
      );

      if (result1.status != NfcMessageStatus.success) {
        throw Exception("Failed to write account number: ${result1.data}");
      }

      print("📝 Writing PIN: $pin");
      final result2 = await nfc.writeSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        data: '$pin;',
        useDefaultKeys: true,
      );

      if (result2.status != NfcMessageStatus.success) {
        throw Exception("Failed to write PIN: ${result2.data}");
      }

      print("📝 Writing max attempts: 3");
      final result3 = await nfc.writeSectorBlock(sectorIndex: 2, blockSectorIndex: 1, data: '3;', useDefaultKeys: true);

      if (result3.status != NfcMessageStatus.success) {
        throw Exception("Failed to write lock count: ${result3.data}");
      }

      print("📝 Writing init flag: 1");
      final result4 = await nfc.writeSectorBlock(sectorIndex: 2, blockSectorIndex: 2, data: '1;', useDefaultKeys: true);

      if (result4.status != NfcMessageStatus.success) {
        throw Exception("Failed to write init status: ${result4.data}");
      }

      print("🔐 Changing keys to POS keys...");
      final changeKey1 = await nfc.changeKeys(sectorIndex: 1, fromDefault: true);
      if (changeKey1.status != NfcMessageStatus.success) {
        throw Exception("Failed to change keys for sector 1: ${changeKey1.data}");
      }

      final changeKey2 = await nfc.changeKeys(sectorIndex: 2, fromDefault: true);
      if (changeKey2.status != NfcMessageStatus.success) {
        throw Exception("Failed to change keys for sector 2: ${changeKey2.data}");
      }

      setState(() => result = "📡 Completing initialization in portal...");

      final completed = await CompleteCardInitService.completeInitializeCard(
        uid: convertedUID,
        accountNo: accountData.customerAccountNumber,
        staffId: staffId,
      );

      await FlutterNfcKit.finish();

      setState(() {
        result =
            '''✅ Card initialized successfully!
${completed ? '✅ Portal updated successfully!' : '⚠️ Portal update failed (card still works)'}

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
🏪 POS UID: $convertedUID''';
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
  if (isProcessing || !mounted) return;

  setState(() => isProcessing = true);
  showLoadingSpinner(context);

  try {
    // Wait for card scan or timeout
    final scanResult = await Future.any([
      FlutterNfcKit.poll().then((tag) => {'type': 'success', 'data': tag}),
      Future.delayed(Duration(seconds: 30)).then((_) => {'type': 'timeout'}),
    ]);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close spinner

    if (scanResult['type'] == 'timeout') {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Timeout"),
          content: Text("⏱️ No card detected. Please try again."),
        ),
      );
      setState(() => isProcessing = false);
      return;
    }

    final tag = scanResult['data'] as NFCTag;
    final rawUID = tag.id;

    if (tag.type != NFCTagType.mifare_classic) {
      await FlutterNfcKit.finish();
      setState(() => isProcessing = false);
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Invalid Card"),
          content: Text("❌ Not a MIFARE Classic card."),
        ),
      );
      return;
    }

    final nfc = NfcFunctions();
    List<String> formatResults = [];

    for (int sector in [1, 2]) {
      bool formatted = false;
      try {
        final res = await nfc.formatSector(sectorIndex: sector, useDefaultKeys: false);
        if (res.status == NfcMessageStatus.success) {
          formatResults.add("✅ Sector $sector: ${res.data}");
          formatted = true;
        }
      } catch (_) {}

      if (!formatted) {
        try {
          final res = await nfc.formatSector(sectorIndex: sector, useDefaultKeys: true);
          if (res.status == NfcMessageStatus.success) {
            formatResults.add("✅ Sector $sector: ${res.data}");
          } else {
            formatResults.add("❌ Sector $sector: ${res.data}");
          }
        } catch (e) {
          formatResults.add("❌ Sector $sector: Error - $e");
        }
      }
    }

    await FlutterNfcKit.finish();

    final convertedUID = UIDConverter.convertToPOSFormat(rawUID);
    final staffId = widget.user.staffId;
    final apiSuccess = await InitializeCardService.formatCardAPI(
      cardUID: convertedUID,
      staffId: staffId,
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Format Complete"),
        content: Text('''
${formatResults.join('\n')}

🔓 All keys reset to default (FF FF FF FF FF FF)
💳 Card ready for new assignment

${apiSuccess ? '✅ Portal: Card unassigned successfully' : '⚠️ Portal: Unassignment failed (card still formatted)'}
        '''),
      ),
    );
  } on PlatformException catch (e) {
    if (mounted) Navigator.of(context).pop();
    await FlutterNfcKit.finish();

    // Handle NFC timeout or other platform exceptions
    if (e.code == '408') {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Timeout"),
          content: Text("⏱️ No card detected. Please try again."),
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Format Failed"),
          content: Text("❌ Format failed:\n${e.message ?? e.toString()}"),
        ),
      );
    }
  } catch (e) {
    if (mounted) Navigator.of(context).pop();
    await FlutterNfcKit.finish();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Format Failed"),
        content: Text("❌ Unexpected error:\n$e"),
      ),
    );
  } finally {
    if (mounted) setState(() => isProcessing = false);
  }
}


  //CHANGE PIN
  //CHANGE CARD PIN
  Future<void> changeCardPIN() async {
    if (isProcessing) return;

    final pinData = widget.extraData;
    if (pinData == null) {
      setState(() {
        result = "❌ No PIN data provided";
        isProcessing = false;
      });
      return;
    }

    setState(() {
      isProcessing = true;
      result = "🔐 Preparing to change PIN...";
    });

    try {
      // Show loading spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: SpinKitCircle(
            size: 70,
            duration: Duration(milliseconds: 1000),
            itemBuilder: (context, index) {
              final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
              return DecoratedBox(
                decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle),
              );
            },
          ),
        ),
      );

      final tagScan = FlutterNfcKit.poll();
      final timeout = Future.delayed(Duration(seconds: 30));
      final scanResult = await Future.any([
        tagScan.then((tag) => {'type': 'success', 'tag': tag}),
        timeout.then((_) => {'type': 'timeout'}),
      ]);

      Navigator.of(context).pop(); // Close loading

      if (scanResult['type'] == 'timeout') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              const AlertDialog(title: Text("Timeout"), content: Text("⏱️ No card detected. Please try again.")),
        );
        setState(() => isProcessing = false);
        return;
      }

      final tag = scanResult['tag'] as NFCTag;

      if (tag.type != NFCTagType.mifare_classic) {
        await FlutterNfcKit.finish();
        setState(() {
          result = "❌ Not a MIFARE Classic card";
          isProcessing = false;
        });
        return;
      }

      final nfc = NfcFunctions();

      setState(() => result = "🔍 Verifying current PIN...");

      final currentPinResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

      if (currentPinResult.status != NfcMessageStatus.success) {
        throw Exception("Failed to read current PIN: ${currentPinResult.data}");
      }

      final storedPin = currentPinResult.data.replaceAll(';', '').trim();
      final oldPin = pinData['oldPin']!;
      final newPin = pinData['newPin']!;

      if (storedPin != oldPin) {
        await FlutterNfcKit.finish();
        setState(() {
          result = "❌ Incorrect current PIN.\nStored: $storedPin\nEntered: $oldPin";
          isProcessing = false;
        });
        return;
      }

      setState(() => result = "✅ Verified! Writing new PIN...");

      final writeResult = await nfc.writeSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        data: '$newPin;',
        useDefaultKeys: false,
      );

      if (writeResult.status != NfcMessageStatus.success) {
        throw Exception("Failed to write new PIN: ${writeResult.data}");
      }

      final verifyResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

      final verifiedPin = verifyResult.data.replaceAll(';', '').trim();
      await FlutterNfcKit.finish();

      setState(() {
        result =
            '''
✅ PIN Changed Successfully!

📊 Details:
• Old PIN: $oldPin
• New PIN: $newPin
• Verified: $verifiedPin
''';
        isProcessing = false;
      });
    } catch (e) {
      await FlutterNfcKit.finish();
      setState(() {
        result = "❌ PIN change failed: $e";
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
          barrierDismissible: false,
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
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: Text("Failed to read card uid"),
            //Text("Failed to read card: $e"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); //pop the dialog
                  Navigator.of(context).pop(); //pop the page
                },
                child: Text("OK", style: TextStyle(fontSize: 20, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
      }
    }
  }

  void _autoViewUID(BuildContext context) async {
    try {
      // Show scanning dialog
      showDialog(
        context: context,
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

      // Create timeout
      final cardScanFuture = FlutterNfcKit.poll();
      final timeoutFuture = Future.delayed(const Duration(seconds: 30));

      final scanResult = await Future.any([
        cardScanFuture.then((tag) => {'type': 'success', 'data': tag}),
        timeoutFuture.then((_) => {'type': 'timeout'}),
      ]);

      // Close scanning dialog
      if (context.mounted) Navigator.of(context).pop();

      if (scanResult['type'] == 'timeout') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
            title: Text("Timeout"),
            content: Text("⏱️ Scan timeout\nTap the button below to try again"),
          ),
        );
        return;
      }

      final tag = scanResult['data'] as NFCTag;
      final appUID = tag.id;
      final posUID = UIDConverter.convertToPOSFormat(appUID);

      await FlutterNfcKit.finish();

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
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
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pop(); // Close the page
                },
                child: Text("OK", style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // close any open scanning dialog

      await FlutterNfcKit.finish();

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: Text("Error reading card"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); //pop the dialog
                  Navigator.of(context).pop(); //pop the page
                },
                child: Text("OK", style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
        print('❌ Error reading card: $e');
      }
    }
  }

  /// C A R D  D E T A I L S
  Future<void> _handleCardDetails(BuildContext context) async {
    print("📡 Scanning card for details...");

    try {
      // Step 1: Start NFC polling
      showDialog(
        context: context,
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

      // ignore: unused_local_variable
     NFCTag tag;
      try {
        tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 20));
      } catch (e) {
        await FlutterNfcKit.finish(); // Stop NFC session

        if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // Hide spinner

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Card Not Detected"),
            content: const Text("No card was detected within 20 seconds. Please try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Pop page
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );

        return;
      }
      final nfc = NfcFunctions();

      // Step 2: Read account number from card
      final accountResponse = await nfc.readSectorBlock(
        sectorIndex: 1,
        blockSectorIndex: 0,
        useDefaultKeys: false, // Use POS keys
      );

      if (accountResponse.status != NfcMessageStatus.success) {
        await FlutterNfcKit.finish();
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close spinner
          Navigator.of(context).pop(); // Close current page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read card data. Please try again.'),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 2),
            ),
          );
        }
        print("❌ Failed to read account number: ${accountResponse.data}");
        return;
      }

      // Step 3: Read PIN from card for validation
      final pinResponse = await nfc.readSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        useDefaultKeys: false, // Use POS keys
      );

      await FlutterNfcKit.finish(); // End NFC session

      if (pinResponse.status != NfcMessageStatus.success) {
        if (context.mounted) Navigator.pop(context); // ❌ Dismiss spinner
        print("❌ Failed to read PIN from card: ${pinResponse.data}");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card PIN. Card may not be initialized.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Step 4: Extract and validate account number
      final accountNo = accountResponse.data.replaceAll(RegExp(r'[^0-9]'), '');
      final cardPin = pinResponse.data.replaceAll(';', '').trim();

      print("🎯 Account number from card: $accountNo");
      print("🔐 PIN from card: $cardPin");

      if (accountNo.isEmpty || accountNo == '0') {
        if (context.mounted) Navigator.pop(context); // ❌ Dismiss spinner
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No assigned account found on this card.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Step 5: Prompt user for PIN and validate
      final pinValid = await _showPinDialog(context, accountNo, cardPin);

      if (!pinValid) {
        if (context.mounted) Navigator.pop(context); // ❌ Dismiss spinner
        print("❌ PIN validation failed or was cancelled");
        return;
      }

      // Step 6: PIN is correct! Fetch customer details
      print("✅ PIN verified successfully");

      // Show loading state
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
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

      final deviceId = '044ba7ee5cdd86c5'; // Eventually get from prefs

      final details = await CustomerAccountDetailsService.fetchCustomerAccountDetails(
        accountNo: accountNo,
        deviceId: deviceId,
      );

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Step 7: Check if details were found
      if (details == null) {
        print("❌ No details found for account: $accountNo");

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Details Found'),
            content: Text(
              'Could not find customer details for account: $accountNo\n\n'
              'The account may not exist in the system or there may be a connection issue.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Step 8: Success! Navigate to details page
      print("✅ Customer details fetched successfully");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardDetailsPage(user: widget.user, details: details),
        ),
      );
    } catch (e) {
      await FlutterNfcKit.finish(); // Always end NFC session
      if (context.mounted) Navigator.pop(context); // ❌ Dismiss spinner on error

      print("❌ Exception occurred: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred'), backgroundColor: Colors.grey, duration: const Duration(seconds: 2)),
      );
    }
  }

  /// DETAILS PIN DIALOG
  Future<bool> _showPinDialog(BuildContext context, String accountNo, String correctPin) async {
    bool pinVerified = false;

    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final pinController = TextEditingController();
        return AlertDialog(
          title: const Text('Enter PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account: $accountNo', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                  // prefixIcon: Icon(Icons.lock),
                ),
                autofocus: true,
                cursorColor: ColorsUniversal.buttonsColor,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
            ),
            TextButton(
              onPressed: () {
                String pin = pinController.text;
                if (pin.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('PIN cannot be empty'), backgroundColor: Colors.grey));
                  return;
                }
                if (pin.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN must be exactly 4 digits'), backgroundColor: Colors.grey),
                  );
                  return;
                }
                if (pin != correctPin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Wrong PIN. Try again.'),
                      backgroundColor: Colors.grey,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return; // Keep dialog open
                }
                pinVerified = true;
                Navigator.of(context).pop();
              },
              child: Text('SUBMIT', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 18)),
            ),
          ],
        );
      },
    );

    return pinVerified;
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
                        child: Text(
                          result,
                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
                      child: myButton(
                        context,
                        () async {
                          switch (widget.action) {
                            case TapCardAction.initialize:
                              initializeCard();
                              break;
                            case TapCardAction.format:
                              isProcessing ? null : formatCard();
                              break;
                            case TapCardAction.viewUID:
                              if (result.contains("timeout") || result.contains("Error")) {
                                // If there was a timeout or error, try again
                                _autoViewUID(context);
                              } else {
                                // If successful, show the dialog version
                                viewUID(context);
                              }
                              break;
                            case TapCardAction.changePin:
                              isProcessing ? null : changeCardPIN();
                              break;
                            case TapCardAction.cardDetails:
                              await _handleCardDetails(context);
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
