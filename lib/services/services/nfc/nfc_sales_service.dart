import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nfc_base_service.dart';
import '../../../models/nfc_result.dart';
import '../../../models/staff_list_model.dart';
import '../../../models/customer_account_details_model.dart';
import '../../../models/payment_mode_model.dart';
import '../../../models/product_card_details_model.dart';
import '../../../modules/nfc_functions.dart';
import '../../../modules/customer_account_details_service.dart';
import '../../../helpers/uid_converter.dart';
import '../../../helpers/device_id_helper.dart';
import '../../../helpers/ref_generator.dart';
import '../../../helpers/cart_storage.dart';
import '../../../pages/receipt_print.dart';
import '../../../utils/colors_universal.dart';

class NFCSalesService extends NFCBaseService {
  // CASH AND CARD SALE
  static Future<NFCResult> handleCardSale(
    BuildContext context,
    StaffListModel user,
    Map<String, dynamic>? extraData,
  ) async {
    final nfc = NfcFunctions();
    String? cardUID;

    NFCBaseService.showLoadingSpinner(context);

    try {
      final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 8));
      cardUID = UIDConverter.convertToPOSFormat(tag.id);

      print("🎯 Card UID: $cardUID");

      // Step 1: Try to read account number from card
      final accountResult = await nfc.readSectorBlock(sectorIndex: 1, blockSectorIndex: 0, useDefaultKeys: false);

      // Step 2: Check if account read was successful
      if (accountResult.status != NfcMessageStatus.success) {
        if (context.mounted) Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card data. Please try again.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return NFCResult.error('Could not read card data');
      }

      // Step 3: Extract and validate account number
      final accountNo = accountResult.data.replaceAll(RegExp(r'[^0-9]'), '');

      if (accountNo.isEmpty || accountNo == '0') {
        if (context.mounted) Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card data. Please try again.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return NFCResult.error('Invalid account number');
      }

      // Step 4: Try to read PIN from card
      final pinResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

      if (pinResult.status != NfcMessageStatus.success) {
        if (context.mounted) Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card data. Please try again.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return NFCResult.error('Could not read PIN');
      }

      // Step 5: Fetch customer account details
      final accountData = await CustomerAccountDetailsService.fetchCustomerAccountDetails(
        accountNo: accountNo,
        deviceId: await getSavedOrFetchDeviceId(),
      );

      if (accountData == null) {
        if (context.mounted) Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read card data. Please try again.'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return NFCResult.error('Customer data not found');
      }

      print("🎯 Account number from card: $accountNo");
      print("🎯 Card UID: $cardUID");
      print("👤 Customer: ${accountData.customerName}");

      // Step 6: All validations passed - proceed with sale
      if (context.mounted) Navigator.pop(context);

      // Show cash amount dialog
      final result = await _showCashAmountDialog(
        context,
        accountData,
        accountResult.data.trim(),
        pinResult.data.trim(),
        cardUID,
        accountNo,
        user,
        extraData,
      );

