import 'package:flutter/material.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/models/transaction_result.dart';
import 'package:sahara_app/modules/reverse_sale_service.dart' as OriginalReverseSaleService;
import 'package:sahara_app/pages/reverse_sale_page.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'transaction_base_service.dart';

class ReverseSaleTransactionService extends TransactionBaseService {
  static Future<TransactionResult> handleReverseSale(
    BuildContext context, 
    StaffListModel user
  ) async {
    final receiptNumber = await TransactionBaseService.showInputDialog(
      context,
      'Reverse Sale',
      'Enter Receipt Id',
      '',
      keyboardType: TextInputType.text,
      validator: (input) {
        if (input.isEmpty) return 'Please enter a receipt number';
        return null;
      },
    );

    if (receiptNumber == null) {
      return TransactionResult.error('Reverse sale cancelled');
    }

    // Show confirmation dialog
    final shouldReverse = await TransactionBaseService.showConfirmationDialog(
      context,
      'Confirm Reversal',
      'Are you sure you want to reverse this transaction?\n\nReceipt: $receiptNumber',
      'Reverse',
    );

    if (!shouldReverse) {
      return TransactionResult.error('Reverse sale cancelled');
    }

    try {
      print('🔄 Reversing transaction: $receiptNumber');

      final result = await OriginalReverseSaleService.ReverseSaleService.reverseTransaction(
        originalRefNumber: receiptNumber,
        user: user,
      );

      if (result['success']) {
        // Get device ID for the receipt
        final deviceId = await getSavedOrFetchDeviceId();
        
        // Navigate to the ReverseSalePage instead of showing a dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReverseSalePage(
              user: user,
              apiData: result['data'],
              originalRefNumber: result['originalRefNumber'],
              reversalRefNumber: result['newRefNumber'],
              terminalName: deviceId,
            ),
          ),
        );
        
        return TransactionResult.success('Transaction reversed successfully', data: result);
      } else {
        // Show error in a snackbar instead of dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed! ${result['error']}'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 3),
          ),
        );
        return TransactionResult.error(result['error']);
      }
    } catch (e) {
      // Show error in a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 3),
        ),
      );
      return TransactionResult.error('Error: $e');
    }
  }
}