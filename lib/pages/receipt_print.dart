// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/helpers/printer_service_telpo.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/product_card_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/sale_service.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:telpo_flutter_sdk/telpo_flutter_sdk.dart';

class ReceiptPrint extends StatefulWidget {
  final StaffListModel user;
  final List<CartItem> cartItems;
  final double cashGiven;
  final String customerName;
  final String card;
  final String accountType;
  final String vehicleNumber;
  final bool showCardDetails;
  final double? discount;
  final double? clientTotal;
  final double? customerBalance;
  final List<ProductCardDetailsModel>? accountProducts;
  final String? companyName;
  final String? channelName;
  final String refNumber;
  final String termNumber;
  final String? cardUID;
  final int? customerAccountNo;
  final int? paymentModeId;
  final String? paymentModeName;

  const ReceiptPrint({
    super.key,
    required this.user,
    required this.cartItems,
    required this.cashGiven,
    required this.customerName,
    required this.card,
    required this.accountType,
    required this.vehicleNumber,
    this.showCardDetails = false,
    this.discount,
    this.clientTotal,
    this.customerBalance,
    this.accountProducts,
    this.companyName,
    this.channelName,
    required this.refNumber,
    required this.termNumber,
    this.cardUID,
    this.customerAccountNo,
    this.paymentModeId,
    this.paymentModeName,
  });

  @override
  State<ReceiptPrint> createState() => _ReceiptPrintState();
}

