import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:async';
import 'nfc_base_service.dart';
import '../../../models/nfc_result.dart';
import '../../../models/staff_list_model.dart';
import '../../../modules/nfc_functions.dart';
import '../../../modules/top_up_service.dart';
import '../../../helpers/device_id_helper.dart';
import '../../../pages/top_up_page.dart';
import '../../../utils/colors_universal.dart';

class NFCTopUpService extends NFCBaseService {
  static Future<NFCResult> handleTopUp(
    BuildContext context, 
    StaffListModel user, 
    Map<String, dynamic>? extraData
  ) async {
    final deviceId = await getSavedOrFetchDeviceId();
    final topUpAmount = extraData?['topUpAmount'] as double?;
    
    print("💰 Scanning card for top-up...");
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
        useDefaultKeys: false,
      );

      if (accountResponse.status != NfcMessageStatus.success) {
        await FlutterNfcKit.finish();
        if (!context.mounted) return NFCResult.error('Context not mounted');
        
        Navigator.of(context).pop();
        shouldDismissSpinner = false;
        Navigator.of(context).pop();
        
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

      // Step 3: Read PIN from card
      final pinResponse = await nfc.readSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        useDefaultKeys: false,
      );

      await FlutterNfcKit.finish();

      if (pinResponse.status != NfcMessageStatus.success) {
        if (!context.mounted) return NFCResult.error('Context not mounted');
        
        Navigator.of(context).pop();
        shouldDismissSpinner = false;
        
        print("❌ Failed to read PIN from card: ${pinResponse.data}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card PIN. Card may not be initialized.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return NFCResult.error('Failed to read PIN');
      }

      // Step 4: Extract and validate account number and PIN
      final accountNo = accountResponse.data.replaceAll(RegExp(r'[^0-9]'), '');
      final cardPin = pinResponse.data.replaceAll(';', '').trim();

      print("🎯 Account number from card: $accountNo");
      print("🔐 PIN from card: $cardPin");
      print("💰 Top-up amount: $topUpAmount");

      if (accountNo.isEmpty || accountNo == '0') {
        if (!context.mounted) return NFCResult.error('Context not mounted');
        
        Navigator.of(context).pop();
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

      if (topUpAmount == null || topUpAmount <= 0) {
        if (!context.mounted) return NFCResult.error('Context not mounted');
        
        Navigator.of(context).pop();
        shouldDismissSpinner = false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid top-up amount.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return NFCResult.error('Invalid top-up amount');
      }

      // Step 5: Dismiss spinner before showing PIN dialog
      if (!context.mounted) return NFCResult.error('Context not mounted');
      
      Navigator.of(context).pop();
      shouldDismissSpinner = false;

      // Show PIN confirmation dialog
      final pinValid = await _showTopUpPinDialog(context, accountNo, cardPin, topUpAmount);
      if (!pinValid) {
        print("❌ PIN validation failed or was cancelled");
        return NFCResult.error('PIN validation failed or cancelled');
      }

      // Step 6: PIN is correct! Show loading state for API call
      print("✅ PIN verified successfully");

      if (!context.mounted) return NFCResult.error('Context not mounted');

      NFCBaseService.showLoadingSpinner(context);
      shouldDismissSpinner = true;

      final result = await TopUpService.processTopUp(
        accountNo: accountNo,
        topUpAmount: topUpAmount,
        user: user,
      );

      // Close loading dialog
      if (!context.mounted) return NFCResult.error('Context not mounted');
      
      Navigator.of(context).pop();
      shouldDismissSpinner = false;

      if (result['success']) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TopUpPage(
              user: user,
              accountNo: accountNo,
              staff: user,
              topUpData: result['data'],
              refNumber: result['refNumber'],
              termNumber: deviceId,
              amount: result['amount'],
            ),
          ),
        );
        
        return NFCResult.success('Top-up completed successfully', data: result);
      } else {
        print("❌ Top-up failed: ${result['error']}");
        
        await NFCBaseService.showErrorDialog(
          context,
          'Top-Up Failed',
          'Top-up could not be completed.\n\n${result['error']}',
        );
        
        return NFCResult.error('Top-up failed: ${result['error']}');
      }

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

  // PIN dialog for top-up confirmation
  static Future<bool> _showTopUpPinDialog(
    BuildContext context, 
    String accountNo, 
    String correctPin, 
    double amount
  ) async {
    bool pinVerified = false;

    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final pinController = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Confirm Top-Up'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Account: $accountNo', style: TextStyle(fontSize: 16)),
              Text(
                'Amount: Ksh ${amount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColorsUniversal.buttonsColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN to confirm',
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
              onPressed: () => Navigator.of(context).pop(),
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
              child: Text(
                'CONFIRM TOP-UP',
                style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    return pinVerified;
  }
}