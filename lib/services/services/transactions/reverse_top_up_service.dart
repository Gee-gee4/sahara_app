import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/models/transaction_result.dart';
import 'package:sahara_app/modules/reverse_top_up_service.dart';
import 'package:sahara_app/pages/reverse_top_up_page.dart';
import 'transaction_base_service.dart';


class ReverseTopUpTransactionService extends TransactionBaseService {
  static Future<TransactionResult> handleReverseTopUp(
    BuildContext context, 
    StaffListModel user
  ) async {
    final receiptNumber = await TransactionBaseService.showInputDialog(
      context,
      'Reverse Topup',
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
      return TransactionResult.error('Reverse top-up cancelled');
    }

    try {
      final result = await ReverseTopUpService.reverseTopUp(
        originalRefNumber: receiptNumber,
        user: user,
      );

      if (result['success']) {
        final deviceId = await getSavedOrFetchDeviceId();

        // Extract data from response
        final responseData = result['data'];
        final customerAccount = responseData['customerAccount'] ?? {};
        final accountNo = customerAccount['customerAccountNumber']?.toString() ?? 'N/A';
        final amount = responseData['topUpAmount']?.abs() ?? 0.0;

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
      } else {
        return TransactionResult.error(result['error'] ?? 'Failed to reverse top-up');
      }
    } catch (e) {
      return TransactionResult.error('Unexpected error: $e');
    }
  }
}