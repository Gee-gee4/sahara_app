// lib/helpers/printer/reprint_printer_helper.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/printer/reprint_printer_service.dart';
import 'package:sahara_app/helpers/printer/unified_printer_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class ReprintPrinterHelper {
  static Future<void> printReprintReceipt({
    required BuildContext context,
    required StaffListModel user,
    required Map<String, dynamic> apiData,
    required String refNumber,
    required String terminalName,
    String? companyName,
    String? channelName,
    bool navigateToHome = true,
  }) async {
    await UnifiedPrinterHelper.printDocument(
      context: context,
      user: user,
      documentType: 'reprint',
      printFunction: () => ReprintPrinterService().printReprintReceipt(
        user: user,
        apiData: apiData,
        refNumber: refNumber,
        terminalName: terminalName,
        companyName: companyName,
        channelName: channelName,
      ),
      navigateToHome: navigateToHome,
      successMessage: 'All receipts printed successfully!',
    );
  }
}