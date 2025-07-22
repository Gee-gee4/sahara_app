// ignore_for_file: avoid_print, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/initialize_card_service.dart';
import 'package:sahara_app/pages/tap_card_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.user});
  final StaffListModel user;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum TapCardAction {
  initialize,
  format,
  viewUID,
  changePin,
  cardDetails,
}

class _SettingsPageState extends State<SettingsPage> {
 

  @override
  Widget build(BuildContext context) {
    final List<String> cardItems = ['Card Details', 'Initialize Card', 'Format Card', 'Card UID', 'Change Card Pin'];
    final List<String> transactionItems = [
      'Ministatement',
      'Top Up',
      'Reverse Top Up',
      'Re-Print Sale',
      'Reverse Sale',
    ];

    final Map<String, VoidCallback> cardItemActions = {
  'Card Details': () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TapCardPage(
          user: widget.user,
          action: TapCardAction.cardDetails,
        ),
      ),
    );
  },
  'Initialize Card': () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TapCardPage(
          user: widget.user,
          action: TapCardAction.initialize,
        ),
      ),
    );
  },
  'Format Card': () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TapCardPage(
          user: widget.user,
          action: TapCardAction.format,
        ),
      ),
    );
  },
  'Card UID': () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TapCardPage(
          user: widget.user,
          action: TapCardAction.viewUID,
        ),
      ),
    );
  },
  'Change Card Pin': () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TapCardPage(
          user: widget.user,
          action: TapCardAction.changePin,
        ),
      ),
    );
  },
};


    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView(
          children: [
            Text('Card', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            ...cardItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Text(item, style: TextStyle(fontSize: 16)),
                  tileColor: Colors.brown[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: cardItemActions[item],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            ...transactionItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: Text(item, style: TextStyle(fontSize: 16)),
                  tileColor: Colors.brown[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
