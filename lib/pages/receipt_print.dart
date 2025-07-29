// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/product_card_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class ReceiptPrint extends StatelessWidget {
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
  });

  // Get client price for a specific product (with fallback to station price)
  double getClientPriceForProduct(CartItem item) {
    if (accountProducts == null) {
      print("❌ No account products available - using station price: ${item.unitPrice}");
      return item.unitPrice; // Fallback to station price
    }

    print("🔍 Looking for product ID: ${item.productId} (${item.name})");

    final accountProduct = accountProducts!.firstWhere(
      (p) => p.productVariationId == item.productId,
      orElse: () {
        print(
          "❌ Product '${item.name}' (ID: ${item.productId}) not found in account - using station price: ${item.unitPrice}",
        );
        return ProductCardDetailsModel(
          productVariationId: 0,
          productVariationName: '',
          productCategoryId: 0,
          productCategoryName: '',
          productPrice: item.unitPrice, // Use station price as fallback
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
      print("💰 Using station price for ${item.name}: ${item.unitPrice}");
      return item.unitPrice;
    }
  }

  // Original station pricing total
  double getStationTotal() {
    return cartItems.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  // Format product line for station pricing (cash sales)
  String formatStationProductLine(CartItem item) {
    final total = item.unitPrice * item.quantity;
    final name = item.name.padRight(7).substring(0, 7);
    final price = item.unitPrice.toStringAsFixed(0).padLeft(5);
    final qty = item.quantity;
    final lineTotal = total.toStringAsFixed(0).padLeft(5);
    return "$name  $price  $qty  $lineTotal";
  }

  // Format product line for client pricing (card sales) with fallback
  String formatClientProductLine(CartItem item) {
    final clientPrice = getClientPriceForProduct(item); // Now passes the whole CartItem
    final total = clientPrice * item.quantity;
    final name = item.name.padRight(7).substring(0, 7);
    final price = clientPrice.toStringAsFixed(0).padLeft(5);
    final qty = item.quantity;
    final lineTotal = total.toStringAsFixed(0).padLeft(5);
    return "$name  $price  $qty  $lineTotal";
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle receiptStyle = TextStyle(fontFamily: 'Courier', fontSize: 14);
    final TextStyle balanceStyle = TextStyle(fontFamily: 'Courier', fontSize: 14, color: Colors.red);

    // Determine if this is a card sale
    final bool isCardSale = showCardDetails && clientTotal != null && discount != null;

    // Calculate totals based on sale type
    final double totalAmount = isCardSale ? clientTotal! : getStationTotal();
    final double discountAmount = isCardSale ? discount! : 0.0;
    final double netTotal = totalAmount - discountAmount;
    final double change = isCardSale ? 0.0 : (cashGiven - totalAmount);

    void _showEndTransactionDialog(BuildContext context) {
      showDialog(
        context: context,
        barrierDismissible: false, // Force user to make a choice
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text('Exit Page'),
          content: Text('You will lose all progress if you exit from this page', style: TextStyle(fontSize: 16)),
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
                  MaterialPageRoute(builder: (_) => HomePage(user: user)),
                  (route) => false,
                );
              },
              child: Text('OK', style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor)),
            ),
          ],
        ),
      );
    }

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
                MaterialPageRoute(builder: (context) => HomePage(user: user)),
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
                    child: Text(companyName ?? 'SAHARA FCS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Center(child: Text(channelName ?? 'CMB Station')),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('SALE', style: TextStyle(decoration: TextDecoration.underline)),
                  ),
                  const SizedBox(height: 8),
                  Text('TERM# 8458cn34e3kf343', style: receiptStyle),
                  Text('REF# TR45739547549219', style: receiptStyle),

                  Divider(),

                  // Product listing header
                  Text('Prod    Price  Qty  Total', style: receiptStyle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),

                  // Product lines - different formatting for card vs cash
                  if (isCardSale) ...[
                    // CARD SALE: Show client pricing
                    ...cartItems.map((item) => Text(formatClientProductLine(item), style: receiptStyle)),
                  ] else ...[
                    // CASH SALE: Show station pricing
                    ...cartItems.map((item) => Text(formatStationProductLine(item), style: receiptStyle)),
                  ],

                  Divider(),

                  // Totals section - different for card vs cash
                  if (isCardSale) ...[
                    // CARD SALE TOTALS
                    _row('Sub Total', totalAmount.toStringAsFixed(2), receiptStyle),
                    _row('Discount', discountAmount.toStringAsFixed(2), receiptStyle),
                    _row('Net Total', netTotal.toStringAsFixed(2), receiptStyle),

                    Divider(),

                    _row('Card', netTotal.toStringAsFixed(2), receiptStyle),
                    if (customerBalance != null) _row('Balance', customerBalance!.toStringAsFixed(2), balanceStyle),
                  ] else ...[
                    // CASH SALE TOTALS
                    _row('Sub Total', totalAmount.toStringAsFixed(2), receiptStyle),
                    _row('Total', totalAmount.toStringAsFixed(2), receiptStyle),
                    _row('Net Total', totalAmount.toStringAsFixed(2), receiptStyle),

                    Divider(),

                    _row('Cash', cashGiven.toStringAsFixed(2), receiptStyle),
                    _row('Change', change.toStringAsFixed(2), receiptStyle),
                  ],

                  Divider(),

                  // Customer details (only for card sales)
                  if (showCardDetails) ...[
                    _row('Customer:', customerName, receiptStyle),
                    _row('Card No:', card, receiptStyle),
                    _row('Account Type:', accountType, receiptStyle),
                    if (vehicleNumber.trim().isNotEmpty && vehicleNumber != 'No Equipment')
                      _row('Vehicle:', vehicleNumber, receiptStyle),
                    Divider(),
                  ],

                  _row('Date', DateTime.now().toString().substring(0, 19), receiptStyle),
                  _row('Served By', user.staffName, receiptStyle),
                  Divider(),

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
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: ColorsUniversal.buttonsColor,
          child: Icon(Icons.print, color: Colors.white),
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
