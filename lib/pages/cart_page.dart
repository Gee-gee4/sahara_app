// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/payment_mode_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/pos_settings_form.dart';
import 'package:sahara_app/pages/receipt_print.dart';
import 'package:sahara_app/pages/settings_page.dart';
import 'package:sahara_app/pages/tap_card_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.user});
  final StaffListModel user;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String? selectedPaymentMode;
  List<String> paymentModes = [];
  OperationMode currentMode = OperationMode.manual;

  List<CartItem> get cartItems => CartStorage().cartItems;

  @override
  void initState() {
    super.initState();
    _loadPaymentModes();
    _loadCurrentMode();
  }

  // ✅ Add method to check current mode
  Future<void> _loadCurrentMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('operationMode') ?? 'manual';
    setState(() {
      currentMode = mode == 'auto' ? OperationMode.auto : OperationMode.manual;
    });
  }

  void _loadPaymentModes() {
    final box = Hive.box('payment_modes');
    final savedModes = box.get('acceptedModes') as List?;

    if (savedModes != null) {
      final names = savedModes.map((e) => e['payModeDisplayName'] as String).toList();

      setState(() {
        paymentModes = names;
      });
    }
  }

  // ✅ Build cart item for AUTO mode (no quantity controls)
  Widget _buildAutoModeCartItem(CartItem item, int index) {
    final total = item.price * item.quantity;
    return Card(
      color: Colors.brown[100],
      child: SizedBox(
        width: double.infinity,
        height: 105,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: Row(
            children: [
              // Product name & price
              SizedBox(
                width: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                    ),
                    Text('Ksh ${item.price}/L', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),

              // Fixed quantity display (no controls)
              SizedBox(
                width: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Quantity', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.brown[200],
                      ),
                      child: Text(
                        '${item.quantity.toStringAsFixed(2)}L',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // Total & delete
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      'Ksh ${total.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          cartItems.removeAt(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: hexToColor('8f9c68'),
                              content: Text('Successfully deleted product'),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        });
                      },
                      icon: Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Build cart item for MANUAL mode (with quantity controls)
  Widget _buildManualModeCartItem(CartItem item, int index) {
    final total = item.price * item.quantity;
    return Card(
      color: Colors.brown[100],
      child: SizedBox(
        width: double.infinity,
        height: 105,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: Row(
            children: [
              // Product name & price
              SizedBox(
                width: 90,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                    ),
                    Text('Ksh ${item.price}', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),

              // Quantity controls
              SizedBox(
                width: 140,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.brown[200],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                CartStorage().decrementQuantity(item.productId);
                              });
                            },
                          ),
                          Text(item.quantity.toStringAsFixed(2)),
                          IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setState(() {
                                item.quantity++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Amount & delete
              SizedBox(
                width: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Amt: ${total.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          cartItems.removeAt(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: hexToColor('8f9c68'),
                              content: Text('Successfully deleted product'),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        });
                      },
                      icon: Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = CartStorage().cartItems;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Cart ${currentMode == OperationMode.auto ? "(Auto Mode)" : "(Manual Mode)"}',
          style: TextStyle(color: Colors.white70),
        ),
        centerTitle: true,
        backgroundColor: ColorsUniversal.appBarColor,
        iconTheme: IconThemeData(color: Colors.white70),
        actions: [
          TextButton(
            onPressed: () {
              cartItems.isNotEmpty
                  ? setState(() {
                      CartStorage().clearCart();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: hexToColor('8f9c68'),
                          content: Text('Successfully cleared cart'),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    })
                  : ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.grey,
                        content: Text('Cart is empty!'),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
            },
            child: Text('Clear All', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  
                  // ✅ Show different cart item based on current mode
                  return currentMode == OperationMode.auto
                      ? _buildAutoModeCartItem(item, index)
                      : _buildManualModeCartItem(item, index);
                },
              ),
            ),
            
            // Total and checkout section (same for both modes)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Total: Ksh ${CartStorage().getTotalPrice().toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            // Payment and checkout section (same for both modes)
            Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPaymentMode,
                  decoration: InputDecoration(
                    labelText: 'Select Payment Mode',
                    labelStyle: TextStyle(color: ColorsUniversal.buttonsColor),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ColorsUniversal.buttonsColor, width: 2),
                    ),
                  ),
                  items: paymentModes.map((mode) {
                    return DropdownMenuItem<String>(value: mode, child: Text(mode));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMode = value!;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a payment mode' : null,
                ),
                SizedBox(height: 10),
                myButton(context, () {
                  // Your existing checkout logic remains the same...
                }, 'Check Out'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
