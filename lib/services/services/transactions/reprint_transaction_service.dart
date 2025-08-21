import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/models/transaction_result.dart';
import 'package:sahara_app/modules/reprint_service.dart';
import 'package:sahara_app/pages/reprint_receipt_page.dart';
import 'transaction_base_service.dart';


class ReprintTransactionService extends TransactionBaseService {
  static Future<TransactionResult> handleReprint(
    BuildContext context, 
    StaffListModel user
  ) async {
    final receiptNumber = await TransactionBaseService.showInputDialog(
      context,
      'Receipt Reprint',
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
      return TransactionResult.error('Reprint cancelled');
    }

    try {
      print('🔄 Fetching receipt: $receiptNumber');

      final result = await ReprintService.getReceiptForReprint(
        refNumber: receiptNumber,
        user: user,
      );

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
        return TransactionResult.error(result['error'] ?? 'Failed to fetch receipt');
      }
    } catch (e) {
      return TransactionResult.error('Unexpected error: $e');
    }
  }
}