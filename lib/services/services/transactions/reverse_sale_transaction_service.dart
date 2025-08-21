import 'package:flutter/material.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/models/transaction_result.dart';
import 'package:sahara_app/modules/reverse_sale_service.dart' as OriginalReverseSaleService;
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
      '(e.g., TR5250815153110)',
      keyboardType: TextInputType.text,
      maxLength: 20,
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
        await TransactionBaseService.showSuccessDialog(
          context,
          'Reversal Successful',
          'Transaction has been reversed successfully.',
          details: {
            'Original Receipt:': result['originalRefNumber'],
            'Reversal Receipt:': result['newRefNumber'],
            'Status:': 'Reversed',
          },
        );
        
        return TransactionResult.success('Transaction reversed successfully', data: result);
      } else {
        return TransactionResult.error(result['error']);
      }
    } catch (e) {
      return TransactionResult.error('Error: $e');
    }
  }
}