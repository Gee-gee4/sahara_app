import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/device_validator.dart';
import 'package:sahara_app/helpers/dummy_validator.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
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

              final deviceId = await getDeviceId();
              final isAllowed = await DummyValidator.isDeviceAllowed(deviceId);

              if (isAllowed) {
                final prefs = await SharedPreferences.getInstance();
                final channel = prefs.getString('channel') ?? 'Station';

                showDialog(
                  // ignore: use_build_context_synchronously
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: ColorsUniversal.background,
                    title: Text('${channel.toUpperCase()} Station'),
                    // content: Text('$channel station found. Proceed?'),
                    actions: [
                      TextButton(
                        child: Text(
                          'OK',
                          style: TextStyle(color: Colors.brown[800], fontSize: 17),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => UsersPage()),
                          );
                        },
                      ),
                    ],
                  ),
                );
              } else {
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
                        child: Text('OK',style: TextStyle(color: Colors.brown[800], fontSize: 17),),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              }
            }, 'NEXT'),
          ],
        ),
      ),
    );
  }
}
