import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/home_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';

class ReceiptPrint extends StatelessWidget {
  final StaffListModel user;
  final List<CartItem> cartItems;
  final double cashGiven;

  const ReceiptPrint({super.key, required this.user, required this.cartItems, required this.cashGiven});

  double getTotal() {
    return cartItems.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  String formatProductLine(CartItem item) {
    final total = item.unitPrice * item.quantity;
    final name = item.name.padRight(7).substring(0, 7);
    final price = item.unitPrice.toStringAsFixed(0).padLeft(5);
    final qty = item.quantity;
    final lineTotal = total.toStringAsFixed(0).padLeft(5);
    return "$name  $price  $qty  $lineTotal";
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle receiptStyle = TextStyle(fontFamily: 'Courier', fontSize: 14);
    final double totalAmount = getTotal();
    final double change = cashGiven - totalAmount;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Receipt', style: TextStyle(color: Colors.white70)),
        centerTitle: true,
        backgroundColor: ColorsUniversal.appBarColor,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white70),
          onPressed: () {
            CartStorage.clearCart();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomePage(user: user)),
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
                const Center(
                  child: Text('SAHARA FCS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Center(child: Text('CMB Station')),
                const SizedBox(height: 8),
                const Center(
                  child: Text('SALE', style: TextStyle(decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 8),
                Text('TERM# 8458cn34e3kf343', style: receiptStyle),
                Text('REF# TR45739547549219', style: receiptStyle),
        
                Divider(),
        
                Text('Prod    Price  Qty  Total', style: receiptStyle.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...cartItems.map((item) => Text(formatProductLine(item), style: receiptStyle)),
        
                Divider(),
        
                _row('Sub Total', totalAmount.toStringAsFixed(2), receiptStyle),
                _row('Total', totalAmount.toStringAsFixed(2), receiptStyle),
                _row('Net Total', totalAmount.toStringAsFixed(2), receiptStyle),
        
                Divider(),
        
                _row('Cash', cashGiven.toStringAsFixed(2), receiptStyle), // We'll inject real amount below
                _row('Change', change.toStringAsFixed(2), receiptStyle),
        
                Divider(),
        
                _row('Date', DateTime.now().toString().substring(0, 19), receiptStyle),
                Text('Served By ${user.staffName}', style: receiptStyle),
        
                Divider(),
        
                const Center(
                  child: Text('APPROVAL', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Center(child: Text('Cardholder acknowledges receipt')),
                const Center(child: Text('of goods/services in the amount')),
                const Center(child: Text('shown above.')),
        
                const SizedBox(height: 10),
                const Center(child: Text('Cardholder Signature')),
                const SizedBox(height: 4),
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
        child: Icon(Icons.print,color: Colors.white,)
      ),

      // Position the FAB properly
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _row(String label, String value, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
