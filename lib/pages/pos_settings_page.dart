import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/pages/users_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

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
            const Text(
              'Select Operation Mode',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
            RadioListTile<OperationMode>(
              activeColor: ColorsUniversal.buttonsColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(20),
              ),
              tileColor: ColorsUniversal.fillWids,
              title: const Text('Manual'),
              value: OperationMode.manual,
              groupValue: _mode,
              onChanged: (value) {
                setState(() {
                  _mode = value!;
                });
              },
            ),
            SizedBox(height: 12),
            RadioListTile<OperationMode>(
              activeColor: ColorsUniversal.buttonsColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(20),
              ),
              tileColor: ColorsUniversal.fillWids,
              title: const Text('Auto'),
              value: OperationMode.auto,
              groupValue: _mode,
              onChanged: (value) {
                setState(() {
                  _mode = value!;
                });
              },
            ),
            SizedBox(height: 12),
            Text(
              'Number of Receipts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
            RadioListTile<ReceiptNumber>(
              activeColor: ColorsUniversal.buttonsColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(20),
              ),
              tileColor: ColorsUniversal.fillWids,
              title: const Text('Single'),
              value: ReceiptNumber.single,
              groupValue: _receipt,
              onChanged: (value) {
                setState(() {
                  _receipt = value!;
                });
              },
            ),
            SizedBox(height: 12),
            RadioListTile<ReceiptNumber>(
              activeColor: ColorsUniversal.buttonsColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(20),
              ),
              tileColor: ColorsUniversal.fillWids,
              title: const Text('Double'),
              value: ReceiptNumber.double,
              groupValue: _receipt,
              onChanged: (value) {
                setState(() {
                  _receipt = value!;
                });
              },
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Print Policies',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                ),
                Switch(
                  activeColor: ColorsUniversal.appBarColor,
                  value: _printPolicies,
                  onChanged: (value) {
                    setState(() {
                      _printPolicies = value;
                    });
                  },
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: myButton(context, () async {
                    final modeString = _mode == OperationMode.manual
                        ? 'manual'
                        : 'auto';
                    final receiptCount = _receipt == ReceiptNumber.single ? 1 : 2;

                    await SharedPrefsHelper.savePosSettings(
                      mode: modeString,
                      receiptCount: receiptCount,
                      printPolicies: _printPolicies,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UsersPage()),
                    );
                  }, 'NEXT'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
