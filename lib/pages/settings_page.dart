// ignore_for_file: avoid_print, unused_import

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:http/http.dart' as http;
import 'package:sahara_app/models/customer_account_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/initialize_card_service.dart';
import 'package:sahara_app/modules/nfc_functions.dart';
import 'package:sahara_app/pages/card_details_page.dart';
import 'package:sahara_app/pages/tap_card_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.user});
  final StaffListModel user;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum TapCardAction { initialize, format, viewUID, changePin, cardDetails }

class _SettingsPageState extends State<SettingsPage> {

    ///CHANGE PIN FUNCTION
  void handleChangePin() async {
    final pinData = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final oldPinController = TextEditingController();
        final newPinController = TextEditingController();
        final confirmPinController = TextEditingController();

        return AlertDialog(
          title: const Text('Change Card Pin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                myPinTextField(oldPinController, 'Current PIN', 'Enter current 4-digit PIN'),

                const SizedBox(height: 5),
                myPinTextField(newPinController, 'New PIN', 'Enter new 4-digit PIN'),

                const SizedBox(height: 5),
                myPinTextField(confirmPinController, 'Confirm New PIN', 'Re-enter new PIN'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
            ),
            TextButton(
              onPressed: () {
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
              child: Text('SUBMIT', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16)),
            ),
          ],
        );
      },
    );

    if (pinData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TapCardPage(
            user: widget.user,
            action: TapCardAction.changePin,
            extraData: pinData, // Pass the PINs to the next page
          ),
        ),
      );
    }
  }


    //CHECK NETWORK FOR INITIALIZATION
    // ignore: unused_element
    Future<bool> _checkInternetConnection() async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    
    // Check if connected to WiFi or Mobile data
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    return true;
  } catch (e) {
    return false;
  }
}

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
            builder: (context) => TapCardPage(user: widget.user, action: TapCardAction.cardDetails),
          ),
        );
      },
      'Initialize Card': () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TapCardPage(user: widget.user, action: TapCardAction.initialize),
          ),
        );
      },
      'Format Card': () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Card Formating'),
            content: const Text(
              'Formating will erase all the user data on the card.\n\n'
              'Are you sure you wish to proceed with formatting card?',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 18)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('PROCEED', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16)),
              ),
            ],
          ),
        );

        // Only proceed if confirmed
        if (confirmed == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TapCardPage(user: widget.user, action: TapCardAction.format),
            ),
          );
        }
      },

      'Card UID': () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TapCardPage(user: widget.user, action: TapCardAction.viewUID),
          ),
        );
      },
      'Change Card Pin': () => handleChangePin(),
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
        /**
         * 'Initialize Card': () async {
        bool hasInternet = await _checkInternetConnection();

        if (!hasInternet) {
          // Show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Check your internet connection', style: TextStyle(fontSize: 16))),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // Retry the initialization
                  _checkInternetConnection().then((hasNet) {
                    if (hasNet) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TapCardPage(user: widget.user, action: TapCardAction.initialize),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Still no internet connection'), backgroundColor: Colors.red),
                      );
                    }
                  });
                },
              ),
            ),
          );
          return;
        }

        // Internet available - proceed
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TapCardPage(user: widget.user, action: TapCardAction.initialize),
          ),
        );
      },
         */