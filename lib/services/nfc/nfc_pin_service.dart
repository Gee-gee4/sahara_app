import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:async';
import 'nfc_base_service.dart';
import '../../models/nfc_result.dart';
import '../../models/staff_list_model.dart';
import '../../modules/nfc_functions.dart';


class NFCPinService extends NFCBaseService {
  static Future<NFCResult> changeCardPIN(
    BuildContext context, 
    StaffListModel user, 
    Map<String, dynamic>? extraData
  ) async {
    // Validate input data
    if (extraData == null || !extraData.containsKey('oldPin') || !extraData.containsKey('newPin')) {
      return NFCResult.error('No PIN data provided');
    }

    final oldPin = extraData['oldPin'] as String;
    final newPin = extraData['newPin'] as String;

    if (oldPin.isEmpty || newPin.isEmpty || oldPin.length != 4 || newPin.length != 4) {
      return NFCResult.error('Invalid PIN data provided');
    }

    bool shouldDismissSpinner = true;

    try {
      // Show loading spinner
      NFCBaseService.showLoadingSpinner(context);

      // Poll for card with timeout
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30));
        },
      );

      if (tag.type != NFCTagType.mifare_classic) {
        await FlutterNfcKit.finish();

        if (!context.mounted) return NFCResult.error('Context not mounted');

        // Dismiss spinner before showing dialog
        Navigator.of(context).pop();
        shouldDismissSpinner = false;

        await NFCBaseService.showErrorDialog(
          context,
          'Invalid Card',
          'Not a MIFARE Classic card. Please use a valid card.',
        );
        return NFCResult.error('Not a MIFARE Classic card');
      }

      final nfc = NfcFunctions();

      // Read current PIN from card
      final currentPinResult = await nfc.readSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        useDefaultKeys: false
      );

      if (currentPinResult.status != NfcMessageStatus.success) {
        throw Exception("Failed to read current PIN: ${currentPinResult.data}");
      }

      final storedPin = currentPinResult.data.replaceAll(';', '').trim();

      // Verify old PIN matches
      if (storedPin != oldPin) {
        await FlutterNfcKit.finish();

        if (!context.mounted) return NFCResult.error('Context not mounted');

        // Dismiss spinner before showing dialog
        Navigator.of(context).pop();
        shouldDismissSpinner = false;

        await NFCBaseService.showErrorDialog(
          context,
          'Incorrect PIN',
          'The current PIN you entered is incorrect. Please try again.',
        );
        return NFCResult.error('Incorrect current PIN');
      }

      // Write new PIN to card
      final writeResult = await nfc.writeSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        data: '$newPin;',
        useDefaultKeys: false,
      );

      if (writeResult.status != NfcMessageStatus.success) {
        throw Exception("Failed to write new PIN: ${writeResult.data}");
      }

      // Verify the new PIN was written correctly
      final verifyResult = await nfc.readSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        useDefaultKeys: false
      );

      final verifiedPin = verifyResult.data.replaceAll(';', '').trim();
      await FlutterNfcKit.finish();

      if (!context.mounted) return NFCResult.error('Context not mounted');

      // Success! Dismiss spinner and show success snackbar, then pop page
      Navigator.of(context).pop(); // Dismiss spinner
      shouldDismissSpinner = false;

      NFCBaseService.showSuccessSnackbar(context, 'PIN changed successfully!');

      return NFCResult.success('PIN changed successfully', data: {
        'oldPin': oldPin,
        'newPin': newPin,
        'verifiedPin': verifiedPin,
      });

    } catch (e) {
      await FlutterNfcKit.finish();

      if (!context.mounted) return NFCResult.error('Context not mounted');

      // Handle timeout specifically
      if (e is TimeoutException) {
        if (shouldDismissSpinner) {
          Navigator.of(context).pop();
          shouldDismissSpinner = false;
        }
        await NFCBaseService.showTimeoutDialog(context);
        return NFCResult.error('Timeout: No card detected');
      }

      // Handle other errors
      if (shouldDismissSpinner) {
        Navigator.of(context).pop();
        shouldDismissSpinner = false;
      }

      print('PIN change error: ${e.toString()}');

      NFCBaseService.showErrorSnackbar(context, 'PIN change failed, Card may not be assigned');
      return NFCResult.error('PIN change failed: ${e.toString()}');

    } finally {
      // Ensure spinner is dismissed if still showing
      if (shouldDismissSpinner && context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Spinner might already be dismissed
        }
      }
    }
  }
}