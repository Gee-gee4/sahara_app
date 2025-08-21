import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../utils/colors_universal.dart';
import '../../utils/color_hex.dart';

abstract class NFCBaseService {
  // Common loading spinner
  static void showLoadingSpinner(BuildContext context) {
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

  // Common error dialog
  static Future<void> showErrorDialog(
    BuildContext context, 
    String title, 
    String message, {
    bool popPage = true,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Pop dialog
              if (popPage && context.mounted) {
                Navigator.of(context).pop(); // Pop page
              }
            },
            child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
          ),
        ],
      ),
    );
  }

  // Common success snackbar
  static void showSuccessSnackbar(BuildContext context, String message, {bool popPage = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 16)),
        backgroundColor: hexToColor('8f9c68'),
        duration: Duration(seconds: 2),
      ),
    );
    if (popPage && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  // Common error snackbar
  static void showErrorSnackbar(BuildContext context, String message, {bool popPage = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    if (popPage && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  // Common timeout dialog
  static Future<void> showTimeoutDialog(BuildContext context) async {
    return showErrorDialog(
      context,
      'Timeout',
      'No card detected. Please try again.',
    );
  }

  // Common PIN validation dialog
  static Future<bool> showPinDialog(
    BuildContext context, 
    String accountNo, 
    String correctPin, {
    String title = 'Enter PIN',
    String? subtitle,
  }) async {
    bool pinVerified = false;

    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final pinController = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Account: $accountNo', style: TextStyle(fontSize: 16)),
              if (subtitle != null) ...[
                SizedBox(height: 8),
                Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
              SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN cannot be empty'), backgroundColor: Colors.grey)
                  );
                  return;
                }
                if (pin.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN must be 4 digits'), backgroundColor: Colors.grey)
                  );
                  return;
                }
                if (pin != correctPin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wrong PIN. Try again.'), backgroundColor: Colors.grey)
                  );
                  return;
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
}