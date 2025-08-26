// lib/helpers/printer/ministatement_printer_helper.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/printer/ministatement_printer_service.dart';
import 'package:sahara_app/helpers/printer/unified_printer_helper.dart';
import 'package:sahara_app/models/customer_account_details_model.dart';
import 'package:sahara_app/models/ministatment_transaction_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class MiniStatementPrinterHelper {
  static Future<void> printMiniStatement({
    required BuildContext context,
    required StaffListModel user,
    required CustomerAccountDetailsModel accountDetails,
    required List<MinistatmentTransactionModel> transactions,
    required String refNumber,
    required String termNumber,
    String? companyName,
    String? channelName,
    bool navigateToHome = true,
  }) async {
    await UnifiedPrinterHelper.printDocument(
      context: context,
      user: user,
      documentType: 'miniStatement',
      printFunction: () => MiniStatementPrinterService().printMiniStatement(
        user: user,
        accountDetails: accountDetails,
        transactions: transactions,
        refNumber: refNumber,
        termNumber: termNumber,
        companyName: companyName,
        channelName: channelName,
      ),
      customDelayMs: 2500,
      navigateToHome: navigateToHome,
      successMessage: 'All statements printed successfully!',
    );
  }
}