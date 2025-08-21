import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:async';
import 'nfc_base_service.dart';
import '../../models/nfc_result.dart';
import '../../models/staff_list_model.dart';
import '../../modules/nfc_functions.dart';
import '../../modules/customer_account_details_service.dart';
import '../../helpers/device_id_helper.dart';
import '../../pages/card_details_page.dart';

class NFCDetailsService extends NFCBaseService {
  static Future<NFCResult> handleCardDetails(BuildContext context, StaffListModel user) async {
    print("📡 Scanning card for details...");
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
        useDefaultKeys: false, // Use POS keys
      );

      if (accountResponse.status != NfcMessageStatus.success) {
        await FlutterNfcKit.finish();

        if (!context.mounted) return NFCResult.error('Context not mounted');

        Navigator.of(context).pop(); // Close spinner
        shouldDismissSpinner = false;

        Navigator.of(context).pop(); // Close current page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card data. Please try again.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        print("❌ Failed to read account number: ${accountResponse.data}");
        return NFCResult.error('Failed to read account number');
      }

      // Step 3: Read PIN from card for validation
      final pinResponse = await nfc.readSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        useDefaultKeys: false, // Use POS keys
      );

      await FlutterNfcKit.finish(); // End NFC session

      if (pinResponse.status != NfcMessageStatus.success) {
        if (!context.mounted) return NFCResult.error('Context not mounted');

        Navigator.of(context).pop(); // Dismiss spinner
        shouldDismissSpinner = false;

        print("❌ Failed to read PIN from card: ${pinResponse.data}");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card PIN. Card may not be initialized.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return NFCResult.error('Failed to read card PIN');
      }

      // Step 4: Extract and validate account number
      final accountNo = accountResponse.data.replaceAll(RegExp(r'[^0-9]'), '');
      final cardPin = pinResponse.data.replaceAll(';', '').trim();

      print("🎯 Account number from card: $accountNo");
      print("🔐 PIN from card: $cardPin");

      if (accountNo.isEmpty || accountNo == '0') {
        if (!context.mounted) return NFCResult.error('Context not mounted');

        Navigator.of(context).pop(); // Dismiss spinner
        shouldDismissSpinner = false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No assigned account found on this card.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return NFCResult.error('No assigned account found');
      }

      // Step 5: Dismiss spinner before showing PIN dialog
      if (!context.mounted) return NFCResult.error('Context not mounted');

      Navigator.of(context).pop(); // Dismiss spinner
      shouldDismissSpinner = false;

      // Prompt user for PIN and validate
      final pinValid = await NFCBaseService.showPinDialog(
        context, 
        accountNo, 
        cardPin,
        title: 'Enter PIN',
      );

      if (!pinValid) {
        print("❌ PIN validation failed or was cancelled");
        return NFCResult.error('PIN validation failed or cancelled');
      }

      // Step 6: PIN is correct! Show loading state for API call
      print("✅ PIN verified successfully");

      if (!context.mounted) return NFCResult.error('Context not mounted');

      NFCBaseService.showLoadingSpinner(context);
      shouldDismissSpinner = true;

      final deviceId = await getSavedOrFetchDeviceId();
      print('📱 Device ID used for sync: $deviceId');

      final details = await CustomerAccountDetailsService.fetchCustomerAccountDetails(
        accountNo: accountNo,
        deviceId: deviceId,
      );

      // Close loading dialog
      if (!context.mounted) return NFCResult.error('Context not mounted');

      Navigator.of(context).pop();
      shouldDismissSpinner = false;

      // Step 7: Check if details were found
      if (details == null) {
        print("❌ No details found for account: $accountNo");

        await NFCBaseService.showErrorDialog(
          context,
          'No Details Found',
          'Could not find customer details for account: $accountNo\n\n'
          'The account may not exist in the system or there may be a connection issue.',
        );
        return NFCResult.error('No details found for account');
      }

      // Step 8: Success! Navigate to details page
      print("✅ Customer details fetched successfully");
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardDetailsPage(
            user: user, 
            details: details, 
            termNumber: deviceId
          ),
        ),
      );

      return NFCResult.success('Card details retrieved successfully', data: {
        'accountNo': accountNo,
        'details': details,
        'deviceId': deviceId,
      });

    } catch (e) {
      await FlutterNfcKit.finish(); // Always end NFC session

      if (!context.mounted) return NFCResult.error('Context not mounted');

      // Handle timeout specifically
      if (e is TimeoutException) {
        if (shouldDismissSpinner) {
          Navigator.of(context).pop(); // Dismiss spinner
          shouldDismissSpinner = false;
        }
        await NFCBaseService.showTimeoutDialog(context);
        return NFCResult.error('Timeout: No card detected');
      }

      // Handle other errors
      if (shouldDismissSpinner) {
        Navigator.of(context).pop(); // Dismiss spinner
      }

      print("❌ Exception occurred: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error occurred: ${e.toString()}'),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 3),
        ),
      );

      return NFCResult.error('Error occurred: ${e.toString()}');

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