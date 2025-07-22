import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/initialize_card_service.dart';

class CardAssignmentChecker extends StatefulWidget {
   final StaffListModel user;
  const CardAssignmentChecker({super.key, required this.user});

  @override
  State<CardAssignmentChecker> createState() => _CardAssignmentCheckerState();
}

class _CardAssignmentCheckerState extends State<CardAssignmentChecker> {
  String status = "Tap card to begin";

  Future<void> scanAndCheckCard() async {
    setState(() => status = "🔍 Scanning card...");

    try {
      // 1. Poll for NFC tag
      final tag = await FlutterNfcKit.poll();
      final uid = tag.id;
      final imei = 'd66e5cf98b2ae46c';
      final staffId = widget.user.staffId;

      setState(() => status = "📡 Fetching assigned account for UID: $uid");

      // 2. Fetch account info assigned to card
      final data = await InitializeCardService.fetchCardData(
        cardUID: uid,
        imei: imei,
        staffID: staffId,
      );

      if (data != null) {
        setState(() {
          status = '''
✅ Card Assigned To:
👤 Name: ${data.customerName}
📞 Phone: ${data.customerPhone}
📧 Email: ${data.customerEmail}
🏦 Account: ${data.customerAccountNumber}
💳 Type: ${data.accountCreditTypeName}
''';
        });
      } else {
        setState(() => status = "❌ No account assigned or card not recognized.");
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
      appBar: AppBar(title: const Text('Check Card Assignment')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(status, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: scanAndCheckCard,
                child: const Text("📲 Scan Card"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
