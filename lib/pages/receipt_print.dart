// lib/pages/receipt_print.dart
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/helpers/printer/printer_helper.dart';
import 'package:sahara_app/models/product_card_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/sale_service.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';

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
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
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
        customerName: widget.customerName.isNotEmpty ? widget.customerName : null,
        customerUID: widget.cardUID,
        customerAccountNo: widget.customerAccountNo,
        customerAccountBalance: widget.customerBalance,
        accountProducts: isCardSale ? widget.accountProducts : null,
        cashGiven: !isCardSale ? widget.cashGiven : null,
        change: !isCardSale ? (widget.cashGiven - getStationTotal()) : null,
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
          print('❌ Sale transaction failed: ${_apiError}');
        }
      });

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
  if (_isPrinting) return; // Prevent multiple clicks
  
  setState(() {
    _isPrinting = true;
  });

  try {
    await PrinterHelper.printReceipt(
      context: context,
      user: widget.user,
      cartItems: widget.cartItems,
      cashGiven: widget.cashGiven,
      customerName: widget.customerName,
      card: widget.card,
      accountType: widget.accountType,
      vehicleNumber: widget.vehicleNumber,
      showCardDetails: widget.showCardDetails,
      refNumber: widget.refNumber,
      termNumber: widget.termNumber,
      discount: widget.discount,
      clientTotal: widget.clientTotal,
      customerBalance: widget.customerBalance,
      accountProducts: widget.accountProducts,
      companyName: widget.companyName,
      channelName: widget.channelName,
      saleCompleted: _saleCompleted,
      apiCallInProgress: _apiCallInProgress,
      apiError: _apiError,
    );
  } finally {
    if (mounted) {
      setState(() {
        _isPrinting = false;
      });
    }
  }
}

  // Get client price for a specific product (with fallback to station price)
  double getClientPriceForProduct(CartItem item) {
    if (widget.accountProducts == null) {
      return item.price;
    }

    final accountProduct = widget.accountProducts!.firstWhere(
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

    return accountProduct.productVariationId != 0 ? accountProduct.productPrice : item.price;
  }

  // Original station pricing total
  double getStationTotal() {
    return widget.cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Format product line for station pricing (cash sales)
  String formatStationProductLine(CartItem item) {
    final total = item.price * item.quantity;
    final name = item.productName.padRight(7).substring(0, 7);
    final price = item.price.toStringAsFixed(0).padLeft(4);
    final qty = item.quantity.toStringAsFixed(2);
    final lineTotal = total.toStringAsFixed(0).padLeft(6);
    return "$name  $price  $qty  $lineTotal";
  }

  // Format product line for client pricing (card sales) with fallback
  String formatClientProductLine(CartItem item) {
    final clientPrice = getClientPriceForProduct(item);
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
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Exit Page'),
        content: const Text(
          'You will lose all progress if you exit from this page',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              CartStorage().clearCart();
              Navigator.of(dialogContext).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
                (route) => false,
              );
            },
            child: Text(
              'OK',
              style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle receiptStyle = const TextStyle(fontFamily: 'Courier', fontSize: 14);
    final TextStyle balanceStyle = const TextStyle(fontFamily: 'Courier', fontSize: 14, color: Colors.red);

    // Determine if this is a card sale
    final bool isCardSale = widget.showCardDetails && widget.clientTotal != null && widget.discount != null;

    // Calculate totals based on sale type
    final double totalAmount = isCardSale ? widget.clientTotal! : getStationTotal();
    final double discountAmount = isCardSale ? widget.discount! : 0.0;
    final double netTotal = totalAmount - discountAmount;
    final double change = isCardSale ? 0.0 : (widget.cashGiven - totalAmount);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
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
                  Text('Prod    Price  Qty    Total', style: receiptStyle.copyWith(fontWeight: FontWeight.bold)),
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
                  
                  // QR Code (only on screen, not printed)
                  Center(
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: PrettyQrView.data(
                        data: 'https://www.tovutigroup.com/',
                        decoration: const PrettyQrDecoration(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isPrinting ? null : _printReceipt,
          backgroundColor:_isPrinting ? Colors.grey : ColorsUniversal.buttonsColor,
          child: _isPrinting ?CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ) : Icon(Icons.print, color: Colors.white),
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