      return result;
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read card data. Please try again.'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
      return NFCResult.error('Error reading card: ${e.toString()}');
    } finally {
      await FlutterNfcKit.finish();
    }
  }

  // CARD ONLY SALE
  static Future<NFCResult> handleOnlyCardSales(
    BuildContext context,
    StaffListModel user,
    Map<String, dynamic>? extraData,
  ) async {
    NFCBaseService.showLoadingSpinner(context);
    String? cardUID;

    try {
      // Step 1: Scan card with timeout and CAPTURE the UID
      final tag = await FlutterNfcKit.poll().timeout(
        Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Card not detected within 8 seconds');
        },
      );

      cardUID = UIDConverter.convertToPOSFormat(tag.id);
      print("🎯 Card UID: $cardUID");

      final nfc = NfcFunctions();

      // Step 2: Read account number from card
      final accountResult = await nfc.readSectorBlock(sectorIndex: 1, blockSectorIndex: 0, useDefaultKeys: false);

      if (accountResult.status != NfcMessageStatus.success) {
        Navigator.of(context).pop();
        _showErrorMessage(context, 'Could not read card data. Please try again.');
        return NFCResult.error('Could not read card data');
      }

      // Step 3: Extract and validate account number
      final accountNo = accountResult.data.replaceAll(RegExp(r'[^0-9]'), '');
      if (accountNo.isEmpty || accountNo == '0') {
        Navigator.of(context).pop();
        _showErrorMessage(context, 'No account assigned to this card.');
        return NFCResult.error('No account assigned');
      }

      // Step 4: Read PIN from card
      final pinResult = await nfc.readSectorBlock(sectorIndex: 2, blockSectorIndex: 0, useDefaultKeys: false);

      if (pinResult.status != NfcMessageStatus.success) {
        Navigator.of(context).pop();
        _showErrorMessage(context, 'Could not read card PIN. Please try again.');
        return NFCResult.error('Could not read PIN');
      }

      final cardPin = pinResult.data.replaceAll(';', '').trim();

      print("🎯 Account number from card: $accountNo");
      print("🔐 PIN from card: $cardPin");
      print("🎯 Card UID: $cardUID");

      // Step 5: Fetch customer account details
      final accountData = await CustomerAccountDetailsService.fetchCustomerAccountDetails(
        accountNo: accountNo,
        deviceId: await getSavedOrFetchDeviceId(),
      );

      if (accountData == null) {
        Navigator.of(context).pop();
        _showErrorMessage(context, 'Account details not found.');
        return NFCResult.error('Account details not found');
      }

      Navigator.of(context).pop(); // Close spinner

      // Step 6: Calculate totals using ONLY client pricing
      final clientTotal = _calculateClientTotal(accountData.products);
      final discount = _calculateDiscount(accountData.products);
      final netTotal = clientTotal - discount;

      // Step 7: Check balance against NET TOTAL
      if (accountData.customerAccountBalance < netTotal) {
        await _showInsufficientBalanceDialog(context, accountData, netTotal, clientTotal, discount);
        return NFCResult.error('Insufficient balance');
      }

      // Step 8: Handle equipment selection
      if (accountData.equipmentMask != null && accountData.equipmentMask!.isNotEmpty) {
        final result = await _showEquipmentDialog(
          context,
          accountData,
          cardPin,
          discount,
          netTotal,
          clientTotal,
          cardUID,
          accountNo,
          user,
        );
        return result;
      } else {
        final result = await _showCardPinDialog(
          context,
          accountData,
          cardPin,
          discount,
          netTotal,
          clientTotal,
          'No Equipment',
          cardUID,
          accountNo,
          user,
        );
        return result;
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (e is TimeoutException) {
        await _showTimeoutDialog(context);
        return NFCResult.error('Timeout: No card detected');
      } else {
        _showErrorMessage(context, 'Error reading card: ${e.toString()}');
        return NFCResult.error('Error reading card: ${e.toString()}');
      }
    } finally {
      await FlutterNfcKit.finish();
    }
  }

  // Helper methods (make these static)
  static Future<NFCResult> _showCashAmountDialog(
    BuildContext context,
    CustomerAccountDetailsModel? account,
    String accountNumber,
    String pin,
    String cardUID,
    String accountNo,
    StaffListModel user,
    Map<String, dynamic>? extraData,
  ) async {
    final double total = CartStorage().getTotalPrice();
    final TextEditingController controller = TextEditingController(text: total.toStringAsFixed(0));
    String? error;
    bool dialogResult = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: ColorsUniversal.background,
              title: Text(
                '${extraData?['selectedPaymentMode'] ?? "Cash"} Payment',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    controller: controller,
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
                    final entered = controller.text.trim();
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
                      if (mode.payModeDisplayName == extraData?['selectedPaymentMode']) {
                        paymentModeId = mode.payModeId;
                        break;
                      }
                    }

                    final prefs = await SharedPreferences.getInstance();
                    final companyName = prefs.getString('companyName') ?? 'SAHARA FCS';
                    final channelName = prefs.getString('channelName') ?? 'CMB Station';
                    final refNumber = await RefGenerator.generate();
                    final deviceId = await getSavedOrFetchDeviceId();

                    Navigator.pop(context); // close the dialog
                    dialogResult = true;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptPrint(
                          showCardDetails: true,
                          user: user,
                          cartItems: extraData?['cartItems'] ?? [],
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
                          cardUID: cardUID,
                          customerAccountNo: int.tryParse(accountNo),
                          discount: null,
                          clientTotal: null,
                          customerBalance: account?.customerAccountBalance,
                          accountProducts: null,
                          paymentModeId: paymentModeId,
                          paymentModeName: extraData?['selectedPaymentMode'] ?? 'Cash',
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

    return dialogResult
        ? NFCResult.success('Cash card sale completed successfully')
        : NFCResult.error('Cash card sale cancelled');
  }

  static double _calculateClientTotal(List<ProductCardDetailsModel> accountProducts) {
    double clientTotal = 0;

    for (var cartItem in CartStorage().cartItems) {
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
        final clientPrice = accountProduct.productPrice;
        final quantity = cartItem.quantity;
        clientTotal += clientPrice * quantity;
      } else {
        clientTotal += cartItem.price * cartItem.quantity;
      }
    }

    return clientTotal;
  }

  static double _calculateDiscount(List<ProductCardDetailsModel> accountProducts) {
    double totalDiscount = 0;

    for (var cartItem in CartStorage().cartItems) {
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
        final discountPerLitre = accountProduct.productDiscount;
        final quantity = cartItem.quantity;
        totalDiscount += discountPerLitre * quantity;
      }
    }

    return totalDiscount;
  }

  static void _showErrorMessage(BuildContext context, String message) {
    print(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed! Check if the device supports NFC'),
        backgroundColor: Colors.grey,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  static Future<void> _showTimeoutDialog(BuildContext context) async {
    return NFCBaseService.showErrorDialog(context, "Card Timeout", "No card detected. Please try again.");
  }

  static Future<void> _showInsufficientBalanceDialog(
    BuildContext context,
    CustomerAccountDetailsModel account,
    double netTotal,
    double clientTotal,
    double discount,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Insufficient Balance"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Customer: ${account.customerName}'),
              SizedBox(height: 16),
              _infoRow('Available Balance:', 'Ksh ${account.customerAccountBalance.toStringAsFixed(2)}'),
              SizedBox(height: 16),
              Text(
                'Please top up your account or reduce the purchase amount.',
                style: TextStyle(color: ColorsUniversal.buttonsColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static Future<NFCResult> _showEquipmentDialog(
    BuildContext context,
    CustomerAccountDetailsModel account,
    String cardPin,
    double discount,
    double netTotal,
    double clientTotal,
    String cardUID,
    String accountNo,
    StaffListModel user,
  ) async {
    String? selectedEquipment;
    bool dialogCompleted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
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
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
            ),
            ElevatedButton(
              onPressed: selectedEquipment == null
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      dialogCompleted = true;
                      await _showCardPinDialog(
                        context,
                        account,
                        cardPin,
                        discount,
                        netTotal,
                        clientTotal,
                        selectedEquipment!,
                        cardUID,
                        accountNo,
                        user,
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
              child: Text('Continue', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    return dialogCompleted
        ? NFCResult.success('Equipment selected successfully')
        : NFCResult.error('Equipment selection cancelled');
  }

  static Future<NFCResult> _showCardPinDialog(
    BuildContext context,
    CustomerAccountDetailsModel account,
    String cardPin,
    double discount,
    double netTotal,
    double clientTotal,
    String selectedEquipment,
    String cardUID,
    String accountNo,
    StaffListModel user,
  ) async {
    final TextEditingController pinController = TextEditingController();
    String? pinError;
    bool dialogCompleted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
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
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: ColorsUniversal.buttonsColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ColorsUniversal.buttonsColor),
              onPressed: () async {
                final enteredPin = pinController.text.trim();

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

                final prefs = await SharedPreferences.getInstance();
                final companyName = prefs.getString('companyName') ?? 'SAHARA FCS';
                final channelName = prefs.getString('channelName') ?? 'Station';
                final deviceId = await getSavedOrFetchDeviceId();
                final refNumber = await RefGenerator.generate();

                Navigator.of(context).pop();
                Navigator.of(context).pop();
                dialogCompleted = true;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptPrint(
                      user: user,
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
                      cardUID: cardUID,
                      customerAccountNo: int.tryParse(accountNo),
                      paymentModeId: 4,
                      paymentModeName: "Card",
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

    return dialogCompleted
        ? NFCResult.success('Card payment completed successfully')
        : NFCResult.error('Card payment cancelled');
  }

  static Widget _infoRow(String label, String value, {bool isBold = false, Color? color}) {
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
}
