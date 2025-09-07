import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/models/transaction_result.dart';
import 'package:sahara_app/modules/reprint_service.dart';
import 'package:sahara_app/pages/reprint_receipt_page.dart';
import 'package:sahara_app/widgets/loading_spinner.dart' as NFCBaseService;
import 'transaction_base_service.dart';
class ReprintTransactionService extends TransactionBaseService {
  static Future<TransactionResult> handleReprint(BuildContext context, StaffListModel user) async {
    final receiptNumber = await TransactionBaseService.showInputDialog(
      context,
      'Receipt Reprint',
      'Enter Receipt Id',
      '',
      keyboardType: TextInputType.text,
      validator: (input) {
        if (input.isEmpty) return 'Please enter a receipt number';
        return null;
      },
    );

    if (receiptNumber == null) {
      return TransactionResult.error('Reprint cancelled');
    }

    try {
      print('🔄 Fetching receipt: $receiptNumber');

      // Show loading spinner
      NFCBaseService.showLoadingSpinner(context);

      // 🔧 Handle ResponseModel properly
      final reprintResponse = await ReprintService.getReceiptForReprint(
        refNumber: receiptNumber, 
        user: user
      );

      // Hide loading spinner
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      // Check if the API call was successful
      if (!reprintResponse.isSuccessfull) {
        if (reprintResponse.message.contains('No Internet Connectivity')) {
          // Show internet connectivity error dialog
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.white,
              title: Text('No Internet'),
              content: Text('Internet is required to fetch the receipt data. \n\nPlease check your connection.'),
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
          // Show other API errors in snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed! ${reprintResponse.message}'),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 3),
            ),
          );
          return TransactionResult.error(reprintResponse.message);
        }
      }

      // Extract the actual data from ResponseModel
      final result = reprintResponse.body;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No receipt data received from server'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 3),
          ),
        );
        return TransactionResult.error('No receipt data received from server');
      }

      // Success! Navigate to reprint receipt page
      final deviceId = await getSavedOrFetchDeviceId();
      
      print('✅ Receipt data fetched successfully');
      print('📄 Receipt Number: $receiptNumber');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReprintReceiptPage(
            user: user,
            apiData: result,
            refNumber: receiptNumber,
            terminalName: deviceId,
          ),
        ),
      );

      return TransactionResult.success('Receipt fetched successfully', data: result);

    } catch (e) {
      // Hide loading spinner on error
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      
      print('❌ Unexpected error in reprint: $e');
      
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