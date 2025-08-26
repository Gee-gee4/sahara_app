// lib/helpers/printer/topup_printer_helper.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/printer/topup_printer_service.dart';
import 'package:sahara_app/helpers/printer/unified_printer_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class TopUpPrinterHelper {
  static Future<void> printTopUpReceipt({
    required BuildContext context,
    required StaffListModel user,
    required String title,
    required String refNumber,
    required String termNumber,
    required double amount,
    required Map<String, dynamic> topUpData,
    required String accountNo,
    required String staffName,
    required bool isReversal,
    String? companyName,
    String? channelName,
    bool navigateToHome = true,
  }) async {
    await UnifiedPrinterHelper.printDocument(
      context: context,
      user: user,
      documentType: 'topUp',
      printFunction: () => TopUpPrinterService().printTopUpReceipt(
        title: title,
        refNumber: refNumber,
        termNumber: termNumber,
        amount: amount,
        topUpData: topUpData,
        accountNo: accountNo,
        staffName: staffName,
        isReversal: isReversal,
        companyName: companyName,
        channelName: channelName,
      ),
      navigateToHome: navigateToHome,
      successMessage: 'All receipts printed successfully!',
    );
  }
}