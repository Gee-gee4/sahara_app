// lib/helpers/printer/reverse_sale_printer_helper.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/printer/reverse_sale_printer_service.dart';
import 'package:sahara_app/helpers/printer/unified_printer_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class ReversalPrinterHelper {
  static Future<void> printReversalReceipt({
    required BuildContext context,
    required StaffListModel user,
    required Map<String, dynamic> apiData,
    required String originalRefNumber,
    required String reversalRefNumber,
    required String terminalName,
    String? companyName,
    String? channelName,
    bool navigateToHome = true,
  }) async {
    await UnifiedPrinterHelper.printDocument(
      context: context,
      user: user,
      documentType: 'reversal',
      printFunction: () => ReverseSalePrinterService().printReversalReceipt(
        user: user,
        apiData: apiData,
        originalRefNumber: originalRefNumber,
        reversalRefNumber: reversalRefNumber,
        terminalName: terminalName,
        companyName: companyName,
        channelName: channelName,
      ),
      navigateToHome: navigateToHome,
      successMessage: 'All receipts printed successfully!',
    );
  }
}