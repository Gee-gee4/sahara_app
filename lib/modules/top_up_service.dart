// lib/services/topup_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/helpers/ref_generator.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopUpService {
  static const String baseUrl = 'https://cmb.saharafcs.com/api';

  static Future<Map<String, dynamic>> processTopUp({
    required String accountNo,
    required double topUpAmount,
    required StaffListModel user,
  }) async {
    try {
      final deviceId = await getSavedOrFetchDeviceId();
      final prefs = await SharedPreferences.getInstance();
      final channelId = prefs.getInt('channelId') ?? 0; // Get station/channel ID
      final refNumber = await RefGenerator.generate();
      
      final topUpData = {
        "accountNo": int.tryParse(accountNo) ?? 0,
        "terminalName": deviceId,
        "topUpAmount": topUpAmount,
        "stationId": channelId,
        "staffId": user.staffId,
        "createdBy": user.staffId, // Use staff ID as created by
        "transactionCode": refNumber,
        "transactionDate": DateTime.now().toIso8601String(),
        "receiptNo": refNumber, // Use ref number as receipt number
        "isOnline": true,
        "parentId": 0,
        "topUpType": "Cash", // Default to Cash for now
        "topUpPlatform": "POS", // Platform identifier
        "topUpDesc": "Account Top-up", // Description
        "topUpRef": refNumber, // Reference number
      };

      print('💰 Processing top-up...');
      print('🏦 Account: $accountNo');
      print('💵 Amount: $topUpAmount');
      print('👤 Staff: ${user.staffName} (${user.staffId})');
      print('🏪 Terminal: $deviceId');
      print('🆔 Ref: $refNumber');
      print('📄 Full JSON: ${jsonEncode(topUpData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/TopUpTransaction'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(topUpData),
      );

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Check if there's an error in the response
        final error = responseData['error'];
        if (error == null || error['ErrorCode'] == 0) {
          print('✅ Top-up processed successfully');
          return {
            'success': true,
            'data': responseData,
            'refNumber': refNumber,
            'amount': topUpAmount,
          };
        } else {
          final errorMsg = error['ErrorMsg'] ?? 'Top-up failed';
          print('❌ Top-up failed: $errorMsg');
          return {
            'success': false,
            'error': errorMsg,
          };
        }
      } else {
        print('❌ Top-up failed: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Top-up failed: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('❌ Error processing top-up: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}