// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/response_model.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/customer_account_details_model.dart';

class CustomerAccountDetailsService {
  static Future<String?> get baseUrl async {
    final url = await apiUrl();
    if (url == null) {
      return null;
    }
    return '$url/api';
  }

  static Future<ResponseModel<CustomerAccountDetailsModel?>> fetchCustomerAccountDetails({
    required String accountNo,
    required String deviceId,
  }) async {
    final url = Uri.parse('${await baseUrl}/CustomerAccountDetails/$accountNo/$deviceId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ResponseModel(isSuccessfull: true, message: '', body: CustomerAccountDetailsModel.fromJson(data));
      } else {
        print('❌ Failed to fetch account details: ${response.statusCode}');
        return ResponseModel(isSuccessfull: false, message: response.body, body: null);
      }
    } on SocketException catch (_) {
      print('❌ No Internet Connectivity for sale completion');
      return ResponseModel(isSuccessfull: false, message: 'No Internet Connectivity', body: null);
    } catch (e) {
      print('❌ Error fetching customer account details: $e');
      return ResponseModel(isSuccessfull: false, message: e.toString(), body: null);
    }
  }
}
