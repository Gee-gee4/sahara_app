// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String? selectedPaymentMode;
  List<String> paymentModes = [];

  double getTotalPrice() {
    return CartStorage.cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPaymentModes();
  }

  void _loadPaymentModes() {
    final box = Hive.box('payment_modes');
    final savedModes = box.get('acceptedModes') as List?;

    if (savedModes != null) {
      final names = savedModes
          .map((e) => e['payModeDisplayName'] as String)
          .toList();

      setState(() {
        paymentModes = names;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = CartStorage.cartItems;
    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart', style: TextStyle(color: Colors.white70)),
        centerTitle: true,
        backgroundColor: ColorsUniversal.appBarColor,
        iconTheme: IconThemeData(color: Colors.white70),
        actions: [
          TextButton(
            onPressed: () {
              cartItems.isNotEmpty
                  ? setState(() {
                      CartStorage.clearCart();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: hexToColor('8f9c68'),
                          content: Text('Successfully cleared cart'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    })
                  : ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.grey,
                        content: Text('Cart is empty!'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                  final total = item.price * item.quantity;
                  return Card(
                    color: Colors.brown[100],
                    child: SizedBox(
                      width: double.infinity,
                      height: 100,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  'Ksh ${item.price}',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 40,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    color: Colors.brown[200],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (item.quantity > 1) {
                                              item.quantity--;
                                            }
                                          });
                                        },
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
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
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Amt: ${total.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      cartItems.removeAt(index); // ✅ Delete item
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: hexToColor('8f9c68'),
                                          content: Text(
                                            'Successfully deleted product',
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
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
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Total: Ksh ${getTotalPrice().toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPaymentMode,
                  decoration: InputDecoration(
                    labelText: 'Select Payment Mode',
                    labelStyle: TextStyle(color: ColorsUniversal.buttonsColor),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: ColorsUniversal.buttonsColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: hexToColor('8f9c68'),
                        width: 2,
                      ), // selected border
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
                  validator: (value) =>
                      value == null ? 'Please select a payment mode' : null,
                ),

                SizedBox(height: 10),
                myButton(context, () {
                  if (selectedPaymentMode == null || selectedPaymentMode!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select a payment mode'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // ✅ Show success dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text('Checked Out!'),
                      content: Text(
                        'You have checked out using "$selectedPaymentMode".',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Go back
                          },
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                }, 'Check Out'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
