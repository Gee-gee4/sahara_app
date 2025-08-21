import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:async';
import 'nfc_base_service.dart';
import '../../models/nfc_result.dart';
import '../../helpers/uid_converter.dart';
import '../../utils/colors_universal.dart';

class NFCUIDService extends NFCBaseService {
  static Future<NFCResult> viewUID(BuildContext context) async {
    bool shouldDismissSpinner = true;

    try {
      // Show loading dialog
      NFCBaseService.showLoadingSpinner(context);

      // Poll for card with timeout
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30));
        },
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        shouldDismissSpinner = false;
      }

      // Get UID
      final appUID = tag.id;
      final posUID = UIDConverter.convertToPOSFormat(appUID);

      await FlutterNfcKit.finish();

      // Show result dialog
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text("Card Identifier"),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UID', style: TextStyle(fontSize: 20, color: Colors.black54)),
                Text(': $posUID', style: TextStyle(fontSize: 20, color: Colors.black54)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close the dialog first
                  if (context.mounted) Navigator.of(context).pop(); // Then pop the page
                },
                child: Text("OK", style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
      }

      return NFCResult.success('Card UID retrieved successfully', data: {
        'appUID': appUID,
        'posUID': posUID,
      });

    } catch (e) {
      await FlutterNfcKit.finish();

      if (context.mounted && shouldDismissSpinner) {
        Navigator.of(context).pop(); // Close loading dialog
        shouldDismissSpinner = false;
      }

      if (context.mounted) {
        // Handle timeout specifically
        if (e is TimeoutException) {
          await NFCBaseService.showTimeoutDialog(context);
        } else {
          // Handle other errors
          await NFCBaseService.showErrorDialog(
            context,
            "Error",
            "Failed to read card UID",
          );
        }
        print('❌ Error reading card: $e');
      }

      return NFCResult.error('Failed to read card UID: ${e.toString()}');
    }
  }
}