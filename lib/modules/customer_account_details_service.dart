// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sahara_app/models/customer_account_details_model.dart';

class CustomerAccountDetailsService {
 static Future<CustomerAccountDetailsModel?> fetchCustomerAccountDetails({
    required String accountNo,
    required String deviceId,
  }) async {
    final url = Uri.parse('https://cmb.saharafcs.com/api/CustomerAccountDetails/$accountNo/$deviceId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CustomerAccountDetailsModel.fromJson(data);
      } else {
        print('❌ Failed to fetch account details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching customer account details: $e');
      return null;
    }
  }
}