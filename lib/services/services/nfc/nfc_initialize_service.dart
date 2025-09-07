import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'dart:async';
import 'nfc_base_service.dart';
import '../../../models/nfc_result.dart';
import '../../../models/staff_list_model.dart';
import '../../../helpers/uid_converter.dart';
import '../../../helpers/device_id_helper.dart';
import '../../../modules/initialize_card_service.dart';
import '../../../modules/complete_card_init_service.dart';
import '../../../modules/nfc_functions.dart';

class NFCInitializeService extends NFCBaseService {
  static Future<NFCResult> initializeCard(BuildContext context, StaffListModel user) async {
    NFCBaseService.showLoadingSpinner(context);
    bool shouldDismissSpinner = true;

    try {
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30)),
      );

      if (tag.type != NFCTagType.mifare_classic) {
        await FlutterNfcKit.finish();
        if (!context.mounted) return NFCResult.error('Not a MIFARE Classic card');

        Navigator.of(context).pop();
        shouldDismissSpinner = false;

        await NFCBaseService.showErrorDialog(context, "Invalid Card", "❌ Not a MIFARE Classic card.");
        return NFCResult.error('Not a MIFARE Classic card');
      }

      final rawUID = tag.id;
      final convertedUID = UIDConverter.convertToPOSFormat(rawUID);
      final nfc = NfcFunctions();

      // Check if card is already initialized
      try {
        final initStatusResult = await nfc.readSectorBlock(
          sectorIndex: 2,
          blockSectorIndex: 2,
          useDefaultKeys: false,
        );

        if (initStatusResult.status == NfcMessageStatus.success && initStatusResult.data.trim().startsWith('1')) {
          // Card already initialized
          final accountResult = await nfc.readSectorBlock(sectorIndex: 1, blockSectorIndex: 0, useDefaultKeys: false);
          final pinResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);
          
          await FlutterNfcKit.finish();

          String accountNumber = accountResult.data.replaceAll(';', '').trim();
          // ignore: unused_local_variable
          String pin = pinResult.data.replaceAll(';', '').trim();

          final imei = await getSavedOrFetchDeviceId();
          
          // 🔧 FIX: Handle ResponseModel properly
          final accountDataResponse = await InitializeCardService.fetchCardData(
            cardUID: convertedUID,
            imei: imei,
            staffID: user.staffId,
          );

          if (!context.mounted) return NFCResult.error('Context not mounted');

          Navigator.of(context).pop();
          shouldDismissSpinner = false;

          // Check if the API call failed due to no internet
          if (!accountDataResponse.isSuccessfull) {
            if (accountDataResponse.message.contains('No Internet Connectivity')) {
              await NFCBaseService.showErrorDialog(
                context,
                'No Internet ',
                'Internet is required for this operation. Please check your connection and try again.',
                popPage: true,
              );
              return NFCResult.error('No internet connectivity');
            } else {
              await NFCBaseService.showErrorDialog(
                context,
                'Error',
                'Failed to fetch card data: ${accountDataResponse.message}',
                popPage: true,
              );
              return NFCResult.error('Failed to fetch card data');
            }
          }

          // Extract the actual model from ResponseModel
          final accountData = accountDataResponse.body;
          
          await NFCBaseService.showErrorDialog(
            context,
            'Card Already Initialized',
            'Account: $accountNumber\nCustomer: ${accountData?.customerName ?? 'Unknown'}',
            popPage: true,
          );

          return NFCResult.error('Card already initialized with account: $accountNumber');
        }
      } catch (e) {
        // Card not initialized yet
      }

      // Continue with initialization...
      final imei = await getSavedOrFetchDeviceId();
      
      // 🔧 FIX: Handle ResponseModel properly
      final accountDataResponse = await InitializeCardService.fetchCardData(
        cardUID: convertedUID,
        imei: imei,
        staffID: user.staffId,
      );

      // Check if the API call failed
      if (!accountDataResponse.isSuccessfull) {
        await FlutterNfcKit.finish();

        if (!context.mounted) return NFCResult.error('Context not mounted');

        Navigator.of(context).pop();
        shouldDismissSpinner = false;

        if (accountDataResponse.message.contains('No Internet Connectivity')) {
          await NFCBaseService.showErrorDialog(
            context,
            'No Internet',
            'Internet is required for this operation.\n\n Please check your connection.',
          );
          return NFCResult.error('No internet connectivity');
        } else {
          await NFCBaseService.showErrorDialog(
            context,
            'Failed',
            'Could not fetch card data: ${accountDataResponse.message}',
          );
          return NFCResult.error('Failed to fetch card data');
        }
      }

      // Extract the actual model from ResponseModel
      final accountData = accountDataResponse.body;

      // Check if we have valid account data
      if (accountData == null || accountData.customerAccountNumber == 0) {
        await FlutterNfcKit.finish();

        if (!context.mounted) return NFCResult.error('Context not mounted');

        Navigator.of(context).pop();
        shouldDismissSpinner = false;

        await NFCBaseService.showErrorDialog(
          context,
          'Failed',
          'Could not find the associated account number',
        );
        return NFCResult.error('No valid account found for this card');
      }

      await FlutterNfcKit.finish();

      if (!context.mounted) return NFCResult.error('Context not mounted');

      Navigator.of(context).pop();
      shouldDismissSpinner = false;

      // Get PIN from user
      String? pin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          final controller = TextEditingController();
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Set Pin'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Setting Pin for:', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                SizedBox(height: 3),
                Text(
                  'Customer Name: ${accountData.customerName}\nAccount: ${accountData.customerAccountNumber}',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter 4-digit Pin',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                  ),
                  cursorColor: ColorsUniversal.buttonsColor,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(controller.text),
                child: Text('Set PIN', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          );
        },
      );

      if (pin == null || pin.length != 4) {
        return NFCResult.error('PIN setup cancelled or invalid');
      }

      // Continue with writing to card...
      NFCBaseService.showLoadingSpinner(context);
      shouldDismissSpinner = true;

      final tag2 = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30)),
      );

      if (tag2.type != NFCTagType.mifare_classic) {
        await FlutterNfcKit.finish();
        return NFCResult.error('Not a MIFARE Classic card');
      }

      if (tag2.id != rawUID) {
        await FlutterNfcKit.finish();
        return NFCResult.error('Different card detected. Please use the same card.');
      }

      // Write data to card
      final accountNo = accountData.customerAccountNumber.toString();
      
      final result1 = await nfc.writeSectorBlock(
        sectorIndex: 1,
        blockSectorIndex: 0,
        data: '$accountNo;',
        useDefaultKeys: true,
      );

      if (result1.status != NfcMessageStatus.success) {
        throw Exception("Failed to write account number: ${result1.data}");
      }

      final result2 = await nfc.writeSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        data: '$pin;',
        useDefaultKeys: true,
      );

      if (result2.status != NfcMessageStatus.success) {
        throw Exception("Failed to write PIN: ${result2.data}");
      }

      final result3 = await nfc.writeSectorBlock(
        sectorIndex: 2, 
        blockSectorIndex: 1, 
        data: '3;', 
        useDefaultKeys: true
      );

      if (result3.status != NfcMessageStatus.success) {
        throw Exception("Failed to write lock count: ${result3.data}");
      }

      final result4 = await nfc.writeSectorBlock(
        sectorIndex: 2, 
        blockSectorIndex: 2, 
        data: '1;', 
        useDefaultKeys: true
      );

      if (result4.status != NfcMessageStatus.success) {
        throw Exception("Failed to write init status: ${result4.data}");
      }

      final changeKey1 = await nfc.changeKeys(sectorIndex: 1, fromDefault: true);
      if (changeKey1.status != NfcMessageStatus.success) {
        throw Exception("Failed to change keys for sector 1: ${changeKey1.data}");
      }

      final changeKey2 = await nfc.changeKeys(sectorIndex: 2, fromDefault: true);
      if (changeKey2.status != NfcMessageStatus.success) {
        throw Exception("Failed to change keys for sector 2: ${changeKey2.data}");
      }

      // 🔧 FIX: This should also be updated to use ResponseModel if needed
      final completed = await CompleteCardInitService.completeInitializeCard(
        uid: convertedUID,
        accountNo: accountData.customerAccountNumber,
        staffId: user.staffId,
      );

      await FlutterNfcKit.finish();

      if (!context.mounted) return NFCResult.error('Context not mounted');

      Navigator.of(context).pop();
      shouldDismissSpinner = false;

      NFCBaseService.showSuccessSnackbar(context, 'Card initialized successfully');

      return NFCResult.success('Card initialized successfully', data: {
        'accountNumber': accountNo,
        'customerName': accountData.customerName,
        'pin': pin,
        'completed': completed,
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

      return NFCResult.error('Initialization failed: ${e.toString()}');

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