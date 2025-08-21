import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:async';
import 'nfc_base_service.dart';
import '../../models/nfc_result.dart';
import '../../models/staff_list_model.dart';
import '../../helpers/uid_converter.dart';
import '../../modules/initialize_card_service.dart';
import '../../modules/nfc_functions.dart';

class NFCFormatService extends NFCBaseService {
  static Future<NFCResult> formatCard(BuildContext context, StaffListModel user) async {
    NFCBaseService.showLoadingSpinner(context);
    bool shouldDismissSpinner = true;

    try {
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30)),
      );

      final rawUID = tag.id;

      if (tag.type != NFCTagType.mifare_classic) {
        await FlutterNfcKit.finish();
        if (!context.mounted) return NFCResult.error('Context not mounted');

        Navigator.of(context).pop();
        shouldDismissSpinner = false;

        await NFCBaseService.showErrorDialog(context, "Invalid Card", "❌ Not a MIFARE Classic card.");
        return NFCResult.error('Not a MIFARE Classic card');
      }

      final nfc = NfcFunctions();
      List<String> formatResults = [];

      for (int sector in [1, 2]) {
        bool formatted = false;
        try {
          final res = await nfc.formatSector(sectorIndex: sector, useDefaultKeys: false);
          if (res.status == NfcMessageStatus.success) {
            formatResults.add("✅ Sector $sector: ${res.data}");
            formatted = true;
          }
        } catch (_) {}

        if (!formatted) {
          try {
            final res = await nfc.formatSector(sectorIndex: sector, useDefaultKeys: true);
            if (res.status == NfcMessageStatus.success) {
              formatResults.add("✅ Sector $sector: ${res.data}");
            } else {
              formatResults.add("❌ Sector $sector: ${res.data}");
            }
          } catch (e) {
            formatResults.add("❌ Sector $sector: Error - $e");
          }
        }
      }

      await FlutterNfcKit.finish();

      final convertedUID = UIDConverter.convertToPOSFormat(rawUID);
      final apiSuccess = await InitializeCardService.formatCardAPI(
        cardUID: convertedUID, 
        staffId: user.staffId
      );

      if (!context.mounted) return NFCResult.error('Context not mounted');

      Navigator.of(context).pop();
      shouldDismissSpinner = false;

      NFCBaseService.showSuccessSnackbar(context, 'Card formatted successfully.');
      
      return NFCResult.success('Card formatted successfully', data: {
        'formatResults': formatResults,
        'apiSuccess': apiSuccess,
        'uid': convertedUID,
      });

    } catch (e) {
      await FlutterNfcKit.finish();

      if (!context.mounted) return NFCResult.error('Context not mounted');

      if (e is TimeoutException) {
        if (shouldDismissSpinner) {
          Navigator.of(context).pop();
          shouldDismissSpinner = false;
        }
        await NFCBaseService.showTimeoutDialog(context);
        return NFCResult.error('Timeout: No card detected');
      }

      if (shouldDismissSpinner) {
        Navigator.of(context).pop();
        shouldDismissSpinner = false;
      }

      NFCBaseService.showErrorSnackbar(context, 'Format failed: ${e.toString()}');
      return NFCResult.error('Format failed: ${e.toString()}');

    } finally {
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