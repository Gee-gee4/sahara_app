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
import 'package:sahara_app/modules/reprint_service.dart';
import 'package:sahara_app/modules/reverse_sale_service.dart';
import 'package:sahara_app/pages/card_details_page.dart';
import 'package:sahara_app/pages/reprint_receipt_page.dart';
import 'package:sahara_app/pages/tap_card_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

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
  cashCardSales,
  cardSales,
  miniStatement,
  topUp,
  reverseTopUp,
}

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
                myPinTextField(
                  controller: oldPinController,
                  myLabelText: 'Current PIN',
                  myHintText: 'Enter current 4-digit PIN',
                ),

                const SizedBox(height: 5),
                myPinTextField(
                  controller: newPinController,
                  myLabelText: 'New PIN',
                  myHintText: 'Enter new 4-digit PIN',
                ),

                const SizedBox(height: 5),
                myPinTextField(
                  controller: confirmPinController,
                  myLabelText: 'Confirm New PIN',
                  myHintText: 'Re-enter new PIN',
                ),
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

  //TRANSACTIONS FUNCS

  //REVERSE SALE
  //REVERSE SALE
  Future<void> showReverseSaleDialog(BuildContext context) async {
    final controllerReverseSale = TextEditingController();
    String? errorMessage;
    bool isLoading = false;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Reverse Sale'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  myPinTextField(
                    controller: controllerReverseSale,
                    myLabelText: 'Enter Receipt Id',
                    myHintText: '(e.g., TR5250815153110)',
                    keyboardType: TextInputType.text,
                    obscureText: false,
                    maxLength: 20,
                  ),
                  if (isLoading) ...[
                    SizedBox(height: 16),
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Reversing transaction...'),
                  ],
                  if (errorMessage != null) ...[
                    SizedBox(height: 8),
                    Text(errorMessage!, style: TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final receiptNumber = controllerReverseSale.text.trim();

                          if (receiptNumber.isEmpty) {
                            setState(() {
                              errorMessage = 'Please enter a receipt number';
                            });
                            return;
                          }

                          // Show confirmation dialog first
                          final shouldReverse = await _showConfirmationDialog(context, receiptNumber);
                          if (!shouldReverse) return;

                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            print('🔄 Reversing transaction: $receiptNumber');

                            final result = await ReverseSaleService.reverseTransaction(
                              originalRefNumber: receiptNumber,
                              user: widget.user, // Assuming this dialog is in a widget with user access
                            );

                            setState(() {
                              isLoading = false;
                            });

                            if (result['success']) {
                              Navigator.of(context).pop(); // Close dialog

                              // Show success message with details
                              _showSuccessDialog(context, result);
                            } else {
                              setState(() {
                                errorMessage = result['error'];
                              });
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              errorMessage = 'Error: $e';
                            });
                          }
                        },
                  child: Text('SUBMIT', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Confirmation dialog before reversing
  Future<bool> _showConfirmationDialog(BuildContext context, String receiptNumber) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirm Reversal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 48),
                  SizedBox(height: 16),
                  Text('Are you sure you want to reverse this transaction?'),
                  SizedBox(height: 8),
                  Text('Receipt: $receiptNumber', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Text('This action cannot be undone.', style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Reverse',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Success dialog showing reversal details
  void _showSuccessDialog(BuildContext context, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Reversal Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Transaction has been reversed successfully.'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    _infoRow('Original Receipt:', result['originalRefNumber']),
                    _infoRow('Reversal Receipt:', result['newRefNumber']),
                    _infoRow('Status:', 'Reversed'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close success dialog
              },
              child: Text('OK', style: TextStyle(color: ColorsUniversal.buttonsColor)),
            ),
          ],
        );
      },
    );
  }

  // Helper widget for info rows
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontFamily: 'Courier')),
        ],
      ),
    );
  }

  //REPRINT RECEIPT
  Future<void> showReceiptReprintDialog(BuildContext context) async {
    final controller = TextEditingController();
    // ignore: unused_local_variable
    String? errorMessage;
    bool isLoading = false;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // print(errorMessage);
            return AlertDialog(
              title: const Text('Receipt Reprint'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  myPinTextField(
                    controller: controller,
                    myLabelText: 'Enter Receipt Id',
                    myHintText: '(e.g., TR5250815153110)',
                    keyboardType: TextInputType.text,
                    obscureText: false,
                    maxLength: 20,
                  ),
                  // TextField(
                  //   controller: controller,
                  //   cursorColor: ColorsUniversal.buttonsColor,
                  //   decoration: InputDecoration(
                  //     labelText: 'Enter Receipt Id (e.g., TR5250815153110)',
                  //     labelStyle: TextStyle(color: Colors.brown[300]),
                  //     focusedBorder: UnderlineInputBorder(
                  //       borderSide: BorderSide(color: ColorsUniversal.buttonsColor)
                  //     ),
                  //     errorText: errorMessage,
                  //   ),
                  // ),
                  if (isLoading) ...[
                    SizedBox(height: 16),
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Fetching receipt...'),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final receiptNumber = controller.text.trim();

                          if (receiptNumber.isEmpty) {
                            setState(() {
                              errorMessage = 'Please enter a receipt number';
                            });
                            return;
                          }

                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            print('🔄 Fetching receipt: $receiptNumber');

                            final result = await ReprintService.getReceiptForReprint(
                              refNumber: receiptNumber,
                              user: widget.user,
                            );

                            setState(() {
                              isLoading = false;
                            });

                            if (result['success']) {
                              Navigator.of(context).pop(); // Close dialog

                              // Navigate to simple reprint page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReprintReceiptPage(
                                    user: widget.user,
                                    apiData: result['data'],
                                    refNumber: receiptNumber,
                                  ),
                                ),
                              );
                            } else {
                              setState(() {
                                errorMessage = result['error'];
                              });
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              errorMessage = 'Error: $e';
                            });
                          }
                        },
                  child: Text('SUBMIT', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  ///TOPUP TRANSACTION
  ///TOPUP TRANSACTION
Future<void> showTopUpTransactionDialog(BuildContext context) async {
  final controller = TextEditingController();
  String? errorMessage;

  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Topup Account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                myPinTextField(
                  controller: controller,
                  myLabelText: 'Enter TopUp Amount',
                  myHintText: 'Amount (e.g., 1000)',
                  keyboardType: TextInputType.number,
                  obscureText: false,
                  maxLength: 20,
                ),
                if (errorMessage != null) ...[
                  SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
              ),
              TextButton(
                onPressed: () {
                  final amountText = controller.text.trim();
                  
                  if (amountText.isEmpty) {
                    setState(() {
                      errorMessage = 'Please enter an amount';
                    });
                    return;
                  }
                  
                  final amount = double.tryParse(amountText);
                  if (amount == null || amount <= 0) {
                    setState(() {
                      errorMessage = 'Please enter a valid amount';
                    });
                    return;
                  }
                  
                  if (amount < 10) {
                    setState(() {
                      errorMessage = 'Minimum top-up amount is Ksh 10';
                    });
                    return;
                  }

                  // Amount is valid, navigate to card scanning
                  Navigator.pop(context); // Close dialog
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TapCardPage(
                        user: widget.user, 
                        action: TapCardAction.topUp,
                        topUpAmount: amount, // PASS THE AMOUNT
                      ),
                    ),
                  );
                },
                child: Text('SUBMIT', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16)),
              ),
            ],
          );
        },
      );
    },
  );
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

    //CARD ONPRESSED
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

    //TRANSACTION ONPRESSED

    final Map<String, VoidCallback> transactionItemActions = {
      'Ministatement': () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TapCardPage(user: widget.user, action: TapCardAction.miniStatement),
          ),
        );
      },
      'Top Up': () => showTopUpTransactionDialog(context),
      'Reverse Top Up': () {},
      'Re-Print Sale': () => showReceiptReprintDialog(context),
      'Reverse Sale': () => showReverseSaleDialog(context),
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
                  onTap: transactionItemActions[item],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
