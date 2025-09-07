// lib/services/topup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/helpers/ref_generator.dart';
import 'package:sahara_app/helpers/response_model.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopUpService {
  static Future<String?> get baseUrl async {
    final url = await apiUrl();
    if (url == null) return null;
    return '$url/api';
  }

  static Future<ResponseModel<Map<String, dynamic>?>> processTopUp({
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

      final base = await baseUrl;
      if (base == null) {
        return ResponseModel(isSuccessfull: false, message: 'Base URL not set in preferences', body: null);
      }

      final response = await http.post(
        Uri.parse('$base/TopUpTransaction'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
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
          return ResponseModel(
            isSuccessfull: true,
            message: 'Top-up processed successfully',
            body: {'data': responseData, 'refNumber': refNumber, 'amount': topUpAmount},
          );
        } else {
          final errorMsg = error['ErrorMsg'] ?? 'Top-up failed';
          print('❌ Top-up failed: $errorMsg');
          return ResponseModel(isSuccessfull: false, message: errorMsg, body: null);
        }
      } else {
        print('❌ Top-up failed: ${response.statusCode}');
        return ResponseModel(isSuccessfull: false, message: 'Top-up failed: ${response.statusCode}', body: null);
      }
    } on SocketException catch (_) {
      print('❌ No Internet Connectivity for top-up');
      return ResponseModel(isSuccessfull: false, message: 'No Internet Connectivity', body: null);
    } catch (e) {
      print('❌ Error processing top-up: $e');
      return ResponseModel(isSuccessfull: false, message: 'Error: ${e.toString()}', body: null);
    }
  }
}
