import 'package:flutter/material.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/models/transaction_result.dart';
import 'package:sahara_app/services/services/transactions/reprint_transaction_service.dart';
import 'package:sahara_app/services/services/transactions/reverse_top_up_service.dart';
import 'pin_change_service.dart';
import 'reverse_sale_transaction_service.dart';
import 'topup_transaction_service.dart';

enum TransactionAction {
  changePin,
  reverseSale,
  reprintReceipt,
  reverseTopUp,
  topUp,
}

class TransactionServiceFactory {
  static Future<TransactionResult> executeAction(
    TransactionAction action,
    BuildContext context,
    StaffListModel user,
  ) async {
    switch (action) {
      case TransactionAction.changePin:
        return await PinChangeService.handleChangePin(context, user);
        
      case TransactionAction.reverseSale:
        return await ReverseSaleTransactionService.handleReverseSale(context, user);
        
      case TransactionAction.reprintReceipt:
        return await ReprintTransactionService.handleReprint(context, user);
        
      case TransactionAction.reverseTopUp:
        return await ReverseTopUpTransactionService.handleReverseTopUp(context, user);
        
      case TransactionAction.topUp:
        return await TopUpTransactionService.handleTopUp(context, user);
        
      }
  }

  static String getActionTitle(TransactionAction action) {
    switch (action) {
      case TransactionAction.changePin:
        return "Change Card PIN";
      case TransactionAction.reverseSale:
        return "Reverse Sale";
      case TransactionAction.reprintReceipt:
        return "Reprint Receipt";
      case TransactionAction.reverseTopUp:
        return "Reverse Top-Up";
      case TransactionAction.topUp:
        return "Account Top-Up";
      }
  }
}