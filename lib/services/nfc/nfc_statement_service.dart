import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'nfc_base_service.dart';
import '../../models/nfc_result.dart';
import '../../models/staff_list_model.dart';
import '../../modules/nfc_functions.dart';
import '../../modules/ministatement_service.dart';
import '../../helpers/device_id_helper.dart';
import '../../helpers/ref_generator.dart';
import '../../pages/mini_statement_page.dart';

class NFCStatementService extends NFCBaseService {
  static Future<NFCResult> handleMiniStatement(BuildContext context, StaffListModel user) async {
    print("📡 Scanning card for mini statement...");
    bool shouldDismissSpinner = true;

    try {
      // Step 1: Start NFC polling with spinner
      NFCBaseService.showLoadingSpinner(context);

      // Poll for card with timeout
      // ignore: unused_local_variable
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30));
        },
      );

      final nfc = NfcFunctions();

      // Step 2: Read account number from card
      final accountResponse = await nfc.readSectorBlock(
        sectorIndex: 1, 
        blockSectorIndex: 0, 
        useDefaultKeys: false
      );

      if (accountResponse.status != NfcMessageStatus.success) {
        await FlutterNfcKit.finish();
        if (!context.mounted) return NFCResult.error('Context not mounted');
        
        Navigator.of(context).pop();
        shouldDismissSpinner = false;
        
        _showErrorMessage(context, 'Could not read card data. Please try again.');
        return NFCResult.error('Failed to read account number');
      }

      // Step 3: Read PIN from card
      final pinResponse = await nfc.readSectorBlock(
        sectorIndex: 2, 
        blockSectorIndex: 0, 
        useDefaultKeys: false
      );

      await FlutterNfcKit.finish();

      if (pinResponse.status != NfcMessageStatus.success) {
        if (!context.mounted) return NFCResult.error('Context not mounted');
        
        Navigator.of(context).pop();
        shouldDismissSpinner = false;
        
        _showErrorMessage(context, 'Could not read card PIN.');
        return NFCResult.error('Failed to read PIN');
      }

      // Step 4: Extract account number and PIN
      final accountNo = accountResponse.data.replaceAll(RegExp(r'[^0-9]'), '');
      final cardPin = pinResponse.data.replaceAll(';', '').trim();

      print("🎯 Account number: $accountNo");
      print("🔐 PIN from card: $cardPin");

      if (accountNo.isEmpty || accountNo == '0') {
        if (!context.mounted) return NFCResult.error('Context not mounted');
        
        Navigator.of(context).pop();
        shouldDismissSpinner = false;
        
        _showErrorMessage(context, 'No assigned account found on this card.');
        return NFCResult.error('No assigned account found');
      }

      // Step 5: Dismiss spinner and show PIN dialog
      if (!context.mounted) return NFCResult.error('Context not mounted');
      
      Navigator.of(context).pop();
      shouldDismissSpinner = false;

      // Show PIN dialog
      final pinValid = await _showMiniStatementPinDialog(context, accountNo, cardPin);
      if (!pinValid) {
        print("❌ PIN validation failed");
        return NFCResult.error('PIN validation failed or cancelled');
      }

      // Step 6: PIN verified, fetch mini statement
      print("✅ PIN verified, fetching mini statement...");

      // Show loading again
      NFCBaseService.showLoadingSpinner(context);
      shouldDismissSpinner = true;

      final result = await MiniStatementService.fetchMiniStatement(
        accountNumber: accountNo, 
        user: user
      );

      if (!context.mounted) return NFCResult.error('Context not mounted');
      
      Navigator.of(context).pop();
      shouldDismissSpinner = false;

      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('companyName') ?? 'SAHARA FCS';
      final channelName = prefs.getString('channelName') ?? 'Station';
      final deviceId = await getSavedOrFetchDeviceId();
      final refNumber = await RefGenerator.generate();

      if (result['success']) {
        // Navigate to mini statement page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MiniStatementPage(
              user: user,
              accountDetails: result['accountDetails'],
              transactions: result['transactions'],
              channelName: channelName,
              companyName: companyName,
              termNumber: deviceId,
              refNumber: refNumber,
            ),
          ),
        );
        
        return NFCResult.success('Mini statement retrieved successfully', data: result);
      } else {
        _showErrorMessage(context, result['error']);
        return NFCResult.error('Failed to fetch mini statement: ${result['error']}');
      }

    } catch (e) {
      await FlutterNfcKit.finish();

      if (!context.mounted) return NFCResult.error('Context not mounted');

      if (e is TimeoutException) {
        if (shouldDismissSpinner) {
          Navigator.of(context).pop();
          shouldDismissSpinner = false;
        }
        await _showTimeoutDialog(context);
        return NFCResult.error('Timeout: No card detected');
      }

      if (shouldDismissSpinner) {
        Navigator.of(context).pop();
      }
      
      _showErrorMessage(context, 'Error: ${e.toString()}');
      return NFCResult.error('Error: ${e.toString()}');

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

  // PIN dialog for mini statement
  static Future<bool> _showMiniStatementPinDialog(
    BuildContext context, 
    String accountNo, 
    String correctPin
  ) async {
    return await NFCBaseService.showPinDialog(
      context, 
      accountNo, 
      correctPin,
      title: 'Enter PIN for Mini Statement',
    );
  }

  static void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Colors.grey, 
        duration: Duration(seconds: 2)
      )
    );
    Navigator.of(context).pop();
  }

  static Future<void> _showTimeoutDialog(BuildContext context) async {
    return NFCBaseService.showErrorDialog(
      context,
      "Timeout",
      "No card detected. Please try again.",
    );
  }
}