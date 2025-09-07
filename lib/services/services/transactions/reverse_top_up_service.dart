import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/models/transaction_result.dart';
import 'package:sahara_app/modules/reverse_top_up_service.dart';
import 'package:sahara_app/pages/reverse_top_up_page.dart';
import 'package:sahara_app/widgets/loading_spinner.dart' as NFCBaseService;
import 'transaction_base_service.dart';

class ReverseTopUpTransactionService extends TransactionBaseService {
  static Future<TransactionResult> handleReverseTopUp(BuildContext context, StaffListModel user) async {
    final receiptNumber = await TransactionBaseService.showInputDialog(
      context,
      'Reverse Topup',
      'Enter Receipt Id',
      '',
      keyboardType: TextInputType.text,
      validator: (input) {
        if (input.isEmpty) return 'Please enter a receipt number';
        return null;
      },
    );

    if (receiptNumber == null) {
      return TransactionResult.error('Reverse top-up cancelled');
    }

    try {
      // Show loading spinner
      NFCBaseService.showLoadingSpinner(context);

      // 🔧 Handle ResponseModel properly
      final reverseResponse = await ReverseTopUpService.reverseTopUp(
        originalRefNumber: receiptNumber, 
        user: user
      );

      // Hide loading spinner
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      // Check if the API call was successful
      if (!reverseResponse.isSuccessfull) {
        if (reverseResponse.message.contains('No Internet Connectivity')) {
          // Show internet connectivity error dialog
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.white,
              title: Text('No Internet'),
              content: Text('Internet  is required to reverse the top-up. \n\nPlease check your connection.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
          return TransactionResult.error('No internet connectivity');
        } else {
          // Show other API errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reverseResponse.message),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 3),
            ),
          );
          return TransactionResult.error(reverseResponse.message);
        }
      }

      // Extract the actual data from ResponseModel
      final result = reverseResponse.body;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No data received from server'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 3),
          ),
        );
        return TransactionResult.error('No data received from server');
      }

      // Success! Extract data and navigate to receipt page
      final deviceId = await getSavedOrFetchDeviceId();

      // Extract data from response
      final responseData = result['data'];
      final customerAccount = responseData['customerAccount'] ?? {};
      final accountNo = customerAccount['customerAccountNumber']?.toString() ?? 'N/A';
      final amount = responseData['topUpAmount']?.abs() ?? 0.0;

      print('✅ Reverse top-up successful');
      print('🏦 Account: $accountNo');
      print('💰 Amount: $amount');
      print('🆔 New Ref: ${result['newRefNumber']}');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReverseTopUpPage(
            user: user,
            accountNo: accountNo,
            staff: user,
            topUpData: responseData,
            refNumber: result['newRefNumber'],
            termNumber: deviceId,
            amount: amount,
          ),
        ),
      );

      return TransactionResult.success('Top-up reversed successfully', data: result);

    } catch (e) {
      // Hide loading spinner on error
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      
      print('❌ Unexpected error in reverse top-up: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'), 
          backgroundColor: Colors.grey, 
          duration: Duration(seconds: 3)
        ),
      );
      return TransactionResult.error('Unexpected error: $e');
    }
  }
}