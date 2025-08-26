// lib/helpers/printer/card_details_printer_helper.dart
import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/printer/card_details_printer_service.dart';
import 'package:sahara_app/helpers/printer/unified_printer_helper.dart';
import 'package:sahara_app/models/customer_account_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class CardDetailsPrinterHelper {
  static Future<void> printCardDetails({
    required BuildContext context,
    required StaffListModel user,
    required CustomerAccountDetailsModel details,
    required String termNumber,
    String? companyName,
    String? channelName,
    bool navigateToHome = true,
  }) async {
    await UnifiedPrinterHelper.printDocument(
      context: context,
      user: user,
      documentType: 'cardDetails',
      printFunction: () => CardDetailsPrinterService().printCardDetails(
        user: user,
        details: details,
        termNumber: termNumber,
        companyName: companyName,
        channelName: channelName,
      ),
      customDelayMs: 3000,
      navigateToHome: navigateToHome,
      successMessage: 'All card details printed successfully!',
    );
  }
}
