// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/receipt_print.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.user});
  final StaffListModel user;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String? selectedPaymentMode;
  List<String> paymentModes = [];

  double getTotalPrice() {
    return CartStorage().cartItems.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));
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
      final names = savedModes.map((e) => e['payModeDisplayName'] as String).toList();

      setState(() {
        paymentModes = names;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = CartStorage().cartItems;
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
                  final total = item.unitPrice * item.quantity;
                  return Card(
                    color: Colors.brown[100],
                    child: SizedBox(
                      width: double.infinity,
                      height: 105,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                        child: Row(
                          children: [
                            // Product name & price - give it a fixed or max width
                            SizedBox(
                              width: 90,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                                  ),
                                  Text('Ksh ${item.unitPrice}', style: TextStyle(color: Colors.black54)),
                                ],
                              ),
                            ),

                            // Quantity container – fixed width
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
                                              CartStorage().decrementQuantity(item.name);
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
                            SizedBox(width: 5),
                            // Amount & delete – fixed width
                            SizedBox(
                              width: 80,
                              child: Column(
                                // crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Amt: ${total.toStringAsFixed(0)}',
                                        style: TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ],
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
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ColorsUniversal.buttonsColor, width: 2), // selected border
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
                  // 🔒 Check if cart is empty
                  if (CartStorage().cartItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please add some products to checkout!'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // 🔒 Check if payment mode is not selected
                  if (selectedPaymentMode == null || selectedPaymentMode!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select a payment mode'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // ✅ Show success dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Cash', style: TextStyle(fontSize: 22)),
                      content: Text('Do you have a card?', style: TextStyle(fontSize: 20)),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (context) {
                                final TextEditingController _cashController = TextEditingController();
                                String? errorText;
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: Text('Amount', style: TextStyle(fontSize: 22)),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: _cashController,
                                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                                            decoration: InputDecoration(
                                              labelText: 'Enter Amount',
                                              errorText: errorText,
                                              labelStyle: TextStyle(color: Colors.brown[300]),
                                              focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(color: ColorsUniversal.buttonsColor),
                                              ),
                                            ),
                                            cursorColor: ColorsUniversal.buttonsColor,
                                            style: TextStyle(color: ColorsUniversal.buttonsColor),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: ColorsUniversal.buttonsColor,
                                          ),
                                          onPressed: () {
                                            final entered = _cashController.text.trim();
                                            final total = getTotalPrice();

                                            if (entered.isEmpty) {
                                              setState(() => errorText = 'Amount is required');
                                              print("Error text: $errorText");
                                              return;
                                            }

                                            final amount = double.tryParse(entered);
                                            if (amount == null || amount < total) {
                                              setState(
                                                () => errorText =
                                                    'Amount must be at least Ksh ${total.toStringAsFixed(0)}',
                                              );
                                              print("Error text: $errorText");
                                              return;
                                            }

                                            Navigator.pop(context); // close this dialog
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ReceiptPrint(
                                                  user: widget.user,
                                                  cartItems: cartItems,
                                                  cashGiven: amount,
                                                ),
                                              ),
                                            );
                                            // CartStorage().clearCart();
                                          },
                                          child: Text('OK', style: TextStyle(color: Colors.white, fontSize: 16)),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                          child: Text('NO', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16)),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Go back
                            CartStorage().clearCart();
                          },
                          child: Text('YES', style: TextStyle(color: Colors.white, fontSize: 16)),
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
