import 'package:flutter/material.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> cardItems = [
      'Card Details',
      'Initialize Card',
      'Format Corrupted Card',
      'Card UID',
      'Change Card Pin',
    ];
    final List<String> transactionItems = [
      'Ministatement',
      'Top Up',
      'Reverse Top Up',
      'Re-Print Sale',
      'Reverse Sale',
    ];

    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView(
          children: [
            Text(
              'Card',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            ...cardItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Text(item, style: TextStyle(fontSize: 16)),
                  tileColor: Colors.brown[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Transactions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            ...transactionItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: Text(item, style: TextStyle(fontSize: 16)),
                  tileColor: Colors.brown[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
