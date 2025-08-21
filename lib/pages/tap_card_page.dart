// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/helpers/ref_generator.dart';
import 'package:sahara_app/helpers/uid_converter.dart';
import 'package:sahara_app/models/customer_account_details_model.dart';
import 'package:sahara_app/models/payment_mode_model.dart';
import 'package:sahara_app/models/product_card_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/modules/complete_card_init_service.dart';
import 'package:sahara_app/modules/customer_account_details_service.dart';
import 'package:sahara_app/modules/initialize_card_service.dart';
import 'package:sahara_app/modules/ministatement_service.dart';
import 'package:sahara_app/modules/nfc_functions.dart';
import 'package:sahara_app/modules/top_up_service.dart';
import 'package:sahara_app/pages/card_details_page.dart';
import 'package:sahara_app/pages/mini_statement_page.dart';
import 'package:sahara_app/pages/receipt_print.dart';
import 'package:sahara_app/pages/settings_page.dart';
import 'package:sahara_app/pages/top_up_page.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TapCardPage extends StatefulWidget {
  const TapCardPage({
    super.key,
    required this.user,
    required this.action,
    this.extraData,
    this.cartItems,
    this.selectedPaymentMode,
    this.topUpAmount,
  });
  final StaffListModel user;
  final TapCardAction action;
  final Map<String, String>? extraData;
  final List<CartItem>? cartItems;
  final String? selectedPaymentMode;
  final double? topUpAmount;

  @override
  State<TapCardPage> createState() => _TapCardPageState();
}

