// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/helpers/ref_generator.dart';
import 'package:sahara_app/models/payment_mode_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/sale_service.dart';
import 'package:sahara_app/pages/pos_settings_form.dart';
import 'package:sahara_app/pages/receipt_print.dart';
import 'package:sahara_app/pages/tap_card_page.dart';
import 'package:sahara_app/services/services/nfc/nfc_service_factory.dart';
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

  // check current mode
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

  // builds a cart item for AUTO mode
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

              //quantity display no +/-
              SizedBox(
                width: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Quantity', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.brown[200]),
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
                    Text('Total', style: TextStyle(fontSize: 12, color: Colors.black54)),
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

  // builds a cart item for MANUAL mode has +&-
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

              // Quantity
              SizedBox(
                width: 140,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: Colors.brown[200]),
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
                    Text('Amt: ${total.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w500)),
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

  //cash payment dialog
  void _showCashPaymentDialog(BuildContext context) {
  final double total = CartStorage().getTotalPrice();
  final TextEditingController _cashController = TextEditingController(text: total.toStringAsFixed(0));

  // Get the selected payment mode details
  final box = Hive.box('payment_modes');
  final rawModes = box.get('acceptedModes', defaultValue: []);
  final savedModes = (rawModes as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .map((e) => PaymentModeModel.fromJson(e))
      .toList();

  PaymentModeModel? selectedMode;
  for (var mode in savedModes) {
    if (mode.payModeDisplayName == selectedPaymentMode) {
      selectedMode = mode;
      break;
    }
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      String? errorText;
      bool isProcessing = false;
      String? currentRefNumber; // Track the current reference number

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: ColorsUniversal.background,
            title: Text('${selectedPaymentMode ?? "Cash"} Payment', style: TextStyle(fontWeight: FontWeight.w500)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Amount Due:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    Text('Ksh ${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 18)),
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
                if (isProcessing)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(color: ColorsUniversal.buttonsColor),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () {
                  Navigator.pop(context);
                },
                child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
                onPressed: isProcessing ? null : () async {
                  final entered = _cashController.text.trim();
                  if (entered.isEmpty) {
                    setState(() => errorText = 'Amount is required');
                    return;
                  }

                  final amount = double.tryParse(entered);
                  if (amount == null || amount < total) {
                    setState(() => errorText = 'Amount must be at least Ksh ${total.toStringAsFixed(0)}');
                    return;
                  }

                  setState(() => isProcessing = true);

                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final companyName = prefs.getString('companyName') ?? 'SAHARA FCS';
                    final channelName = prefs.getString('channelName') ?? 'Station';
                    final termNumber = prefs.getString('termNumber') ?? '8b7118e04fecbaf2';
                    
                    // 🔄 Generate NEW reference number for each attempt
                    final refNumber = await RefGenerator.generate();
                    currentRefNumber = refNumber;

                    print("🎯 Final data for Cash-Only sale:");
                    print("💰 Payment: ${selectedMode?.payModeDisplayName ?? 'Cash'} (${amount})");
                    print("🆔 Payment Mode ID: ${selectedMode?.payModeId ?? 1}");
                    print("🔢 Reference Number: $refNumber");
                    print("📝 No card data (cash-only)");

                    // ✅ Complete the sale with NEW ref number
                    final saleResponse = await SaleService.completeSale(
                      refNumber: refNumber,
                      cartItems: cartItems,
                      user: widget.user,
                      isCardSale: false,
                      cashGiven: amount,
                      paymentModeId: selectedMode?.payModeId ?? 2,
                      paymentModeName: selectedMode?.payModeDisplayName ?? 'Cash',
                    );

                    if (!saleResponse.isSuccessfull) {
                      setState(() => isProcessing = false);
                      
                      // 🔍 Check if it's a duplicate key error (sale might have succeeded)
                      if (saleResponse.message.contains('duplicate key') || 
                          saleResponse.message.contains('IX_Finance_Transaction')) {
                        // Show success message since the sale was actually completed
                        Navigator.pop(context); // close dialog
                        
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Sale Completed', style: TextStyle(color: Colors.green)),
                            content: Text('Your sale was successfully processed. The system detected a duplicate transaction, which means your sale went through properly.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Navigate to receipt with the current ref number
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReceiptPrint(
                                        user: widget.user,
                                        cartItems: cartItems,
                                        cashGiven: amount,
                                        customerName: 'Cash Customer', 
                                        card: 'N/A',
                                        accountType: 'Cash Sale',
                                        vehicleNumber: 'N/A',
                                        showCardDetails: false,
                                        companyName: companyName,
                                        channelName: channelName,
                                        refNumber: currentRefNumber ?? refNumber,
                                        termNumber: termNumber,
                                        cardUID: null,
                                        customerAccountNo: null,
                                        discount: null,
                                        clientTotal: null,
                                        customerBalance: null,
                                        accountProducts: null,
                                        paymentModeId: selectedMode?.payModeId ?? 2,
                                        paymentModeName: selectedMode?.payModeDisplayName ?? 'Cash',
                                      ),
                                    ),
                                  );
                                },
                                child: Text('View Receipt'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      
                      if (saleResponse.message.contains('No Internet Connectivity')) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: Text('No Internet'),
                            content: Text('Internet connection is required to complete the sale. Please check your connection and try again.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Sale Failed'),
                            content: Text('Failed to complete sale: ${saleResponse.message}'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                      return;
                    }

                    // ✅ Sale successful - navigate to receipt
                    Navigator.pop(context); // close dialog

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptPrint(
                          user: widget.user,
                          cartItems: cartItems,
                          cashGiven: amount,
                          customerName: 'Cash Customer', 
                          card: 'N/A',
                          accountType: 'Cash Sale',
                          vehicleNumber: 'N/A',
                          showCardDetails: false,
                          companyName: companyName,
                          channelName: channelName,
                          refNumber: refNumber,
                          termNumber: termNumber,
                          cardUID: null,
                          customerAccountNo: null,
                          discount: null,
                          clientTotal: null,
                          customerBalance: null,
                          accountProducts: null,
                          paymentModeId: selectedMode?.payModeId ?? 2,
                          paymentModeName: selectedMode?.payModeDisplayName ?? 'Cash',
                        ),
                      ),
                    );

                  } catch (e) {
                    setState(() => isProcessing = false);
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Error'),
                        content: Text('An unexpected error occurred: $e'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
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
        title: Text('My Cart ${currentMode == OperationMode.auto ? "" : ""}', style: TextStyle(color: Colors.white70)),
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

                  // show different cart item based on current mode
                  return currentMode == OperationMode.auto
                      ? _buildAutoModeCartItem(item, index)
                      : _buildManualModeCartItem(item, index);
                },
              ),
            ),

            // Total and checkout section
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

            // Payment and checkout section
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
                  // Check if cart is empty
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

                  // Check if payment mode is not selected
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

                  //Get the selected payment mode from Hive
                  final box = Hive.box('payment_modes');
                  final rawModes = box.get('acceptedModes', defaultValue: []);

                  //converts the dynamic list to a list of PaymentModeModel
                  final savedModes = (rawModes as List)
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .map((e) => PaymentModeModel.fromJson(e))
                      .toList();

                  PaymentModeModel? selectedMode;
                  for (var mode in savedModes) {
                    if (mode.payModeDisplayName == selectedPaymentMode) {
                      selectedMode = mode;
                      break;
                    }
                  }

                  // Check if Internal Card is selected
                  if (selectedMode != null && selectedMode.payModeCategory == 'Internal Card') {
                    // Navigate to card sales
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TapCardPage(user: widget.user, action: TapCardAction.cardSales, cartItems: cartItems),
                      ),
                    );
                    return;
                  }
                  if (selectedMode == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected payment mode not found. Please re-sync.'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.grey,
                      ),
                    );
                    return;
                  }

                  //  For all other payment modes shows the card dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
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
                                  selectedPaymentMode: selectedPaymentMode,
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