class _ReceiptPrintState extends State<ReceiptPrint> {
  bool _saleCompleted = false;
  bool _apiCallInProgress = true;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    // Complete the sale as soon as the receipt page loads
    _completeSale();
  }

  Future<void> _completeSale() async {
    print('📤 Completing sale transaction...');

    final bool isCardSale = widget.showCardDetails && widget.clientTotal != null && widget.discount != null;

    try {
      final apiResult = await SaleService.completeSale(
        refNumber: widget.refNumber,
        cartItems: widget.cartItems,
        user: widget.user,
        isCardSale: isCardSale,
        // Card sale data - ALWAYS pass card data if available (for both card sales AND cash+card sales)
        customerName: widget.customerName.isNotEmpty ? widget.customerName : null,
        customerUID: widget.cardUID, // Pass card UID if available (for cash+card tracking)
        customerAccountNo: widget.customerAccountNo, // Pass account number if available (for cash+card tracking)
        customerAccountBalance: widget.customerBalance,
        accountProducts: isCardSale ? widget.accountProducts : null, // Only for card sales (client pricing)
        // Cash sale data
        cashGiven: !isCardSale ? widget.cashGiven : null,
        change: !isCardSale ? (widget.cashGiven - getStationTotal()) : null,
        // Payment mode data
        paymentModeId: widget.paymentModeId,
        paymentModeName: widget.paymentModeName,
      );

      setState(() {
        _apiCallInProgress = false;
        if (apiResult['success']) {
          _saleCompleted = true;
          print('✅ Sale transaction completed successfully');
        } else {
          _apiError = apiResult['error'];
          // ignore: unnecessary_brace_in_string_interps
          print('❌ Sale transaction failed: ${_apiError}');
        }
      });

      // Show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_saleCompleted ? 'Sale completed successfully!' : 'Sale failed: $_apiError'),
            backgroundColor: _saleCompleted ? hexToColor('8f9c68') : Colors.grey,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _apiCallInProgress = false;
        _apiError = 'Network error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sale failed: Network error'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 3),
          ),
        );
      }
      print('❌ Error completing sale: $e');
    }
  }

  Future<void> _printReceipt() async {
    // Check if sale was completed successfully before printing
    if (!_saleCompleted) {
      // Show dialog asking if user wants to proceed anyway
      final shouldPrint = await _showSaleNotCompletedDialog();
      if (!shouldPrint) return; // User chose not to print
    }

    // Check printer status before starting
    final printerReady = await _checkPrinterStatus();
    if (!printerReady) return; // Don't proceed if printer has issues

    final receiptCount = await SharedPrefsHelper.getReceiptCount();

    for (int i = 0; i < receiptCount; i++) {
      print('🖨️ Printing receipt ${i + 1} of $receiptCount');

      // Check printer status before each print (especially important for multiple receipts)
      if (i > 0) {
        final statusOk = await _checkPrinterStatus();
        if (!statusOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Printer issue detected before receipt ${i + 1}. Printing stopped."),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      final result = await PrinterServiceTelpo().printReceiptForTransaction(
        user: widget.user,
        cartItems: widget.cartItems,
        cashGiven: widget.cashGiven,
        customerName: widget.customerName,
        card: widget.card,
        accountType: widget.accountType,
        vehicleNumber: widget.vehicleNumber,
        showCardDetails: widget.showCardDetails,
        discount: widget.discount,
        clientTotal: widget.clientTotal,
        customerBalance: widget.customerBalance,
        accountProducts: widget.accountProducts,
        companyName: widget.companyName,
        channelName: widget.channelName,
      );

      if (result != PrintResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Receipt ${i + 1} failed to print: ${_getPrintResultMessage(result)}"),
            backgroundColor: Colors.grey,
          ),
        );
        return;
      }

      print('✅ Receipt ${i + 1} print command sent');

      // Wait for printer to actually finish printing
      if (i < receiptCount - 1) {
        // Use both approaches: minimum delay + status monitoring
        print('⏳ Ensuring printer is ready for next receipt...');

        // Calculate minimum delay based on content
        int minDelay = 2000 + (widget.cartItems.length * 300);
        await Future.delayed(Duration(milliseconds: minDelay));

        // Then check if printer is actually ready
        await _waitForPrinterToFinish();
      }
    }

    print('🎉 All receipts printed');

    // Show success message but don't navigate yet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All receipts printed successfully!'),
        backgroundColor: hexToColor('8f9c68'),
        duration: Duration(seconds: 2),
      ),
    );

    // Optional: Auto-navigate after a short delay to let user see the success message
    await Future.delayed(Duration(seconds: 2));

    CartStorage().clearCart();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage(user: widget.user)),
      (route) => false,
    );
  }

  // New method to check printer status
  Future<bool> _checkPrinterStatus() async {
    try {
      final TelpoFlutterChannel _printer = TelpoFlutterChannel();
      final TelpoStatus status = await _printer.checkStatus();

      print('🖨️ Printer status: ${status.toString()}');

      switch (status) {
        case TelpoStatus.ok: // Changed from TelpoStatus.values
          print('✅ Printer ready');
          return true;

        case TelpoStatus.noPaper:
          await _showPrinterErrorDialog(
            'No Paper Found',
            'Please load paper into the printer and try again.',
            Icons.assignment,
          );
          await Future.delayed(Duration(milliseconds: 500));
          return false;

        case TelpoStatus.overHeat:
          await _showPrinterErrorDialog(
            'Printer Overheated',
            'The printer is too hot. Please wait for it to cool down before printing.',
            Icons.warning_amber,
          );
          return false;

        case TelpoStatus.cacheIsFull:
          await _showPrinterErrorDialog(
            'Printer Buffer Full',
            'The printer buffer is full. Please wait a moment and try again.',
            Icons.memory,
          );
          return false;

        case TelpoStatus.unknown:
          await _showPrinterErrorDialog(
            'Printer Error',
            'Failed! Please check if the device supports printing services and try again.',
            Icons.error_outline,
          );
          return false;
      }
    } catch (e) {
      print('❌ Error checking printer status: $e');
      await _showPrinterErrorDialog(
        'Printer Check Failed',
        'Unable to check printer status: ${e.toString()}',
        Icons.help_outline,
      );
      return false;
    }
  }

  // Helper method to show printer error dialogs
  Future<void> _showPrinterErrorDialog(String title, String message, IconData icon) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ColorsUniversal.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(icon, color: ColorsUniversal.buttonsColor, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: ColorsUniversal.buttonsColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Text(message, style: TextStyle(fontSize: 16, color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retry checking printer status
                _printReceipt();
              },
              child: Text(
                'Retry',
                style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method to get user-friendly print result messages
  String _getPrintResultMessage(PrintResult result) {
    switch (result) {
      case PrintResult.success:
        return 'Print successful';
      case PrintResult.noPaper: // Changed from PrintResult.values
        return 'No paper in printer';
      case PrintResult.lowBattery:
        return 'Printer battery low';
      case PrintResult.overHeat:
        return 'Printer overheated';
      case PrintResult.dataCanNotBeTransmitted:
        return 'Data transmission failed';
      case PrintResult.other:
        return 'Other printer error';
    }
  }

  // Helper dialog to show when sale isn't completed
  Future<bool> _showSaleNotCompletedDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Sale Not Completed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 48),
                  SizedBox(height: 16),
                  if (_apiCallInProgress)
                    Text('Sale is still being processed in the system. Please wait...')
                  else
                    Text('Sale failed to complete in the system: ${_apiError ?? "Unknown error"}'),
                  SizedBox(height: 16),
                  Text('Do you still want to print the receipt?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Print Anyway', style: TextStyle(color: ColorsUniversal.buttonsColor)),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if dialog is dismissed
  }

  // Helper method to wait for printer to finish
  Future<void> _waitForPrinterToFinish() async {
    final printer = TelpoFlutterChannel();
    int maxWaitTime = 30; // Maximum 30 seconds
    int waitCount = 0;

    while (waitCount < maxWaitTime) {
      try {
        final status = await printer.checkStatus();
        print('📊 Printer status: $status');

        // If printer is ready/ok, it's finished printing
        if (status == TelpoStatus.ok) {
          print('✅ Printer finished, ready for next receipt');
          await Future.delayed(Duration(milliseconds: 500)); // Small buffer
          return;
        }

        // If there's an error, stop waiting
        if (status == TelpoStatus.noPaper || status == TelpoStatus.overHeat) {
          print('❌ Printer error: $status');
          return;
        }
      } catch (e) {
        print('❌ Error checking printer status: $e');
      }

      // Wait 1 second before checking again
      await Future.delayed(Duration(seconds: 1));
      waitCount++;
    }

    print('⚠️ Max wait time reached, proceeding anyway');
  }

  // Get client price for a specific product (with fallback to station price)
  double getClientPriceForProduct(CartItem item) {
    if (widget.accountProducts == null) {
      print("❌ No account products available - using station price: ${item.price}");
      return item.price; // Fallback to station price
    }

    print("🔍 Looking for product ID: ${item.productId} (${item.productName})");

    final accountProduct = widget.accountProducts!.firstWhere(
      (p) => p.productVariationId == item.productId,
      orElse: () {
        print(
          "❌ Product '${item.productName}' (ID: ${item.productId}) not found in account - using station price: ${item.price}",
        );
        return ProductCardDetailsModel(
          productVariationId: 0,
          productVariationName: '',
          productCategoryId: 0,
          productCategoryName: '',
          productPrice: item.price, // Use station price as fallback
          productDiscount: 0,
        );
      },
    );

    // If product found in account, use account price; otherwise use station price
    if (accountProduct.productVariationId != 0) {
      print(
        "✅ Found in account: ${accountProduct.productVariationName} - Using account price: ${accountProduct.productPrice}",
      );
      return accountProduct.productPrice;
    } else {
      print("💰 Using station price for ${item.productName}: ${item.price}");
      return item.price;
    }
  }

  // Original station pricing total
  double getStationTotal() {
    return widget.cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Format product line for station pricing (cash sales)
  String formatStationProductLine(CartItem item) {
    final total = item.price * item.quantity;
    final name = item.productName.padRight(7).substring(0, 7);
    final price = item.price.toStringAsFixed(0).padLeft(5);
    final qty = item.quantity;
    final lineTotal = total.toStringAsFixed(0).padLeft(5);
    return "$name  $price  $qty  $lineTotal";
  }

  // Format product line for client pricing (card sales) with fallback
  String formatClientProductLine(CartItem item) {
    final clientPrice = getClientPriceForProduct(item); // Now passes the whole CartItem
    final total = clientPrice * item.quantity;
    final name = item.productName.padRight(7).substring(0, 7);
    final price = clientPrice.toStringAsFixed(0).padLeft(5);
    final qty = item.quantity;
    final lineTotal = total.toStringAsFixed(0).padLeft(5);
    return "$name  $price  $qty  $lineTotal";
  }

  void _showEndTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to make a choice
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Exit Page'),
        content: const Text('You will lose all progress if you exit from this page', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close dialog only
            },
            child: Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              CartStorage().clearCart();
              Navigator.of(dialogContext).pop(); // Close dialog first
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
                (route) => false,
              );
            },
            child: Text('OK', style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor)),
          ),
        ],
      ),
    );
  }

  //TR5250815063919
  @override
  Widget build(BuildContext context) {
    final TextStyle receiptStyle = const TextStyle(fontFamily: 'Courier', fontSize: 14);
    final TextStyle balanceStyle = const TextStyle(fontFamily: 'Courier', fontSize: 14, color: Colors.red);
    print(widget.refNumber);
    // Determine if this is a card sale
    final bool isCardSale = widget.showCardDetails && widget.clientTotal != null && widget.discount != null;

    // Calculate totals based on sale type
    final double totalAmount = isCardSale ? widget.clientTotal! : getStationTotal();
    final double discountAmount = isCardSale ? widget.discount! : 0.0;
    final double netTotal = totalAmount - discountAmount;
    final double change = isCardSale ? 0.0 : (widget.cashGiven - totalAmount);
    return PopScope(
      canPop: false, // Prevent default back navigation
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          // Show confirmation dialog when back button is pressed
          _showEndTransactionDialog(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sale Receipt', style: TextStyle(color: Colors.white70)),
          centerTitle: true,
          backgroundColor: ColorsUniversal.appBarColor,
          leading: IconButton(
            icon: const Icon(Icons.home, color: Colors.white70),
            onPressed: () {
              CartStorage().clearCart();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage(user: widget.user)),
                (route) => false,
              );
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      widget.companyName ?? 'SAHARA FCS',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Center(child: Text(widget.channelName ?? 'Station')),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('SALE', style: TextStyle(decoration: TextDecoration.underline)),
                  ),
                  const SizedBox(height: 8),
                  Text('TERM# ${widget.termNumber}', style: receiptStyle),
                  Text('REF# ${widget.refNumber}', style: receiptStyle),

                  const Divider(),

                  // Product listing header
                  Text('Prod    Price  Qty  Total', style: receiptStyle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),

                  // Product lines - different formatting for card vs cash
                  if (isCardSale) ...[
                    // CARD SALE: Show client pricing
                    ...widget.cartItems.map((item) => Text(formatClientProductLine(item), style: receiptStyle)),
                  ] else ...[
                    // CASH SALE: Show station pricing
                    ...widget.cartItems.map((item) => Text(formatStationProductLine(item), style: receiptStyle)),
                  ],

                  const Divider(),

                  // Totals section - different for card vs cash
                  if (isCardSale) ...[
                    // CARD SALE TOTALS
                    _row('Sub Total', totalAmount.toStringAsFixed(2), receiptStyle),
                    _row('Discount', discountAmount.toStringAsFixed(2), receiptStyle),
                    _row('Net Total', netTotal.toStringAsFixed(2), receiptStyle),

                    const Divider(),

                    _row('Card', netTotal.toStringAsFixed(2), receiptStyle),
                    if (widget.customerBalance != null)
                      _row('Balance', widget.customerBalance!.toStringAsFixed(2), balanceStyle),
                  ] else ...[
                    // CASH SALE TOTALS
                    _row('Sub Total', totalAmount.toStringAsFixed(2), receiptStyle),
                    _row('Total', totalAmount.toStringAsFixed(2), receiptStyle),
                    _row('Net Total', totalAmount.toStringAsFixed(2), receiptStyle),

                    const Divider(),

                    _row('Cash', widget.cashGiven.toStringAsFixed(2), receiptStyle),
                    _row('Change', change.toStringAsFixed(2), receiptStyle),
                  ],

                  const Divider(),

                  // Customer details (only for card sales)
                  if (widget.showCardDetails) ...[
                    _row('Customer:', widget.customerName, receiptStyle),
                    _row('Card No:', widget.card, receiptStyle),
                    _row('Account Type:', widget.accountType, receiptStyle),
                    if (widget.vehicleNumber.trim().isNotEmpty && widget.vehicleNumber != 'No Equipment')
                      _row('Vehicle:', widget.vehicleNumber, receiptStyle),
                    const Divider(),
                  ],

                  _row('Date', DateTime.now().toString().substring(0, 19), receiptStyle),
                  _row('Served By', widget.user.staffName, receiptStyle),
                  const Divider(),

                  // Approval section (only for card sales)
                  if (isCardSale) ...[
                    const Center(
                      child: Text('APPROVAL', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const Center(child: Text('Cardholder acknowledges receipt')),
                    const Center(child: Text('of goods/services in the amount')),
                    const Center(child: Text('shown above.')),
                    const SizedBox(height: 10),
                    const Center(child: Text('Cardholder Signature')),
                    const SizedBox(height: 4),
                  ],

                  const Center(
                    child: Text('THANK YOU', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Center(child: Text('CUSTOMER COPY')),
                  const SizedBox(height: 4),
                  const Center(child: Text('Powered by Sahara FCS', style: TextStyle(fontSize: 11))),
                  SizedBox(height: 10),
                  Center(
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: PrettyQrView.data(
                        data: 'https://www.tovutigroup.com/',
                        decoration: const PrettyQrDecoration(
                          // Customize as needed
                        ),
                      ),
                    ),
                  ),

                  // Test Print Button
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _printReceipt,
          backgroundColor: ColorsUniversal.buttonsColor,
          child: const Icon(Icons.print, color: Colors.white),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _row(String label, String value, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Expanded(
            child: Text(value, style: style, textAlign: TextAlign.right, softWrap: true),
          ),
        ],
      ),
    );
  }
}
