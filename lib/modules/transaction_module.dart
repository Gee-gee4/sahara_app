// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/transaction_model.dart';
import 'package:sahara_app/modules/auth_module.dart';
import 'package:sahara_app/utils/configs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionModule {
  final AuthModule _authModule = AuthModule();

  // ✅ Basic Authorization method
  String get basicAuthorization {
    final base64E = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));
    return 'Basic $base64E';
  }

  /// Fetches transactions for a specific pump
  Future<List<TransactionModel>> fetchTransactions(String pumpId) async {
    List<TransactionModel> items = [];

    try {
      final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      
      // ✅ Force update baseTatsUrl
      final savedUrl = sharedPreferences.getString(urlKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        baseTatsUrl = savedUrl;
      }
      
      String stationName = (sharedPreferences.getString(stationNameKey) ?? '').trim();
      String durationStr = sharedPreferences.getString(durationKey) ?? '30';
      int duration = int.tryParse(durationStr) ?? 30;

      DateTime toDate = DateTime.now();
      DateTime fromDate = toDate.subtract(Duration(minutes: duration));

      // ✅ Use Basic Auth (not Bearer token)
      Map<String, String> headers = {
        'Content-type': 'application/json',
        'authorization': basicAuthorization,
      };

      // ✅ Use the working fdcName format
      final url = '$baseTatsUrl/v2/transactions?fdcName=$stationName&pumpAddress=$pumpId&fromDate=${fromDate.toIso8601String()}&toDate=${toDate.toIso8601String()}';

      final res = await http.get(Uri.parse(url), headers: headers);

      if (res.statusCode == 200) {
        List<Map> rawTransactions = List<Map>.from(json.decode(res.body) ?? []);
        items = rawTransactions.map((transaction) => TransactionModel(
          transactionId: transaction['id']?.toString(),
          nozzle: transaction['nozzle'].toString(),
          productName: transaction['productName'].toString(),
          productId: transaction['productId']?.toString(),
          price: double.tryParse(transaction['price'].toString()) ?? 0,
          volume: double.tryParse(transaction['volume'].toString()) ?? 0,
          totalAmount: double.tryParse(transaction['amount'].toString()) ?? 0,
          dateTimeSold: transaction['dateTime'],
        )).toList();
      }
    } catch (_) {}

    return items;
  }

  /// Fetches transactions for all pumps
  Future<List<TransactionModel>> fetchAllTransactions() async {
    List<TransactionModel> allItems = [];

    try {
      final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      
      // ✅ Force update baseTatsUrl
      final savedUrl = sharedPreferences.getString(urlKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        baseTatsUrl = savedUrl;
      }
      
      String stationName = (sharedPreferences.getString(stationNameKey) ?? '').trim();
      String durationStr = sharedPreferences.getString(durationKey) ?? '30';
      int duration = int.tryParse(durationStr) ?? 30;

      DateTime toDate = DateTime.now();
      DateTime fromDate = toDate.subtract(Duration(minutes: duration));

      // ✅ Use Bearer token for fetching pumps
      String token = await _authModule.fetchToken();
      Map<String, String> pumpHeaders = {
        'Content-type': 'application/json',
        'authorization': 'Bearer $token',
      };

      // ✅ Use Basic Auth for transactions
      Map<String, String> transactionHeaders = {
        'Content-type': 'application/json',
        'authorization': basicAuthorization,
      };

      // fetch all pumps first
      final resPumps = await http.get(
        Uri.parse(fetchPumpsUrl(stationName)),
        headers: pumpHeaders,
      );

      if (resPumps.statusCode == 200) {
        Map pumpBody = json.decode(resPumps.body);
        List<Map> pumps = List<Map>.from(pumpBody['pumps'] ?? []);

        for (var pump in pumps) {
          final pumpId = pump['rdgIndex'];

          // ✅ Use the working fdcName format
          final url = '$baseTatsUrl/v2/transactions?fdcName=$stationName&pumpAddress=$pumpId&fromDate=${fromDate.toIso8601String()}&toDate=${toDate.toIso8601String()}';

          final res = await http.get(
            Uri.parse(url),
            headers: transactionHeaders,
          );

          if (res.statusCode == 200) {
            List<Map> rawTransactions = List<Map>.from(json.decode(res.body) ?? []);
            final items = rawTransactions.map((transaction) => TransactionModel(
              transactionId: transaction['id']?.toString(),
              nozzle: transaction['nozzle'].toString(),
              productName: transaction['productName'].toString(),
              productId: transaction['productId']?.toString(),
              price: double.tryParse(transaction['price'].toString()) ?? 0,
              volume: double.tryParse(transaction['volume'].toString()) ?? 0,
              totalAmount: double.tryParse(transaction['amount'].toString()) ?? 0,
              dateTimeSold: transaction['dateTime'],
            )).toList();

            allItems.addAll(items);
          }
        }
      }
    } catch (e) {
      print('Error fetching all transactions: $e');
    }

    return allItems;
  }

  /// Posts a list of transactions
  Future postTransaction({
    required List<CartItem> cartItemTrans,
    String? taxPayerName,
    String? tin,
    String? phoneNumber,
  }) async {
    try {
      // ✅ Use Basic Auth for posting transactions
      Map<String, String> headers = {
        'Content-type': 'application/json',
        'authorization': basicAuthorization,
      };

      final res = await http.put(
        Uri.parse(postTransactionUrl()),
        headers: headers,
        body: json.encode({
          "buyerName": taxPayerName,
          "buyerTIN": tin,
          "buyerPhone": phoneNumber,
          'items': cartItemTrans.map((cartItem) {
            return {
              'transactionId': cartItem.uniqueId,
              'code': cartItem.productId,
              'name': cartItem.productName,
              'quantity': cartItem.quantity,
              'price': cartItem.price,
              'amount': cartItem.totalAmount,
            };
          }).toList(),
        }),
      );

      print(res.statusCode);
      print(res.body);

      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (e) {
      print(e);
    }
  }
}