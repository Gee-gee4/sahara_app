// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/payment_mode_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
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

  List<CartItem> get cartItems => CartStorage().cartItems;

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

  // Add this method to your class for the cash payment dialog
  void _showCashPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final TextEditingController _cashController = TextEditingController();
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: ColorsUniversal.background,
              title: Text('Custom Amount', style: TextStyle(fontWeight: FontWeight.w500)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount Due:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      Text('Ksh ${CartStorage().getTotalPrice().toStringAsFixed(2)}', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  TextField(
                    controller: _cashController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Enter Amount Received',
                      errorText: errorText,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                    ),
                    cursorColor: ColorsUniversal.buttonsColor,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
                  onPressed: () async {
                    final entered = _cashController.text.trim();
                    final total = CartStorage().getTotalPrice();

                    if (entered.isEmpty) {
                      setState(() => errorText = 'Amount is required');
                      return;
                    }

                    final amount = double.tryParse(entered);
                    if (amount == null || amount < total) {
                      setState(() => errorText = 'Amount must be at least Ksh ${total.toStringAsFixed(0)}');
                      return;
                    }
                    final prefs = await SharedPreferences.getInstance();
                    final companyName = prefs.getString('companyName') ?? 'SAHARA FCS';
                    final channelName = prefs.getString('channelName') ?? 'CMB Station';
                    Navigator.pop(context); // close this dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptPrint(
                          user: widget.user,
                          cartItems: cartItems,
                          cashGiven: amount,
                          customerName: '',
                          card: '',
                          accountType: '',
                          vehicleNumber: '',
                          showCardDetails: false,
                          companyName: companyName,
                          channelName: channelName,
                        ),
                      ),
                    );
                  },
                  child: Text('OK', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );
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
                  'Total: Ksh ${CartStorage().getTotalPrice().toStringAsFixed(0)}',
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

                  // 🔍 Get the selected payment mode from Hive
                  final box = Hive.box('payment_modes');
                  final savedModes = box.get('acceptedModes', defaultValue: <Map<String, dynamic>>[]);

                  PaymentModeModel? selectedMode;
                  for (var modeMap in savedModes) {
                    final mode = PaymentModeModel.fromJson(modeMap);
                    if (mode.payModeDisplayName == selectedPaymentMode) {
                      selectedMode = mode;
                      break;
                    }
                  }

                  // 💳 Check if Internal Card is selected
                  if (selectedMode != null && selectedMode.payModeCategory == 'Internal Card') {
                    // Navigate directly to card sales
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TapCardPage(user: widget.user, action: TapCardAction.cardSales, cartItems: cartItems),
                      ),
                    );
                    return;
                  }

                  // 💰 For all other payment modes (Cash, etc.) - show the card dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Tap Card', style: TextStyle(fontSize: 22)),
                      content: Text('Do you have a card?', style: TextStyle(fontSize: 20)),
                      actions: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
                          onPressed: () {
                            Navigator.pop(context);
                            // Show cash payment dialog
                            _showCashPaymentDialog(context);
                          },
                          child: Text('NO', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TapCardPage(
                                  user: widget.user,
                                  action: TapCardAction.cashCardSales,
                                  cartItems: cartItems,
                                ),
                              ),
                            );
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
