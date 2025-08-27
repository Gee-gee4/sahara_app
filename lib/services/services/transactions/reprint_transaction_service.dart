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

      final result = await ReprintService.getReceiptForReprint(refNumber: receiptNumber, user: user);

      // Hide loading spinner
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (result['success']) {
        final deviceId = await getSavedOrFetchDeviceId();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReprintReceiptPage(
              user: user,
              apiData: result['data'],
              refNumber: receiptNumber,
              terminalName: deviceId,
            ),
          ),
        );

        return TransactionResult.success('Receipt fetched successfully', data: result);
      } else {
        print('////////////');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed! ${result['error']}'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 3),
          ),
        );
        return TransactionResult.error(result['error'] ?? 'Failed to fetch receipt');
      }
    } catch (e) {
      // Hide loading spinner on error
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.grey, duration: Duration(seconds: 3)),
      );
      return TransactionResult.error('Unexpected error: $e');
    }
  }
}