// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/initialize_card_service.dart';
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

class _TapCardPageState extends State<TapCardPage> {
  @override
  void initState() {
    super.initState();
    switch (widget.action) {
      case TapCardAction.initialize:
        scanAndCheckCard();
        break;
      case TapCardAction.format:
        // formatCard();
        break;
      case TapCardAction.viewUID:
        // viewUID();
        break;
      case TapCardAction.changePin:
        // changePinFlow();
        break;
      case TapCardAction.cardDetails:
        // fetchCardDetails();
        break;
    }
  }

  String status = "Tap card to begin";
  Future<void> scanAndCheckCard() async {
    setState(() => status = "🔍 Scanning card...");

    try {
      // 1. Poll for NFC tag
      final tag = await FlutterNfcKit.poll();
      final rawUID = tag.id;
      final imei = 'd66e5cf98b2ae46c';
      final staffId = widget.user.staffId;

      // 2. Convert UID to POS format
      final convertedUID = UIDConverter.convertToPOSFormat(rawUID);

      // Debug both formats
      UIDConverter.debugUID(rawUID);

      setState(() => status = "📡 Fetching assigned account for UID: $convertedUID");

      // 3. Fetch account info using converted UID
      final data = await InitializeCardService.fetchCardData(
        cardUID: convertedUID, // Use converted UID
        imei: imei,
        staffID: staffId,
      );

      if (data != null) {
        setState(() {
          status =
              '''
✅ Card Assigned To:
👤 Name: ${data.customerName}
📞 Phone: ${data.customerPhone}
📧 Email: ${data.customerEmail}
🏦 Account: ${data.customerAccountNumber}
💳 Type: ${data.accountCreditTypeName}

🔧 Debug Info:
📱 App UID: $rawUID
🏪 POS UID: $convertedUID
''';
        });
        print(' Name: ${data.customerName},');
        print('Phone: ${data.customerPhone},');
        print(' Email: ${data.customerEmail}');
        print(' Account: ${data.customerAccountNumber}');
        print(' Type: ${data.accountCreditTypeName}');
       
      } else {
        setState(
          () => status =
              "❌ No account assigned or card not recognized.\n\n🔧 Debug:\n📱 App UID: $rawUID\n🏪 POS UID: $convertedUID",
        );
      }
    } catch (e) {
      setState(() => status = "❌ Error: $e");
    } finally {
      await FlutterNfcKit.finish();
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: myButton(
                      context,
                      () {},
                      'TAP AGAIN !',
                      buttonTextStyle: TextStyle(fontSize: 25, color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UIDConverter {
  /// Converts UID from app format (big-endian hex) to POS format (little-endian decimal)
  static String convertToPOSFormat(String appUID) {
    try {
      // Remove any spaces and convert to uppercase
      String cleaned = appUID.replaceAll(' ', '').toUpperCase();

      // Ensure even length by padding with 0 if needed
      if (cleaned.length % 2 != 0) {
        cleaned = '0$cleaned';
      }

      // Split into byte pairs and reverse the order
      List<String> bytes = [];
      for (int i = 0; i < cleaned.length; i += 2) {
        bytes.add(cleaned.substring(i, i + 2));
      }

      // Reverse byte order (big-endian to little-endian)
      String reversedHex = bytes.reversed.join('');

      // Convert to decimal
      int decimal = int.parse(reversedHex, radix: 16);

      return decimal.toString();
    } catch (e) {
      print('Error converting UID: $e');
      return appUID; // Return original if conversion fails
    }
  }

  /// For debugging - shows both formats
  static void debugUID(String appUID) {
    String posFormat = convertToPOSFormat(appUID);
    print('🔍 UID Conversion:');
    print('   App format (hex): $appUID');
    print('   POS format (decimal): $posFormat');
  }
}
