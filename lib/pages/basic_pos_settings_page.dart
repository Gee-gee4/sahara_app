// lib/pages/basic_pos_settings_page.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/pages/pos_settings_form.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class BasicPosSettingsPage extends StatefulWidget {
  const BasicPosSettingsPage({super.key});

  @override
  State<BasicPosSettingsPage> createState() => _BasicPosSettingsPageState();
}

class _BasicPosSettingsPageState extends State<BasicPosSettingsPage> {
  ReceiptNumber _receipt = ReceiptNumber.single;
  bool _printPolicies = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _receipt = (prefs.getInt('receiptCount') ?? 1) == 2 
          ? ReceiptNumber.double 
          : ReceiptNumber.single;
      _printPolicies = prefs.getBool('printPolicies') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('receiptCount', _receipt == ReceiptNumber.single ? 1 : 2);
      await prefs.setBool('printPolicies', _printPolicies);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: hexToColor('8f9c68'),
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings'),
          backgroundColor: Colors.grey,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: myAppBar('Pos Settings'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Number of Receipts', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            
            RadioListTile(
              activeColor: ColorsUniversal.buttonsColor,
              tileColor: Colors.brown[100],
              title: Text('Single'),
              value: ReceiptNumber.single,
              groupValue: _receipt,
              onChanged: (value) => setState(() => _receipt = value!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            
            SizedBox(height: 8),
            
            RadioListTile(
              activeColor: ColorsUniversal.buttonsColor,
              tileColor: Colors.brown[100],
              title: Text('Double'),
              value: ReceiptNumber.double,
              groupValue: _receipt,
              onChanged: (value) => setState(() => _receipt = value!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            
            SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Print Policies', style: TextStyle(fontSize: 16)),
                Switch(
                  activeColor: ColorsUniversal.appBarColor,
                  value: _printPolicies,
                  onChanged: (value) => setState(() => _printPolicies = value),
                ),
              ],
            ),
            
            Spacer(),
            
            Spacer(),
            
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 55.0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsUniversal.buttonsColor,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _isLoading ? null : _saveSettings,
                child: _isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('Saving...', style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : Text(
                        'SAVE SETTINGS',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}