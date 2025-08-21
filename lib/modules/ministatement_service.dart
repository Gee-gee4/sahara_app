// lib/services/mini_statement_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/customer_account_details_model.dart';
import 'package:sahara_app/models/ministatment_transaction_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class MiniStatementService {
  
  static Future<String?> get baseUrl async {
    final url = await apiUrl(); // this is the function you already wrote
    if (url == null) return null;
    return '$url/api';
  }

  static Future<Map<String, dynamic>> fetchMiniStatement({
    required String accountNumber,
    required StaffListModel user,
  }) async {
    try {
      final deviceId = await getSavedOrFetchDeviceId();

      final base = await baseUrl; // 👈 fetch from SharedPreferences
      if (base == null) {
        return {'success': false, 'error': 'Base URL not set in preferences'};
      }

      final url = '$base/CustomerMiniStatements/$accountNumber/$deviceId/${user.staffId}';
      print('💳 Fetching mini statement...');
      print('🏦 Account: $accountNumber');
      print('👤 Staff ID: ${user.staffId}');
      print('🏪 Terminal: $deviceId');
      print('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if there's an error in the response
        final error = responseData['error'];
        if (error != null && error['ErrorCode'] == 0) {
          // Parse customer account details
          final customerAccount = responseData['customerAccount'];
          final CustomerAccountDetailsModel accountDetails = CustomerAccountDetailsModel.fromJson(customerAccount);

          // Parse transactions
          final transactionList = responseData['transaction'] as List? ?? [];
          final List<MinistatmentTransactionModel> transactions = transactionList
              .map((transaction) => MinistatmentTransactionModel.fromJson(transaction))
              .toList();

          print('✅ Mini statement fetched successfully');
          print('📊 Found ${transactions.length} transactions');

          return {'success': true, 'accountDetails': accountDetails, 'transactions': transactions};
        } else {
          final errorMsg = error?['ErrorMsg'] ?? 'Unknown error occurred';
          print('❌ Mini statement failed: $errorMsg');
          return {'success': false, 'error': errorMsg};
        }
      } else if (response.statusCode == 404) {
        print('❌ Account not found');
        return {'success': false, 'error': 'Account not found. Please check the account number.'};
      } else {
        print('❌ Failed to fetch mini statement: ${response.statusCode}');
        return {'success': false, 'error': 'Failed to fetch mini statement: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Error fetching mini statement: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
