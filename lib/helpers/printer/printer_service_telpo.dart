// lib/helpers/printing/printer_service_telpo.dart
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/product_card_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:telpo_flutter_sdk/telpo_flutter_sdk.dart';

class PrinterServiceTelpo {
  static final _instance = PrinterServiceTelpo._internal();
  factory PrinterServiceTelpo() => _instance;
  PrinterServiceTelpo._internal();

  final TelpoFlutterChannel _printer = TelpoFlutterChannel();

  Future<PrintResult> printReceiptForTransaction({
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
  }) async {
    final sheet = TelpoPrintSheet();
    final isCardSale = showCardDetails && clientTotal != null && discount != null;

    // Calculations
    double getClientPrice(CartItem item) {
      if (accountProducts == null) return item.price;
      final match = accountProducts.firstWhere(
        (p) => p.productVariationId == item.productId,
        orElse: () => ProductCardDetailsModel(
          productVariationId: 0,
          productVariationName: '',
          productCategoryId: 0,
          productCategoryName: '',
          productPrice: item.price,
          productDiscount: 0,
        ),
      );
      return match.productVariationId != 0 ? match.productPrice : item.price;
    }

    String formatLine(CartItem item, double unitPrice) {
      final total = unitPrice * item.quantity;
      final name = item.productName.padRight(7).substring(0, 7);
      final price = unitPrice.toStringAsFixed(0).padLeft(5);
      final qty = item.quantity.toStringAsFixed(2);
      final totalStr = total.toStringAsFixed(0).padLeft(5);
      return "$name  $price  $qty  $totalStr";
    }

    double stationTotal = cartItems.fold(0.0, (sum, i) => sum + i.price * i.quantity);
    double total = isCardSale ? clientTotal : stationTotal;
    double netTotal = isCardSale ? (clientTotal - discount) : total;
    double change = isCardSale ? 0 : (cashGiven - total);

    // Header
    sheet.addElement(
      PrintData.text(companyName ?? 'SAHARA FCS', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(
      PrintData.text(channelName ?? 'Station', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 4));
    sheet.addElement(PrintData.text('SALE', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24));
    
    // Use the passed parameters instead of hardcoded values
    sheet.addElement(PrintData.text('TERM# $termNumber', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.text('REF# $refNumber', fontSize: PrintedFontSize.size24));
    
    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));

    // Product Table
    sheet.addElement(PrintData.text('Prod    Price  Qty  Total', fontSize: PrintedFontSize.size24));
    sheet.addElement(PrintData.space(line: 2));

    for (final item in cartItems) {
      final unitPrice = isCardSale ? getClientPrice(item) : item.price;
      sheet.addElement(PrintData.text(formatLine(item, unitPrice), fontSize: PrintedFontSize.size24));
    }

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));

    if (isCardSale) {
      sheet.addElement(PrintData.text('Sub Total   ${total.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('Discount    ${discount.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('Net Total   ${netTotal.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
      sheet.addElement(PrintData.text('Card        ${netTotal.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      if (customerBalance != null) {
        sheet.addElement(
          PrintData.text('Balance     ${customerBalance.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24),
        );
      }
    } else {
      sheet.addElement(PrintData.text('Total       ${total.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('Cash        ${cashGiven.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('Change      ${change.toStringAsFixed(2)}', fontSize: PrintedFontSize.size24));
    }

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));

    // Customer info
    if (showCardDetails) {
      sheet.addElement(PrintData.text('Customer: $customerName', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('Card No: $card', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(PrintData.text('Account Type: $accountType', fontSize: PrintedFontSize.size24));
      sheet.addElement(PrintData.space(line: 2));
      if (vehicleNumber.trim().isNotEmpty && vehicleNumber != 'No Equipment') {
        sheet.addElement(PrintData.text('Vehicle: $vehicleNumber', fontSize: PrintedFontSize.size24));
      }
      sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    }

    sheet.addElement(
      PrintData.text('Date: ${DateTime.now().toString().substring(0, 19)}', fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 2));
    sheet.addElement(PrintData.text('Served By: ${user.staffName}', fontSize: PrintedFontSize.size24));

    sheet.addElement(PrintData.text('--------------------------------------------------------------------'));
    sheet.addElement(PrintData.space(line: 4));

    if (isCardSale) {
      sheet.addElement(PrintData.text('APPROVAL', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24));
      sheet.addElement(
        PrintData.text(
          'Cardholder acknowledges receipt',
          fontSize: PrintedFontSize.size24,
          alignment: PrintAlignment.center,
        ),
      );
      sheet.addElement(
        PrintData.text(
          'of goods/services in the amount',
          fontSize: PrintedFontSize.size24,
          alignment: PrintAlignment.center,
        ),
      );
      sheet.addElement(
        PrintData.text('shown above.', fontSize: PrintedFontSize.size24, alignment: PrintAlignment.center),
      );
      sheet.addElement(PrintData.space(line: 2));
      sheet.addElement(
        PrintData.text('Cardholder Signature', fontSize: PrintedFontSize.size24, alignment: PrintAlignment.center),
      );
    }
    sheet.addElement(PrintData.space(line: 4));
    sheet.addElement(PrintData.text('THANK YOU', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24));
    sheet.addElement(
      PrintData.text('CUSTOMER COPY', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(
      PrintData.text('Powered by Sahara FCS', alignment: PrintAlignment.center, fontSize: PrintedFontSize.size24),
    );
    sheet.addElement(PrintData.space(line: 20));

    return await _printer.print(sheet);
  }
}