// lib/services/sale_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/models/product_card_details_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class SaleService {
  //  static Future<String?> get baseUrl async {
  //   final url = await apiUrl();
  //   if (url == null) {
  //     return null;
  //   }
  //   return '$url/api';
  // }
  static const String baseUrl = 'https://cmb.saharafcs.com/api';

  static Future<Map<String, dynamic>> completeSale({
    required String refNumber,
    required List<CartItem> cartItems,
    required StaffListModel user,
    required bool isCardSale,
    // Card sale specific
    String? customerName,
    String? customerUID,
    String? customerMask,
    int? customerId,
    int? customerAccountNo,
    double? customerAccountBalance,
    List<ProductCardDetailsModel>? accountProducts,
    // Cash sale specific
    double? cashGiven,
    double? change,
    // Payment mode details
    int? paymentModeId,
    String? paymentModeName,
  }) async {
    try {
      // Determine if we have card data (regardless of payment method)
      final hasCardData =
          customerUID != null && customerUID.isNotEmpty && customerAccountNo != null && customerAccountNo != 0;

      print("🎯 Sale analysis:");
      print("📋 Payment Type: ${isCardSale ? "CARD" : "CASH"}");
      print("💳 Has Card Data: $hasCardData");
      print("🆔 Card UID: $customerUID");
      print("🏦 Account No: $customerAccountNo");
      // Helper function to get client price for card sales
      double getClientPrice(CartItem item) {
        if (!isCardSale || accountProducts == null) {
          return item.price; // Use station price for cash sales or when no account products
        }

        final accountProduct = accountProducts.firstWhere(
          (p) => p.productVariationId == item.productId,
          orElse: () => ProductCardDetailsModel(
            productVariationId: 0,
            productVariationName: '',
            productCategoryId: 0,
            productCategoryName: '',
            productPrice: item.price, // Fallback to station price
            productDiscount: 0,
          ),
        );

        if (accountProduct.productVariationId != 0) {
          print("💰 Using client price for ${item.productName}: ${accountProduct.productPrice}");
          return accountProduct.productPrice;
        } else {
          print("💰 No client price found for ${item.productName}, using station price: ${item.price}");
          return item.price;
        }
      }

      // Helper function to get discount for card sales
      double getDiscount(CartItem item) {
        if (!isCardSale || accountProducts == null) {
          return 0.0; // No discount for cash sales
        }

        final accountProduct = accountProducts.firstWhere(
          (p) => p.productVariationId == item.productId,
          orElse: () => ProductCardDetailsModel(
            productVariationId: 0,
            productVariationName: '',
            productCategoryId: 0,
            productCategoryName: '',
            productPrice: 0,
            productDiscount: 0,
          ),
        );

        return accountProduct.productVariationId != 0 ? accountProduct.productDiscount : 0.0;
      }

      // Calculate total amount and total discount using appropriate pricing
      double totalAmount = 0;
      double totalDiscount = 0;

      for (var item in cartItems) {
        final price = getClientPrice(item);
        final discount = getDiscount(item);

        totalAmount += price * item.quantity;
        totalDiscount += discount * item.quantity;
      }

      // Calculate net total (amount after discount)
      final netTotal = totalAmount - totalDiscount;

      print("💰 Total amount (before discount): $totalAmount");
      print("💰 Total discount: $totalDiscount");
      print("💰 Net total (after discount): $netTotal");
      final deviceId = await getSavedOrFetchDeviceId();
      final saleData = {
        "terminalName": deviceId,
        "accountNo": hasCardData ? customerAccountNo : 0,
        "cardUID": hasCardData ? customerUID : "",
        "staffId": user.staffId,
        "customerVehicleId": 0,
        "driverId": 0,
        "driverCode": "",
        "reference": refNumber,
        "automationReferenceId": "",
        "odometerReading": 0,
        "transactionCode": refNumber,
        "transactionDate": DateTime.now().toIso8601String(), // Current timestamp
        "ticketLines": cartItems
            .map(
              (item) => {
                "productVariationId": item.productId,
                "productVariationName": item.productName,
                "productVariationPrice": getClientPrice(item), // Use client price
                "units": item.quantity,
                "totalMoneySold": getClientPrice(item) * item.quantity, // Use client price for total
                "productVariationDiscount": getDiscount(item) * item.quantity, // Apply discount
              },
            )
            .toList(),
        "paymentList": [
          {
            // Use the actual payment mode passed from the UI
            "paymentModeId": paymentModeId ?? (isCardSale ? 3 : 1), // Fallback to default if not provided
            "paymentModeName": paymentModeName ?? (isCardSale ? "Card" : "Cash"), // Fallback to default if not provided
            "totalPaid": isCardSale ? netTotal : (cashGiven ?? totalAmount), // Use NET TOTAL for card sales
            "totalUsed": isCardSale ? netTotal : totalAmount, // Use NET TOTAL for card sales
            "mpesaCode": "", // Only used for M-Pesa payments
            "mpesaMSISDN": "", // Only used for M-Pesa payments
          },
        ],
        "isOnline": true,
      };

      print('🚀 Sending sale data to API:');
      print('📋 Sale Type: ${isCardSale ? "CARD" : "CASH"}');
      print('💳 Account No: ${saleData["accountNo"]}');
      print('🆔 Card UID: ${saleData["cardUID"]}');
      // print('💰 Payment Mode: ${saleData["paymentList"][0]["paymentModeId"]} (${saleData["paymentList"][0]["paymentModeName"]})');
      print('🏪 Terminal: ${saleData["terminalName"]}');
      print('👤 Staff ID: ${saleData["staffId"]}');
      print('📄 Full JSON: ${jsonEncode(saleData)}');

      final endpoint = '$baseUrl/SellComplete';
print('🛒 Completing sale...');
print('🌐 URL: $endpoint');
print('📦 Payload: ${jsonEncode(saleData)}');


      final response = await http.post(
        Uri.parse('$baseUrl/SellComplete'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add authorization headers if needed
          // 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(saleData),
      );

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Sale completed successfully');
        return {'success': true, 'data': responseData};
      } else {
        print('❌ Sale completion failed: ${response.statusCode}');
        return {'success': false, 'error': 'Failed to complete sale: ${response.statusCode}', 'details': response.body};
      }
    } catch (e) {
      print('❌ Error completing sale: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
