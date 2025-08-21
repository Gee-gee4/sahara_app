import 'package:flutter/material.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/models/transaction_result.dart';
import 'package:sahara_app/pages/tap_card_page.dart';
import 'package:sahara_app/services/services/nfc/nfc_service_factory.dart';
import 'transaction_base_service.dart';


class TopUpTransactionService extends TransactionBaseService {
  static Future<TransactionResult> handleTopUp(
    BuildContext context, 
    StaffListModel user
  ) async {
    final amountText = await TransactionBaseService.showInputDialog(
      context,
      'Topup Account',
      'Enter TopUp Amount',
      'Amount (e.g., 1000)',
      keyboardType: TextInputType.number,
      maxLength: 20,
      validator: (input) {
        if (input.isEmpty) return 'Please enter an amount';
        
        final amount = double.tryParse(input);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        
        if (amount < 10) {
          return 'Minimum top-up amount is Ksh 10';
        }
        
        return null;
      },
    );

    if (amountText == null) {
      return TransactionResult.error('Top-up cancelled');
    }

    final amount = double.parse(amountText);

    // Navigate to TapCardPage for NFC operation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TapCardPage(
          user: user,
          action: TapCardAction.topUp,
          topUpAmount: amount,
        ),
      ),
    );

    return TransactionResult.success('Top-up initiated', data: {'amount': amount});
  }
}