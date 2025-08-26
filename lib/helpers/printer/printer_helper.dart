import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/helpers/printer/printer_service_telpo.dart';
import 'package:sahara_app/models/product_card_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
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
    // Check if sale is incomplete
    if (saleCompleted != null && !saleCompleted) {
      final shouldPrint = await _showSaleNotCompletedDialog(
        context,
        apiCallInProgress ?? false,
        apiError,
      );
      if (!shouldPrint) return;
    }

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

  /// Dialog shown when sale is not yet completed but user tries to print
  static Future<bool> _showSaleNotCompletedDialog(
    BuildContext context,
    bool apiCallInProgress,
    String? apiError,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text("Sale Not Completed"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(apiCallInProgress
                      ? "The sale is still processing. Do you want to print anyway?"
                      : "The sale has not been confirmed."),
                  if (apiError != null) ...[
                    const SizedBox(height: 8),
                    Text("Error: $apiError",
                        style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                TextButton(
                  child: const Text("Print Anyway"),
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
