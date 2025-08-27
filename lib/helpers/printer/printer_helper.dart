import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/helpers/printer/printer_service_telpo.dart';
import 'package:sahara_app/models/product_card_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'unified_printer_helper.dart';

class PrinterHelper {
  /// Handles printing a sales receipt
  static Future<void> printReceipt({
    required BuildContext context,
    required StaffListModel user,
    required List<CartItem> cartItems,
    required double cashGiven,
    required String customerName,
    required String card,
    required String accountType,
    required String vehicleNumber,
    required bool showCardDetails,
    required String refNumber,
    required String termNumber,
    double? discount,
    double? clientTotal,
    double? customerBalance,
    List<ProductCardDetailsModel>? accountProducts,
    String? companyName,
    String? channelName,
    bool? saleCompleted,
    bool? apiCallInProgress,
    String? apiError,
    bool clearCartOnComplete = true,
    bool navigateToHome = true,
  }) async {
    // Check if sale failed (not just in progress)
    if (saleCompleted != null && !saleCompleted && apiCallInProgress == false) {
      final shouldPrint = await _showSaleFailedDialog(context, apiError);
      if (!shouldPrint) return;
    }

    // If sale is still in progress, we assume the button is disabled
    // and the user is waiting, so we proceed with printing

    // Delegate to UnifiedPrinterHelper
    await UnifiedPrinterHelper.printDocument(
      context: context,
      user: user,
      documentType: 'receipt',
      navigateToHome: navigateToHome,
      successMessage: 'All receipts printed successfully!',
      printFunction: () {
        return PrinterServiceTelpo().printReceiptForTransaction(
          user: user,
          cartItems: cartItems,
          cashGiven: cashGiven,
          customerName: customerName,
          card: card,
          accountType: accountType,
          vehicleNumber: vehicleNumber,
          showCardDetails: showCardDetails,
          discount: discount,
          clientTotal: clientTotal,
          customerBalance: customerBalance,
          accountProducts: accountProducts,
          companyName: companyName,
          channelName: channelName,
          refNumber: refNumber,
          termNumber: termNumber,
        );
      },
    );

    // Handle cart clearing after printing
    if (clearCartOnComplete) {
      CartStorage().clearCart();
    }
  }

  /// Dialog shown only when sale has failed (not in progress)
  static Future<bool> _showSaleFailedDialog(
    BuildContext context,
    String? apiError,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text("Sale Failed"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("The sale could not be completed."),
                  if (apiError != null) ...[
                    const SizedBox(height: 8),
                    Text("Error: $apiError",
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  child: Text("Cancel", style: TextStyle(color: ColorsUniversal.buttonsColor)),
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                TextButton(
                  child: Text("Print Anyway", style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16)),
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}