class _TapCardPageState extends State<TapCardPage> {
  void showLoadingSpinner(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: SpinKitCircle(
          size: 70,
          duration: Duration(milliseconds: 1000),
          itemBuilder: (context, index) {
            final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
            return DecoratedBox(
              decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle),
            );
          },
        ),
      ),
    );
  }

  //CASH AND CARD SALE
  Future<void> _handleCardSale(BuildContext context) async {
    final nfc = NfcFunctions();
    String? cardUID; // Declare variable to store card UID

    showLoadingSpinner(context); // Shows the spinner

    try {
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 8));
      cardUID = UIDConverter.convertToPOSFormat(tag.id); // CAPTURE THE CARD UID

      print("🎯 Card UID: $cardUID"); // Debug print

      // Step 1: Try to read account number from card
      final accountResult = await nfc.readSectorBlock(sectorIndex: 1, blockSectorIndex: 0, useDefaultKeys: false);

      // Step 2: Check if account read was successful
      if (accountResult.status != NfcMessageStatus.success) {
        if (context.mounted) Navigator.pop(context); // Hide spinner

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card data. Please try again.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return; // STOP - Do not proceed
      }

      // Step 3: Extract and validate account number
      final accountNo = accountResult.data.replaceAll(RegExp(r'[^0-9]'), '');

      // Check if account number is valid (not empty, null, or 0)
      if (accountNo.isEmpty || accountNo == '0') {
        if (context.mounted) Navigator.pop(context); // Hide spinner

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card data. Please try again.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return; // STOP - Do not proceed
      }

      // Step 4: Try to read PIN from card
      final pinResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

      // Step 5: Check if PIN read was successful
      if (pinResult.status != NfcMessageStatus.success) {
        if (context.mounted) Navigator.pop(context); // Hide spinner

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card data. Please try again.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return; // STOP - Do not proceed
      }

      // Step 6: Fetch customer account details
      final accountData = await CustomerAccountDetailsService.fetchCustomerAccountDetails(
        accountNo: accountNo,
        deviceId: await getSavedOrFetchDeviceId(),
      );

      // Step 7: Check if customer data was found
      if (accountData == null) {
        if (context.mounted) Navigator.pop(context); // Hide spinner

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card data. Please try again.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return; // STOP - Do not proceed
      }

      // DEBUG: Print the captured data
      print("🎯 Account number from card: $accountNo");
      print("🎯 Card UID: $cardUID");
      print("👤 Customer: ${accountData.customerName}");

      // Step 8: All validations passed - proceed with sale
      if (context.mounted) Navigator.pop(context); // Hide spinner

      // Pass the card data to the cash amount dialog
      _promptCashAmount(context, accountData, accountResult.data.trim(), pinResult.data.trim(), cardUID, accountNo);
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Hide spinner

      // Show the same error message for any exception
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read card data. Please try again.'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      await FlutterNfcKit.finish();
    }
  }

  // Updated method to accept card data
  void _promptCashAmount(
    BuildContext context,
    CustomerAccountDetailsModel? account,
    String accountNumber,
    String pin,
    String cardUID, // NEW: Accept card UID
    String accountNo, // NEW: Accept account number
  ) {
    final double total = CartStorage().getTotalPrice();
    final TextEditingController _controller = TextEditingController(text: total.toStringAsFixed(0));
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: ColorsUniversal.background,
              title: Text(
                '${widget.selectedPaymentMode ?? "Cash"} Payment',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show customer info since we have card details
                  if (account != null) ...[
                    Text(
                      'Customer: ${account.customerName}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount Due:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      Text('Ksh ${CartStorage().getTotalPrice().toStringAsFixed(2)}', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    cursorColor: ColorsUniversal.buttonsColor,
                    decoration: InputDecoration(
                      hintText: 'Enter Amount Received',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      errorText: error,
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
                  child: Text('OK', style: TextStyle(color: Colors.white, fontSize: 16)),
                  onPressed: () async {
                    final entered = _controller.text.trim();
                    final amount = double.tryParse(entered);

                    if (amount == null || amount < CartStorage().getTotalPrice()) {
                      setState(() => error = 'Amount must be ≥ ${CartStorage().getTotalPrice().toStringAsFixed(0)}');
                      return;
                    }

                    // Get payment mode ID from Hive
                    final box = Hive.box('payment_modes');
                    final rawModes = box.get('acceptedModes', defaultValue: []);
                    final savedModes = (rawModes as List)
                        .map((e) => Map<String, dynamic>.from(e as Map))
                        .map((e) => PaymentModeModel.fromJson(e))
                        .toList();

                    int paymentModeId = 2; // Default to Cash
                    for (var mode in savedModes) {
                      if (mode.payModeDisplayName == widget.selectedPaymentMode) {
                        paymentModeId = mode.payModeId;
                        break;
                      }
                    }

                    final prefs = await SharedPreferences.getInstance();
                    final companyName = prefs.getString('companyName') ?? 'SAHARA FCS';
                    final channelName = prefs.getString('channelName') ?? 'CMB Station';
                    final refNumber = await RefGenerator.generate();
                    final deviceId = await getSavedOrFetchDeviceId();

                    print("🎯 Final data for Cash+Card sale:");
                    print("💰 Payment: ${widget.selectedPaymentMode} (${amount})");
                    print("🆔 Payment Mode ID: $paymentModeId");
                    print("📱 Card UID: $cardUID");
                    print("🏦 Account No: $accountNo");
                    print("👤 Customer: ${account?.customerName}");

                    Navigator.pop(context); // close the dialog

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptPrint(
                          showCardDetails: true, // Show card details on receipt
                          user: widget.user,
                          cartItems: widget.cartItems!,
                          cashGiven: amount,
                          customerName: account?.customerName ?? 'N/A',
                          card: account?.mask ?? 'N/A',
                          accountType: account?.agreementDescription ?? 'N/A',
                          vehicleNumber: (account?.equipmentMask != null && account!.equipmentMask!.isNotEmpty)
                              ? account.equipmentMask!.join(', ')
                              : 'No Equipment',
                          companyName: companyName,
                          channelName: channelName,
                          refNumber: refNumber,
                          termNumber: deviceId,
                          // PASS THE REAL CARD DATA:
                          cardUID: cardUID, // Real card UID from NFC
                          customerAccountNo: int.tryParse(accountNo), // Real account number from card
                          // NO CLIENT PRICING - this is a cash sale:
                          discount: null, // No discount for cash sales
                          clientTotal: null, // No client pricing for cash sales
                          customerBalance: account?.customerAccountBalance, // Show balance for info
                          accountProducts: null, // No account products needed for cash sales
                          // PASS THE REAL PAYMENT MODE:
                          paymentModeId: paymentModeId,
                          paymentModeName: widget.selectedPaymentMode ?? 'Cash',
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// CARD ONLY SALE
  //  _handleOnlyCardSales method
  Future<void> _handleOnlyCardSales() async {
    showLoadingSpinner(context);

    String? cardUID; // Declare variable to store card UID

    try {
      // Step 1: Scan card with timeout and CAPTURE the UID
      final tag = await FlutterNfcKit.poll().timeout(
        Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Card not detected within 8 seconds');
        },
      );

      // CAPTURE THE CARD UID HERE
      cardUID = UIDConverter.convertToPOSFormat(tag.id);
      print("🎯 Card UID: $cardUID"); // Debug print

      final nfc = NfcFunctions();

      // Step 2: Read account number from card
      final accountResult = await nfc.readSectorBlock(sectorIndex: 1, blockSectorIndex: 0, useDefaultKeys: false);

      if (accountResult.status != NfcMessageStatus.success) {
        Navigator.of(context).pop(); // Close spinner
        _showErrorMessage('Could not read card data. Please try again.');
        return;
      }

      // Step 3: Extract and validate account number
      final accountNo = accountResult.data.replaceAll(RegExp(r'[^0-9]'), '');
      if (accountNo.isEmpty || accountNo == '0') {
        Navigator.of(context).pop(); // Close spinner
        _showErrorMessage('No account assigned to this card.');
        return;
      }

      // Step 4: Read PIN from card
      final pinResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

      if (pinResult.status != NfcMessageStatus.success) {
        Navigator.of(context).pop(); // Close spinner
        _showErrorMessage('Could not read card PIN. Please try again.');
        return;
      }

      final cardPin = pinResult.data.replaceAll(';', '').trim();

      // DEBUG: Print all the data we captured
      print("🎯 Account number from card: $accountNo");
      print("🔐 PIN from card: $cardPin");
      print("🎯 Card UID: $cardUID");

      // Step 5: Fetch customer account details
      final accountData = await CustomerAccountDetailsService.fetchCustomerAccountDetails(
        accountNo: accountNo,
        deviceId: await getSavedOrFetchDeviceId(),
      );

      if (accountData == null) {
        Navigator.of(context).pop(); // Close spinner
        _showErrorMessage('Account details not found.');
        return;
      }

      Navigator.of(context).pop(); // Close spinner

      // Step 6: Calculate totals using ONLY client pricing
      final clientTotal = _calculateClientTotal(accountData.products);
      final discount = _calculateDiscount(accountData.products);
      final netTotal = clientTotal - discount;

      // Step 7: Check balance against NET TOTAL
      if (accountData.customerAccountBalance < netTotal) {
        _showInsufficientBalanceDialog(accountData, netTotal, clientTotal, discount);
        return;
      }

      // Step 8: Handle equipment selection (pass ALL the data including cardUID and accountNo)
      if (accountData.equipmentMask != null && accountData.equipmentMask!.isNotEmpty) {
        _showEquipmentDialog(accountData, cardPin, discount, netTotal, clientTotal, cardUID, accountNo);
      } else {
        _showCardPinDialog(accountData, cardPin, discount, netTotal, clientTotal, 'No Equipment', cardUID, accountNo);
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close spinner
      if (e is TimeoutException) {
        _showTimeoutDialog();
      } else {
        _showErrorMessage('Error reading card: ${e.toString()}');
      }
    } finally {
      await FlutterNfcKit.finish();
    }
  }

  // / 2. CORRECTED: Calculate discount using client pricing and cart quantities
  double _calculateDiscount(List<ProductCardDetailsModel> accountProducts) {
    double totalDiscount = 0;

    for (var cartItem in CartStorage().cartItems) {
      // Find matching product in account
      final accountProduct = accountProducts.firstWhere(
        (p) => p.productVariationId == cartItem.productId,
        orElse: () => ProductCardDetailsModel(
          productVariationId: 0,
          productVariationName: '',
          productCategoryId: 0,
          productCategoryName: '',
          productPrice: 0,
          productDiscount: 0,
        ),
      );

      if (accountProduct.productVariationId != 0) {
        // Calculate discount: Discount per Litre × Cart Quantity
        final discountPerLitre = accountProduct.productDiscount;
        final quantity = cartItem.quantity; // Use actual cart quantity

        totalDiscount += discountPerLitre * quantity;

        print("Discount for ${cartItem.productName}: $discountPerLitre × $quantity = ${discountPerLitre * quantity}");
      }
    }

    return totalDiscount;
  }

  // 1. CORRECTED: Calculate client total using ONLY client pricing (ignore cart total)
  double _calculateClientTotal(List<ProductCardDetailsModel> accountProducts) {
    double clientTotal = 0;

    for (var cartItem in CartStorage().cartItems) {
      // Find matching product in account
      final accountProduct = accountProducts.firstWhere(
        (p) => p.productVariationId == cartItem.productId,
        orElse: () => ProductCardDetailsModel(
          productVariationId: 0,
          productVariationName: '',
          productCategoryId: 0,
          productCategoryName: '',
          productPrice: 0,
          productDiscount: 0,
        ),
      );

      if (accountProduct.productVariationId != 0) {
        // Use ONLY client's price and cart quantity (ignore station price completely)
        final clientPrice = accountProduct.productPrice;
        final quantity = cartItem.quantity; // Use actual cart quantity

        clientTotal += clientPrice * quantity;

        print("Product: ${cartItem.productName}");
        print("Cart Quantity: $quantity, Client Price: $clientPrice");
        print("Product Total: ${clientPrice * quantity}");
      } else {
        // If product not found in account, use original pricing as fallback
        clientTotal += cartItem.price * cartItem.quantity;
        print("Product ${cartItem.productName} not found in account - using station price");
      }
    }

    return clientTotal;
  }

  // Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.grey, duration: Duration(seconds: 2)));
    Navigator.of(context).pop(); // Pop the dialog
    // if (mounted) Navigator.of(context).pop(); // Then pop the page
  }

  // Show timeout dialog
  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Card Timeout"),
        content: Text("No card detected. Please try again."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous page
            },
            child: Text("OK", style: TextStyle(color: ColorsUniversal.buttonsColor)),
          ),
        ],
      ),
    );
  }

  // Show insufficient balance dialog
  void _showInsufficientBalanceDialog(
    CustomerAccountDetailsModel account,
    double netTotal,
    double clientTotal,
    double discount,
  ) {
    // ignore: unused_local_variable
    final shortage = netTotal - account.customerAccountBalance;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Insufficient Balance"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Customer: ${account.customerName}'),
              SizedBox(height: 16),
              _infoRow('Available Balance:', 'Ksh ${account.customerAccountBalance.toStringAsFixed(2)}'),
              // Divider(),
              // _infoRow('Total:', 'Ksh ${clientTotal.toStringAsFixed(2)}'),
              // _infoRow('Discount:', 'Ksh ${discount.toStringAsFixed(2)}'),
              // _infoRow('Net Amount:', 'Ksh ${netTotal.toStringAsFixed(2)}', isBold: true),
              // Divider(),
              // _infoRow('Shortage:', 'Ksh ${shortage.toStringAsFixed(2)}', color: Colors.red, isBold: true),
              // SizedBox(height: 16),
              SizedBox(height: 16),
              Text(
                'Please top up your account or reduce the purchase amount.',
                style: TextStyle(color: ColorsUniversal.buttonsColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              // Text(
              //   'Custom pricing applied per your agreement',
              //   style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              //   textAlign: TextAlign.center,
              // ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous page
            },
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Show equipment selection dialog
  // Updated equipment dialog to accept and pass card data
  void _showEquipmentDialog(
    CustomerAccountDetailsModel account,
    String cardPin,
    double discount,
    double netTotal,
    double clientTotal,
    String cardUID, // NEW: Accept card UID
    String accountNo, // NEW: Accept account number
  ) {
    String? selectedEquipment;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Select Equipment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Customer: ${account.customerName}'),
              SizedBox(height: 16),
              Text('Available Equipment:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),

              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedEquipment,
                hint: Text('Select Equipment'),
                items: (account.equipmentMask ?? []).map((mask) {
                  return DropdownMenuItem<String>(value: mask, child: Text(mask));
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedEquipment = value;
                  });
                },
              ),

              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    _infoRow('Total:', 'Ksh ${clientTotal.toStringAsFixed(2)}'),
                    _infoRow('Discount:', 'Ksh ${discount.toStringAsFixed(2)}'),
                    Divider(height: 8),
                    _infoRow('Net Total:', 'Ksh ${netTotal.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous page
              },
              child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
            ),
            ElevatedButton(
              onPressed: selectedEquipment == null
                  ? null
                  : () {
                      Navigator.of(context).pop(); // Close equipment dialog
                      // PASS the card data to PIN dialog
                      _showCardPinDialog(
                        account,
                        cardPin,
                        discount,
                        netTotal,
                        clientTotal,
                        selectedEquipment!,
                        cardUID,
                        accountNo,
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
              child: Text('Continue', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Show PIN input dialog
  // Updated PIN dialog to accept and use real card data
  void _showCardPinDialog(
    CustomerAccountDetailsModel account,
    String cardPin,
    double discount,
    double netTotal,
    double clientTotal,
    String selectedEquipment,
    String cardUID, // NEW: Accept card UID
    String accountNo, // NEW: Accept account number
  ) {
    final TextEditingController pinController = TextEditingController();
    String? pinError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Card Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Customer: ${account.customerName}'),
              if (selectedEquipment != 'No Equipment') Text('Vehicle: $selectedEquipment'),
              SizedBox(height: 16),
              _infoRow('Balance:', 'Ksh ${account.customerAccountBalance.toStringAsFixed(2)}'),
              _infoRow('Total:', 'Ksh ${clientTotal.toStringAsFixed(2)}'),
              _infoRow('Discount:', 'Ksh ${discount.toStringAsFixed(2)}'),
              Divider(),
              _infoRow('Net Total:', 'Ksh ${netTotal.toStringAsFixed(2)}', isBold: true),
              SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter PIN',
                  errorText: pinError,
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous page
              },
              child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
              onPressed: () async {
                final enteredPin = pinController.text.trim();

                // Validate PIN
                if (enteredPin.isEmpty) {
                  setState(() => pinError = 'PIN cannot be empty');
                  return;
                }

                if (enteredPin.length != 4) {
                  setState(() => pinError = 'PIN must be 4 digits');
                  return;
                }

                if (enteredPin != cardPin) {
                  setState(() => pinError = 'Incorrect PIN. Try again.');
                  return;
                }

                // PIN is correct, go to receipt with REAL card data
                final prefs = await SharedPreferences.getInstance();
                final companyName = prefs.getString('companyName') ?? 'SAHARA FCS';
                final channelName = prefs.getString('channelName') ?? 'Station';
                final deviceId = await getSavedOrFetchDeviceId();
                final refNumber = await RefGenerator.generate();

                print("🎯 Final data being passed to receipt:");
                print("📱 Card UID: $cardUID");
                print("🏦 Account No: $accountNo");
                print("💰 Net Total: $netTotal");

                Navigator.of(context).pop(); // Close PIN dialog
                Navigator.of(context).pop(); // Go back to main page

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptPrint(
                      user: widget.user,
                      cartItems: CartStorage().cartItems,
                      cashGiven: netTotal,
                      customerName: account.customerName,
                      card: account.cardMask ?? account.mask ?? '',
                      accountType: account.accountCreditTypeName,
                      vehicleNumber: selectedEquipment,
                      showCardDetails: true,
                      discount: discount,
                      clientTotal: clientTotal,
                      customerBalance: account.customerAccountBalance,
                      accountProducts: account.products,
                      companyName: companyName,
                      channelName: channelName,
                      refNumber: refNumber,
                      termNumber: deviceId,
                      // PASS THE REAL CARD DATA:
                      cardUID: cardUID, // Real card UID from NFC
                      customerAccountNo: int.tryParse(accountNo),
                      paymentModeId: 4, // Internal Card payment mode ID
                      paymentModeName: "Card", // Internal Card payment mode name
                    ),
                  ),
                );
              },
              child: Text('Pay', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for info rows
  Widget _infoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }

  bool isProcessing = false;
  String result = '';
  @override
  void initState() {
    super.initState();
    switch (widget.action) {
      case TapCardAction.initialize:
        result = "Initialize card";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          initializeCard();
        });
        break;
      case TapCardAction.format:
        result = "Formatting card...";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          formatCard(); //  auto-run like _autoViewUID
        });
        break;
      case TapCardAction.viewUID:
        result = "Card UID";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          viewUID(context);
        });

        break;
      case TapCardAction.changePin:
        result = "Change card PIN";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          changeCardPIN(); // Auto-start change PIN
        });
        break;

      case TapCardAction.cardDetails:
        result = "Card details";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleCardDetails(context); //  Auto-start card details scan
        });
        break;
      case TapCardAction.cashCardSales:
        result = "Scanning card for sale...";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleCardSale(context);
        });

      case TapCardAction.cardSales:
        result = "Card sales";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleOnlyCardSales();
          //function
        });
        break;
      case TapCardAction.miniStatement:
        result = "Ministatement";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleMiniStatement(context);
          //function
        });
        break;
      case TapCardAction.topUp:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleTopUp(context);
          //function
        });
        break;

      case TapCardAction.reverseTopUp:
        break;
    }
  }

  ///TOP UP TRANSACTION
  Future<void> _handleTopUp(BuildContext context) async {
    final deviceId = await getSavedOrFetchDeviceId();
    print("💰 Scanning card for top-up...");
    bool shouldDismissSpinner = true;

    try {
      // Step 1: Start NFC polling with spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: SpinKitCircle(
            size: 70,
            duration: Duration(milliseconds: 1000),
            itemBuilder: (context, index) {
              final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
              final color = colors[index % colors.length];
              return DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              );
            },
          ),
        ),
      );

      // Poll for card with timeout - EXACTLY like mini statement
      // ignore: unused_local_variable
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30));
        },
      );

      final nfc = NfcFunctions();

      // Step 2: Read account number from card - EXACTLY like mini statement
      final accountResponse = await nfc.readSectorBlock(
        sectorIndex: 1,
        blockSectorIndex: 0,
        useDefaultKeys: false, // Use POS keys
      );

      if (accountResponse.status != NfcMessageStatus.success) {
        await FlutterNfcKit.finish();
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Close spinner
        shouldDismissSpinner = false;
        Navigator.of(context).pop(); // Close current page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card data. Please try again.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        print("❌ Failed to read account number: ${accountResponse.data}");
        return;
      }

      // Step 3: Read PIN from card - EXACTLY like mini statement
      final pinResponse = await nfc.readSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        useDefaultKeys: false, // Use POS keys
      );

      await FlutterNfcKit.finish(); // End NFC session

      if (pinResponse.status != NfcMessageStatus.success) {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Dismiss spinner
        shouldDismissSpinner = false;
        print("❌ Failed to read PIN from card: ${pinResponse.data}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card PIN. Card may not be initialized.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Step 4: Extract and validate account number and PIN - EXACTLY like mini statement
      final accountNo = accountResponse.data.replaceAll(RegExp(r'[^0-9]'), '');
      final cardPin = pinResponse.data.replaceAll(';', '').trim();

      print("🎯 Account number from card: $accountNo");
      print("🔐 PIN from card: $cardPin");
      print("💰 Top-up amount: ${widget.topUpAmount}");

      if (accountNo.isEmpty || accountNo == '0') {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Dismiss spinner
        shouldDismissSpinner = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No assigned account found on this card.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (widget.topUpAmount == null || widget.topUpAmount! <= 0) {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Close spinner
        shouldDismissSpinner = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid top-up amount.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Step 5: Dismiss spinner before showing PIN dialog - EXACTLY like mini statement
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss spinner
      shouldDismissSpinner = false;

      // Show PIN confirmation dialog
      final pinValid = await _showTopUpPinDialog(context, accountNo, cardPin, widget.topUpAmount!);
      if (!pinValid) {
        print("❌ PIN validation failed or was cancelled");
        return;
      }

      // Step 6: PIN is correct! Show loading state for API call - EXACTLY like mini statement
      print("✅ PIN verified successfully");

      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: SpinKitCircle(
            size: 70,
            duration: Duration(milliseconds: 1000),
            itemBuilder: (context, index) {
              final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
              final color = colors[index % colors.length];
              return DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              );
            },
          ),
        ),
      );
      shouldDismissSpinner = true;

      final result = await TopUpService.processTopUp(
        accountNo: accountNo,
        topUpAmount: widget.topUpAmount!,
        user: widget.user,
      );

      // Close loading dialog
      if (!context.mounted) return;
      Navigator.of(context).pop();
      shouldDismissSpinner = false;

      if (result['success']) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TopUpPage(
              user: widget.user,
              accountNo: accountNo,
              staff: widget.user,
              topUpData: result['data'],
              refNumber: result['refNumber'],
              termNumber: deviceId,
              amount: result['amount'],
            ),
          ),
        );
      } else {
        print("❌ Top-up failed: ${result['error']}");
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Top-Up Failed'),
            content: Text('Top-up could not be completed.\n\n${result['error']}', style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Pop dialog
                  if (context.mounted) Navigator.of(context).pop(); // Pop page
                },
                child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      await FlutterNfcKit.finish(); // Always end NFC session

      // Handle timeout specifically - EXACTLY like mini statement
      if (e is TimeoutException) {
        if (!context.mounted) return;

        if (shouldDismissSpinner) {
          Navigator.of(context).pop(); // Dismiss spinner
          shouldDismissSpinner = false;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text("Timeout"),
            content: const Text("No card detected. Please try again.", style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Pop dialog
                  if (context.mounted) Navigator.of(context).pop(); // Pop page
                },
                child: Text("OK", style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
        return;
      }

      // Handle other errors - EXACTLY like mini statement
      if (!context.mounted) return;

      if (shouldDismissSpinner) {
        Navigator.of(context).pop(); // Dismiss spinner
      }

      print("❌ Exception occurred: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error occurred: ${e.toString()}'),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      // Ensure spinner is dismissed if still showing - EXACTLY like mini statement
      if (shouldDismissSpinner && context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Spinner might already be dismissed
        }
      }
    }
  }

  // PIN dialog for top-up confirmation
  Future<bool> _showTopUpPinDialog(BuildContext context, String accountNo, String correctPin, double amount) async {
    bool pinVerified = false;

    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final pinController = TextEditingController();
        return AlertDialog(
          title: const Text('Confirm Top-Up'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Account: $accountNo', style: TextStyle(fontSize: 16)),
              Text(
                'Amount: Ksh ${amount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColorsUniversal.buttonsColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN to confirm',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                ),
                autofocus: true,
                cursorColor: ColorsUniversal.buttonsColor,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
            ),
            TextButton(
              onPressed: () {
                String pin = pinController.text;
                if (pin.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('PIN cannot be empty'), backgroundColor: Colors.grey));
                  return;
                }
                if (pin.length != 4) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('PIN must be 4 digits'), backgroundColor: Colors.grey));
                  return;
                }
                if (pin != correctPin) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Wrong PIN. Try again.'), backgroundColor: Colors.grey));
                  return;
                }
                pinVerified = true;
                Navigator.of(context).pop();
              },
              child: Text(
                'CONFIRM TOP-UP',
                style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    return pinVerified;
  }

  ///TRANSACTION MINISTATEMENT
  // Add this method to your TapCardPage for mini statement
  Future<void> _handleMiniStatement(BuildContext context) async {
    print("📡 Scanning card for mini statement...");
    bool shouldDismissSpinner = true;

    try {
      // Step 1: Start NFC polling with spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: SpinKitCircle(
            size: 70,
            duration: Duration(milliseconds: 1000),
            itemBuilder: (context, index) {
              final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
              final color = colors[index % colors.length];
              return DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              );
            },
          ),
        ),
      );

      // Poll for card with timeout
      // ignore: unused_local_variable
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30));
        },
      );

      final nfc = NfcFunctions();

      // Step 2: Read account number from card
      final accountResponse = await nfc.readSectorBlock(sectorIndex: 1, blockSectorIndex: 0, useDefaultKeys: false);

      if (accountResponse.status != NfcMessageStatus.success) {
        await FlutterNfcKit.finish();
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Close spinner
        shouldDismissSpinner = false;
        _showErrorMessage('Could not read card data. Please try again.');
        return;
      }

      // Step 3: Read PIN from card
      final pinResponse = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

      await FlutterNfcKit.finish();

      if (pinResponse.status != NfcMessageStatus.success) {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Close spinner
        shouldDismissSpinner = false;
        _showErrorMessage('Could not read card PIN.');
        return;
      }

      // Step 4: Extract account number and PIN
      final accountNo = accountResponse.data.replaceAll(RegExp(r'[^0-9]'), '');
      final cardPin = pinResponse.data.replaceAll(';', '').trim();

      print("🎯 Account number: $accountNo");
      print("🔐 PIN from card: $cardPin");

      if (accountNo.isEmpty || accountNo == '0') {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Close spinner
        shouldDismissSpinner = false;
        _showErrorMessage('No assigned account found on this card.');
        return;
      }

      // Step 5: Dismiss spinner and show PIN dialog
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close spinner
      shouldDismissSpinner = false;

      // Show PIN dialog
      final pinValid = await _showMiniStatementPinDialog(context, accountNo, cardPin);
      if (!pinValid) {
        print("❌ PIN validation failed");
        return;
      }

      // Step 6: PIN verified, fetch mini statement
      print("✅ PIN verified, fetching mini statement...");

      // Show loading again
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: SpinKitCircle(
            size: 70,
            duration: Duration(milliseconds: 1000),
            itemBuilder: (context, index) {
              final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
              final color = colors[index % colors.length];
              return DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              );
            },
          ),
        ),
      );
      shouldDismissSpinner = true;

      final result = await MiniStatementService.fetchMiniStatement(accountNumber: accountNo, user: widget.user);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading
      shouldDismissSpinner = false;
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('companyName') ?? 'SAHARA FCS';
      final channelName = prefs.getString('channelName') ?? 'Station';
      final deviceId = await getSavedOrFetchDeviceId();
      final refNumber = await RefGenerator.generate();

      if (result['success']) {
        // Navigate to mini statement page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MiniStatementPage(
              user: widget.user,
              accountDetails: result['accountDetails'],
              transactions: result['transactions'],
              channelName: channelName,
              companyName: companyName,
              termNumber: deviceId,
              refNumber: refNumber,
            ),
          ),
        );
      } else {
        _showErrorMessage(result['error']);
      }
    } catch (e) {
      await FlutterNfcKit.finish();

      if (e is TimeoutException) {
        if (!context.mounted) return;
        if (shouldDismissSpinner) {
          Navigator.of(context).pop();
          shouldDismissSpinner = false;
        }
        _showTimeoutDialog();
        return;
      }

      if (!context.mounted) return;
      if (shouldDismissSpinner) {
        Navigator.of(context).pop();
      }
      _showErrorMessage('Error: ${e.toString()}');
    }
  }

  // PIN dialog for mini statement
  Future<bool> _showMiniStatementPinDialog(BuildContext context, String accountNo, String correctPin) async {
    bool pinVerified = false;

    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final pinController = TextEditingController();
        return AlertDialog(
          title: const Text('Enter PIN for Mini Statement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Account: $accountNo', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                ),
                autofocus: true,
                cursorColor: ColorsUniversal.buttonsColor,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
            ),
            TextButton(
              onPressed: () {
                String pin = pinController.text;
                if (pin.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('PIN cannot be empty'), backgroundColor: Colors.grey));
                  return;
                }
                if (pin.length != 4) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('PIN must be 4 digits'), backgroundColor: Colors.grey));
                  return;
                }
                if (pin != correctPin) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Wrong PIN. Try again.'), backgroundColor: Colors.grey));
                  return;
                }
                pinVerified = true;
                Navigator.of(context).pop();
              },
              child: Text('SUBMIT', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 18)),
            ),
          ],
        );
      },
    );

    return pinVerified;
  }

  /// I N I T I A L I Z E  C A R D

  Future<void> initializeCard() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      result = "Starting initialization...";
    });

    final nfc = NfcFunctions();
    showLoadingSpinner(context);
    bool shouldDismissSpinner = true;

    try {
      setState(() => result = "📱 Waiting for card...\nPlace your card on the phone");

      // Step 1: Poll for card with timeout
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30));
        },
      );
      if (tag.type != NFCTagType.mifare_classic) {
        setState(() {
          result = "❌ Not a MIFARE Classic card";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      final rawUID = tag.id;
      final convertedUID = UIDConverter.convertToPOSFormat(rawUID);

      // Step 2: CHECK IF CARD IS ALREADY INITIALIZED
      setState(() => result = "🔍 Checking if card is already initialized...");

      try {
        // Try to read initialization flag with POS keys
        final initStatusResult = await nfc.readSectorBlock(
          sectorIndex: 2,
          blockSectorIndex: 2,
          useDefaultKeys: false, // Use POS keys
        );

        if (initStatusResult.status == NfcMessageStatus.success && initStatusResult.data.trim().startsWith('1')) {
          // Card is already initialized! Read existing data
          final accountResult = await nfc.readSectorBlock(sectorIndex: 1, blockSectorIndex: 0, useDefaultKeys: false);

          final pinResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

          await FlutterNfcKit.finish();

          // Extract data
          String accountNumber = accountResult.data.replaceAll(';', '').trim();
          String pin = pinResult.data.replaceAll(';', '').trim();

          // Fetch customer details for this account
          final imei = await getSavedOrFetchDeviceId();
          final staffId = widget.user.staffId;

          final accountData = await InitializeCardService.fetchCardData(
            cardUID: convertedUID,
            imei: imei,
            staffID: staffId,
          );

          setState(() {
            result =
                "⚠️ Card Already Initialized!\n\n"
                "📱 Card UID: $convertedUID\n"
                "🏦 Account: $accountNumber\n"
                "👤 Customer: ${accountData?.customerName ?? 'Unknown'}\n"
                "📞 Phone: ${accountData?.customerPhone ?? 'N/A'}\n"
                "🔐 PIN: $pin\n"
                "✅ Status: Already Active\n\n"
                "This card is already assigned and initialized.";
            isProcessing = false;
          });

          if (!mounted) return;

          // Dismiss spinner before showing dialog
          Navigator.of(context).pop();
          shouldDismissSpinner = false;

          // Show dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text('Card Already Initialized', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              content: Text(
                'Account: $accountNumber\n'
                'Customer: ${accountData?.customerName ?? 'Unknown'}\n',
                // 'Phone: ${accountData?.customerPhone ?? 'N/A'}\n\n',
                style: TextStyle(fontSize: 17),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Pop the dialog
                    if (mounted) Navigator.of(context).pop(); // Then pop the page
                  },
                  child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
                ),
              ],
            ),
          );
          return; // STOP - Do not proceed with initialization
        }
      } catch (e) {
        // Reading with POS keys failed - card is probably not initialized
        print("📝 Card not initialized yet (POS key read failed): $e");
      }

      // Step 3: Card is not initialized, proceed with normal flow
      setState(() => result = "✅ Card is blank - ready for initialization\n\n🔍 Checking account assignment...");

      final imei = await getSavedOrFetchDeviceId();
      final staffId = widget.user.staffId;

      // Fetch account data
      final accountData = await InitializeCardService.fetchCardData(
        cardUID: convertedUID,
        imei: imei,
        staffID: staffId,
      );

      // Check if account exists
      if (accountData == null ||
          // ignore: unnecessary_null_comparison
          accountData.customerAccountNumber == null ||
          accountData.customerAccountNumber == 0 ||
          accountData.customerAccountNumber.toString().isEmpty) {
        await FlutterNfcKit.finish();

        setState(() {
          result =
              "❌ No valid account found for this card.\n\n"
              "📱 App UID: $rawUID\n"
              "🏪 POS UID: $convertedUID\n"
              "🏦 Account Number: ${accountData?.customerAccountNumber ?? 'null'}\n\n"
              "Please assign this card to a valid account first.";
          isProcessing = false;
        });

        if (!mounted) return;

        // Dismiss spinner before showing dialog
        Navigator.of(context).pop();
        shouldDismissSpinner = false;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Failed'),
            content: const Text('Could not find the associated account number', style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Pop the dialog
                  if (mounted) Navigator.of(context).pop(); // Pop the page
                },
                child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
        return;
      }

      // Account found! End current session and get PIN
      await FlutterNfcKit.finish();

      setState(
        () => result =
            "✅ Account found: ${accountData.customerAccountNumber}\n\n👤 Customer: ${accountData.customerName}\n\n🔐 Please set a PIN for this card...",
      );

      if (!mounted) return;

      // Dismiss spinner before showing dialog
      Navigator.of(context).pop();
      shouldDismissSpinner = false;

      String? pin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Set Pin'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Setting Pin for:', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Customer Name: ${accountData.customerName}\nAccount: ${accountData.customerAccountNumber}',
                        style: TextStyle(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter 4-digit Pin',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                  ),
                  cursorColor: ColorsUniversal.buttonsColor,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Pop dialog
                  if (mounted) Navigator.of(context).pop(); // Pop page
                },
                child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(controller.text),
                child: Text('Set PIN', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          );
        },
      );

      if (pin == null || pin.length != 4) {
        setState(() {
          result = "❌ PIN setup cancelled or invalid";
          isProcessing = false;
        });
        return;
      }

      // Show spinner again for the writing process
      if (mounted) showLoadingSpinner(context);
      shouldDismissSpinner = true;

      // Start new session for writing with timeout
      setState(() => result = "📱 Ready to write data...\nPlace your card on the phone again");

      final tag2 = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30));
        },
      );
      if (tag2.type != NFCTagType.mifare_classic) {
        setState(() {
          result = "❌ Not a MIFARE Classic card";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      final rawUID2 = tag2.id;
      if (rawUID2 != rawUID) {
        setState(() {
          result = "⚠️ Different card detected!\n\nOriginal: $rawUID\nCurrent: $rawUID2\n\nPlease use the same card.";
          isProcessing = false;
        });
        await FlutterNfcKit.finish();
        return;
      }

      // Proceed with writing data
      setState(() => result = "📝 Initializing card with account ${accountData.customerAccountNumber}...");

      final accountNo = accountData.customerAccountNumber.toString();
      print("📝 Writing account number: $accountNo");

      final result1 = await nfc.writeSectorBlock(
        sectorIndex: 1,
        blockSectorIndex: 0,
        data: '$accountNo;',
        useDefaultKeys: true,
      );

      if (result1.status != NfcMessageStatus.success) {
        throw Exception("Failed to write account number: ${result1.data}");
      }

      print("📝 Writing PIN: $pin");
      final result2 = await nfc.writeSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        data: '$pin;',
        useDefaultKeys: true,
      );

      if (result2.status != NfcMessageStatus.success) {
        throw Exception("Failed to write PIN: ${result2.data}");
      }

      print("📝 Writing max attempts: 3");
      final result3 = await nfc.writeSectorBlock(sectorIndex: 2, blockSectorIndex: 1, data: '3;', useDefaultKeys: true);

      if (result3.status != NfcMessageStatus.success) {
        throw Exception("Failed to write lock count: ${result3.data}");
      }

      print("📝 Writing init flag: 1");
      final result4 = await nfc.writeSectorBlock(sectorIndex: 2, blockSectorIndex: 2, data: '1;', useDefaultKeys: true);

      if (result4.status != NfcMessageStatus.success) {
        throw Exception("Failed to write init status: ${result4.data}");
      }

      print("🔐 Changing keys to POS keys...");
      final changeKey1 = await nfc.changeKeys(sectorIndex: 1, fromDefault: true);
      if (changeKey1.status != NfcMessageStatus.success) {
        throw Exception("Failed to change keys for sector 1: ${changeKey1.data}");
      }

      final changeKey2 = await nfc.changeKeys(sectorIndex: 2, fromDefault: true);
      if (changeKey2.status != NfcMessageStatus.success) {
        throw Exception("Failed to change keys for sector 2: ${changeKey2.data}");
      }

      setState(() => result = "📡 Completing initialization in portal...");

      final completed = await CompleteCardInitService.completeInitializeCard(
        uid: convertedUID,
        accountNo: accountData.customerAccountNumber,
        staffId: staffId,
      );

      await FlutterNfcKit.finish();

      setState(() {
        result =
            '''✅ Card initialized successfully!
${completed ? '✅ Portal updated successfully!' : '⚠️ Portal update failed (card still works)'}

👤 Customer: ${accountData.customerName}
📞 Phone: ${accountData.customerPhone}
📧 Email: ${accountData.customerEmail}
🏦 Account: ${accountData.customerAccountNumber}
💳 Type: ${accountData.accountCreditTypeName}
🔐 PIN: $pin
🔢 Max attempts: 3
✅ Status: Initialized

🔑 Keys: POS system keys set
🏪 Ready for POS use!

🔧 Debug Info:
📱 App UID: $rawUID
🏪 POS UID: $convertedUID''';
        isProcessing = false;
      });

      // Success! Dismiss spinner and show success snackbar, then pop page
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss spinner
        shouldDismissSpinner = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Card initialized successfully'),
            // for ${accountData.customerName}!
            backgroundColor: hexToColor('8f9c68'),
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pop(); // Pop the page
      }
    } catch (e) {
      await FlutterNfcKit.finish();

      // Handle timeout specifically
      if (e is TimeoutException) {
        setState(() {
          result = "⏰ Timeout: No card detected";
          isProcessing = false;
        });

        if (!mounted) return;

        // Dismiss spinner before showing dialog
        if (shouldDismissSpinner) {
          Navigator.of(context).pop();
          shouldDismissSpinner = false;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Timeout'),
            content: const Text('No card detected. Please try again.', style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Pop the dialog
                  if (mounted) Navigator.of(context).pop(); // Pop the page
                },
                child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        result = "❌ Initialization failed:\n$e";
        isProcessing = false;
      });
    } finally {
      // Ensure spinner is dismissed if still showing
      if (shouldDismissSpinner && mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Spinner might already be dismissed
        }
      }
    }
  }

  //FORMAT CARD
  Future<void> formatCard() async {
    if (isProcessing || !mounted) return;

    setState(() => isProcessing = true);
    showLoadingSpinner(context);
    bool shouldDismissSpinner = true;

    try {
      // Wait for card scan with timeout
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30));
        },
      );

      final rawUID = tag.id;

      if (tag.type != NFCTagType.mifare_classic) {
        await FlutterNfcKit.finish();
        setState(() => isProcessing = false);

        if (!mounted) return;

        // Dismiss spinner before showing dialog
        Navigator.of(context).pop();
        shouldDismissSpinner = false;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text("Invalid Card"),
            content: const Text("❌ Not a MIFARE Classic card.", style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Pop the dialog
                  if (mounted) Navigator.of(context).pop(); // Pop the page
                },
                child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
        return;
      }

      final nfc = NfcFunctions();
      List<String> formatResults = [];

      for (int sector in [1, 2]) {
        bool formatted = false;
        try {
          final res = await nfc.formatSector(sectorIndex: sector, useDefaultKeys: false);
          if (res.status == NfcMessageStatus.success) {
            formatResults.add("✅ Sector $sector: ${res.data}");
            formatted = true;
          }
        } catch (_) {}

        if (!formatted) {
          try {
            final res = await nfc.formatSector(sectorIndex: sector, useDefaultKeys: true);
            if (res.status == NfcMessageStatus.success) {
              formatResults.add("✅ Sector $sector: ${res.data}");
            } else {
              formatResults.add("❌ Sector $sector: ${res.data}");
            }
          } catch (e) {
            formatResults.add("❌ Sector $sector: Error - $e");
          }
        }
      }

      await FlutterNfcKit.finish();

      final convertedUID = UIDConverter.convertToPOSFormat(rawUID);
      final staffId = widget.user.staffId;
      final apiSuccess = await InitializeCardService.formatCardAPI(cardUID: convertedUID, staffId: staffId);
      print('$apiSuccess');

      if (!mounted) return;

      // Success! Dismiss spinner and show success snackbar, then pop page
      Navigator.of(context).pop(); // Dismiss spinner
      shouldDismissSpinner = false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SizedBox(
            height: 22,
            child: Text(
              'Card formatted successfully.\n',
              // '${apiSuccess ? '✅ Portal unassigned successfully' : '⚠️ Portal unassignment failed (card still formatted)'}',
              style: TextStyle(fontSize: 16),
            ),
          ),
          backgroundColor: hexToColor('8f9c68'),
          duration: Duration(seconds: 2),
        ),
      );
      // Pop the page immediately
      Navigator.of(context).pop();
    } catch (e) {
      await FlutterNfcKit.finish();

      // Handle timeout specifically
      if (e is TimeoutException) {
        setState(() => isProcessing = false);

        if (!mounted) return;

        // Dismiss spinner before showing dialog
        if (shouldDismissSpinner) {
          Navigator.of(context).pop();
          shouldDismissSpinner = false;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Timeout'),
            content: const Text('No card detected. Please try again.', style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Pop the dialog
                  if (mounted) Navigator.of(context).pop(); // Pop the page
                },
                child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
        return;
      }

      // Handle other errors
      setState(() => isProcessing = false);

      if (!mounted) return;

      // Dismiss spinner before showing snackbar
      if (shouldDismissSpinner) {
        Navigator.of(context).pop();
        shouldDismissSpinner = false;
      }

      print('Format error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SizedBox(height: 22, child: Text('Format failed: ${e.toString()}', style: TextStyle(fontSize: 16))),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.fixed,
        ),
      );
      Navigator.of(context).pop(); // Pop the page
    } finally {
      // Ensure spinner is dismissed if still showing
      if (shouldDismissSpinner && mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Spinner might already be dismissed
        }
      }
      if (mounted) setState(() => isProcessing = false);
    }
  }

  //CHANGE PIN
  //CHANGE CARD PIN
  Future<void> changeCardPIN() async {
    if (isProcessing) return;

    final pinData = widget.extraData;
    if (pinData == null) {
      setState(() {
        result = "❌ No PIN data provided";
        isProcessing = false;
      });
      return;
    }

    setState(() {
      isProcessing = true;
      result = "🔐 Preparing to change PIN...";
    });

    bool shouldDismissSpinner = true;

    try {
      // Show loading spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: SpinKitCircle(
            size: 70,
            duration: Duration(milliseconds: 1000),
            itemBuilder: (context, index) {
              final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
              return DecoratedBox(
                decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle),
              );
            },
          ),
        ),
      );

      // Poll for card with timeout
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30));
        },
      );

      if (tag.type != NFCTagType.mifare_classic) {
        await FlutterNfcKit.finish();

        setState(() {
          result = "❌ Not a MIFARE Classic card";
          isProcessing = false;
        });

        if (!mounted) return;

        // Dismiss spinner before showing dialog
        Navigator.of(context).pop();
        shouldDismissSpinner = false;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Invalid Card'),
            content: const Text('Not a MIFARE Classic card. Please use a valid card.', style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Pop dialog
                  if (mounted) Navigator.of(context).pop(); // Pop page
                },
                child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
        return;
      }

      final nfc = NfcFunctions();

      setState(() => result = "🔍 Verifying current PIN...");

      final currentPinResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

      if (currentPinResult.status != NfcMessageStatus.success) {
        throw Exception("Failed to read current PIN: ${currentPinResult.data}");
      }

      final storedPin = currentPinResult.data.replaceAll(';', '').trim();
      final oldPin = pinData['oldPin']!;
      final newPin = pinData['newPin']!;

      if (storedPin != oldPin) {
        await FlutterNfcKit.finish();

        setState(() {
          result = "❌ Incorrect current PIN.\nStored: $storedPin\nEntered: $oldPin";
          isProcessing = false;
        });

        if (!mounted) return;

        // Dismiss spinner before showing dialog
        Navigator.of(context).pop();
        shouldDismissSpinner = false;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Incorrect PIN'),
            content: const Text(
              'The current PIN you entered is incorrect. Please try again.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Pop dialog
                  if (mounted) Navigator.of(context).pop(); // Pop page
                },
                child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
        return;
      }

      setState(() => result = "✅ Verified! Writing new PIN...");

      final writeResult = await nfc.writeSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        data: '$newPin;',
        useDefaultKeys: false,
      );

      if (writeResult.status != NfcMessageStatus.success) {
        throw Exception("Failed to write new PIN: ${writeResult.data}");
      }

      final verifyResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

      final verifiedPin = verifyResult.data.replaceAll(';', '').trim();
      await FlutterNfcKit.finish();

      setState(() {
        result =
            '''
✅ PIN Changed Successfully!

📊 Details:
• Old PIN: $oldPin
• New PIN: $newPin
• Verified: $verifiedPin
''';
        isProcessing = false;
      });

      // Success! Dismiss spinner and show success snackbar, then pop page
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss spinner
        shouldDismissSpinner = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PIN changed successfully!'),
            backgroundColor: hexToColor('8f9c68'),
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pop(); // Pop the page
      }
    } catch (e) {
      await FlutterNfcKit.finish();

      // Handle timeout specifically
      if (e is TimeoutException) {
        setState(() {
          result = "⏰ Timeout: No card detected";
          isProcessing = false;
        });

        if (!mounted) return;

        // Dismiss spinner before showing dialog
        if (shouldDismissSpinner) {
          Navigator.of(context).pop();
          shouldDismissSpinner = false;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Timeout'),
            content: const Text('No card detected. Please try again.', style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Pop the dialog
                  if (mounted) Navigator.of(context).pop(); // Pop the page
                },
                child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
        return;
      }

      // Handle other errors
      setState(() {
        result = "❌ PIN change failed: $e";
        isProcessing = false;
      });

      if (!mounted) return;

      // Dismiss spinner before showing snackbar
      if (shouldDismissSpinner) {
        Navigator.of(context).pop();
        shouldDismissSpinner = false;
      }
      print(': ${e.toString()}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PIN change failed, Card may not be assigned'),
          //: ${e.toString()}
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop(); // Pop the page
    } finally {
      // Ensure spinner is dismissed if still showing
      if (shouldDismissSpinner && mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Spinner might already be dismissed
        }
      }
    }
  }

  //C A R D  U I D
  void viewUID(BuildContext context) async {
    bool shouldDismissSpinner = true;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: SpinKitCircle(
            size: 70,
            duration: Duration(milliseconds: 1000),
            itemBuilder: (context, index) {
              final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
              final color = colors[index % colors.length];
              return DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              );
            },
          ),
        ),
      );

      // Poll for card with timeout
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30));
        },
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        shouldDismissSpinner = false;
      }

      // Get UID
      final appUID = tag.id;
      final posUID = UIDConverter.convertToPOSFormat(appUID);

      await FlutterNfcKit.finish();

      // Show result
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text("Card Identifier"),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UID', style: TextStyle(fontSize: 20, color: Colors.black54)),
                Text(': $posUID', style: TextStyle(fontSize: 20, color: Colors.black54)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close the dialog first
                  if (context.mounted) Navigator.of(context).pop(); // Then pop the page
                },
                child: Text("OK", style: TextStyle(fontSize: 16, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      await FlutterNfcKit.finish();

      if (context.mounted && shouldDismissSpinner) {
        Navigator.of(context).pop(); // Close loading dialog
        shouldDismissSpinner = false;
      }

      if (context.mounted) {
        // Handle timeout specifically
        if (e is TimeoutException) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: const Text("Timeout"),
              content: const Text("No card detected. Please try again.", style: TextStyle(fontSize: 16)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Pop the dialog
                    if (context.mounted) Navigator.of(context).pop(); // Pop the page
                  },
                  child: Text("OK", style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
                ),
              ],
            ),
          );
        } else {
          // Handle other errors
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: const Text("Error"),
              content: const Text("Failed to read card UID", style: TextStyle(fontSize: 16)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Pop the dialog
                    if (context.mounted) Navigator.of(context).pop(); // Pop the page
                  },
                  child: Text("OK", style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
                ),
              ],
            ),
          );
        }
        print('❌ Error reading card: $e');
      }
    }
  }

  /// C A R D  D E T A I L S
  Future<void> _handleCardDetails(BuildContext context) async {
    print("📡 Scanning card for details...");
    bool shouldDismissSpinner = true;

    try {
      // Step 1: Start NFC polling with spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: SpinKitCircle(
            size: 70,
            duration: Duration(milliseconds: 1000),
            itemBuilder: (context, index) {
              final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
              final color = colors[index % colors.length];
              return DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              );
            },
          ),
        ),
      );

      // Poll for card with timeout
      // ignore: unused_local_variable
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 30)).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('No card detected within 30 seconds', Duration(seconds: 30));
        },
      );

      final nfc = NfcFunctions();

      // Step 2: Read account number from card
      final accountResponse = await nfc.readSectorBlock(
        sectorIndex: 1,
        blockSectorIndex: 0,
        useDefaultKeys: false, // Use POS keys
      );

      if (accountResponse.status != NfcMessageStatus.success) {
        await FlutterNfcKit.finish();

        if (!context.mounted) return;

        Navigator.of(context).pop(); // Close spinner
        shouldDismissSpinner = false;

        Navigator.of(context).pop(); // Close current page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card data. Please try again.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        print("❌ Failed to read account number: ${accountResponse.data}");
        return;
      }

      // Step 3: Read PIN from card for validation
      final pinResponse = await nfc.readSectorBlock(
        sectorIndex: 2,
        blockSectorIndex: 0,
        useDefaultKeys: false, // Use POS keys
      );

      await FlutterNfcKit.finish(); // End NFC session

      if (pinResponse.status != NfcMessageStatus.success) {
        if (!context.mounted) return;

        Navigator.of(context).pop(); // Dismiss spinner
        shouldDismissSpinner = false;

        print("❌ Failed to read PIN from card: ${pinResponse.data}");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card PIN. Card may not be initialized.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Step 4: Extract and validate account number
      final accountNo = accountResponse.data.replaceAll(RegExp(r'[^0-9]'), '');
      final cardPin = pinResponse.data.replaceAll(';', '').trim();

      print("🎯 Account number from card: $accountNo");
      print("🔐 PIN from card: $cardPin");

      if (accountNo.isEmpty || accountNo == '0') {
        if (!context.mounted) return;

        Navigator.of(context).pop(); // Dismiss spinner
        shouldDismissSpinner = false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No assigned account found on this card.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Step 5: Dismiss spinner before showing PIN dialog
      if (!context.mounted) return;

      Navigator.of(context).pop(); // Dismiss spinner
      shouldDismissSpinner = false;

      // Prompt user for PIN and validate
      final pinValid = await _showPinDialog(context, accountNo, cardPin);

      if (!pinValid) {
        print("❌ PIN validation failed or was cancelled");
        return;
      }

      // Step 6: PIN is correct! Show loading state for API call
      print("✅ PIN verified successfully");

      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: SpinKitCircle(
            size: 70,
            duration: Duration(milliseconds: 1000),
            itemBuilder: (context, index) {
              final colors = [ColorsUniversal.buttonsColor, ColorsUniversal.fillWids];
              final color = colors[index % colors.length];
              return DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              );
            },
          ),
        ),
      );
      shouldDismissSpinner = true;

      final deviceId = await getSavedOrFetchDeviceId();
      print('📱 Device ID used for sync: $deviceId');

      final details = await CustomerAccountDetailsService.fetchCustomerAccountDetails(
        accountNo: accountNo,
        deviceId: deviceId,
      );

      // Close loading dialog
      if (!context.mounted) return;

      Navigator.of(context).pop();
      shouldDismissSpinner = false;

      // Step 7: Check if details were found
      if (details == null) {
        print("❌ No details found for account: $accountNo");

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('No Details Found'),
            content: Text(
              'Could not find customer details for account: $accountNo\n\n'
              'The account may not exist in the system or there may be a connection issue.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Pop dialog
                  if (context.mounted) Navigator.of(context).pop(); // Pop page
                },
                child: Text('OK', style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
        return;
      }

      // Step 8: Success! Navigate to details page
      print("✅ Customer details fetched successfully");
      // final deviceId = await getSavedOrFetchDeviceId();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardDetailsPage(user: widget.user, details: details, termNumber: deviceId),
        ),
      );
    } catch (e) {
      await FlutterNfcKit.finish(); // Always end NFC session

      // Handle timeout specifically
      if (e is TimeoutException) {
        if (!context.mounted) return;

        if (shouldDismissSpinner) {
          Navigator.of(context).pop(); // Dismiss spinner
          shouldDismissSpinner = false;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text("Timeout"),
            content: const Text("No card detected. Please try again.", style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Pop dialog
                  if (context.mounted) Navigator.of(context).pop(); // Pop page
                },
                child: Text("OK", style: TextStyle(fontSize: 18, color: ColorsUniversal.buttonsColor)),
              ),
            ],
          ),
        );
        return;
      }

      // Handle other errors
      if (!context.mounted) return;

      if (shouldDismissSpinner) {
        Navigator.of(context).pop(); // Dismiss spinner
      }

      print("❌ Exception occurred: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error occurred: ${e.toString()}'),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      // Ensure spinner is dismissed if still showing
      if (shouldDismissSpinner && context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Spinner might already be dismissed
        }
      }
    }
  }

  /// DETAILS PIN DIALOG
  Future<bool> _showPinDialog(BuildContext context, String accountNo, String correctPin) async {
    bool pinVerified = false;

    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final pinController = TextEditingController();
        return AlertDialog(
          title: const Text('Enter PIN'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account: $accountNo', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter 4-digit PIN',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorsUniversal.buttonsColor)),
                    // prefixIcon: Icon(Icons.lock),
                  ),
                  autofocus: true,
                  cursorColor: ColorsUniversal.buttonsColor,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
            ),
            TextButton(
              onPressed: () {
                String pin = pinController.text;
                if (pin.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('PIN cannot be empty'), backgroundColor: Colors.grey));
                  return;
                }
                if (pin.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN must be exactly 4 digits'), backgroundColor: Colors.grey),
                  );
                  return;
                }
                if (pin != correctPin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Wrong PIN. Try again.'),
                      backgroundColor: Colors.grey,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return; // Keep dialog open
                }
                pinVerified = true;
                Navigator.of(context).pop();
              },
              child: Text('SUBMIT', style: TextStyle(color: ColorsUniversal.buttonsColor, fontSize: 18)),
            ),
          ],
        );
      },
    );

    return pinVerified;
  }

  //SET STATE HELPER
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void safeShowSnackBar(String message, {Color? backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor ?? Colors.grey,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void safeNavigatorPop() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> safeShowDialog(Widget dialog) async {
    if (mounted) {
      await showDialog(context: context, barrierDismissible: false, builder: (context) => dialog);
    }
  }

  // Add cancellation support
  bool _isCancelled = false;

  void cancelOperation() {
    _isCancelled = true;
    safeSetState(() => isProcessing = false);
  }

  bool get shouldContinue => mounted && !_isCancelled;

  // Handle back button press
  Future<bool> handleBackPress() async {
    if (isProcessing) {
      // Cancel any ongoing operation
      cancelOperation();
      await FlutterNfcKit.finish(); // Stop NFC
      return true; // Allow pop
    }
    return true; // Allow normal pop
  }

  /// END OF SET STATE HELPER

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop && isProcessing) {
          // If the pop already happened and we were processing, clean up
          await handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: ColorsUniversal.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  'Hold the Card/Tag at the \nreader and keep it there',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                RotatedBox(
                  quarterTurns: -2,
                  child: Image.asset('assets/images/nfc_scan.png', fit: BoxFit.fitHeight, height: 300),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        // This takes all available space except what the button needs
                        child: SingleChildScrollView(
                          child: Text(
                            // result,
                            '',
                            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
                        child: myButton(
                          context,
                          () async {
                            switch (widget.action) {
                              case TapCardAction.initialize:
                                initializeCard();
                                break;
                              case TapCardAction.format:
                                isProcessing ? null : formatCard();
                                break;
                              case TapCardAction.viewUID:
                                viewUID(context);
                                break;
                              case TapCardAction.changePin:
                                isProcessing ? null : changeCardPIN();
                                break;
                              case TapCardAction.cardDetails:
                                await _handleCardDetails(context);
                                break;
                              case TapCardAction.cashCardSales:
                                await _handleCardSale(context); // <-- Your new handler here
                                break;
                              case TapCardAction.cardSales:
                                // Add handler or leave empty if unused for now
                                await _handleOnlyCardSales();
                                break;
                              case TapCardAction.miniStatement:
                                await _handleMiniStatement(context);
                                break;
                              case TapCardAction.topUp:
                                await _handleTopUp(context);
                                break;
                              case TapCardAction.reverseTopUp:
                                break;
                            }
                          },
                          'TAP AGAIN !',
                          buttonTextStyle: const TextStyle(fontSize: 25, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
