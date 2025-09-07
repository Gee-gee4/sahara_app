// lib/services/reprint_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/helpers/response_model.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class ReprintService {
  static Future<String?> get baseUrl async {
    final url = await apiUrl();
    if (url == null) return null;
    return '$url/api';
  }

  static Future<ResponseModel<Map<String, dynamic>?>> getReceiptForReprint({
    required String refNumber,
    required StaffListModel user,
  }) async {
    try {
      final deviceId = await getSavedOrFetchDeviceId();

      final base = await baseUrl; //fetch from SharedPreferences
      if (base == null) {
        return ResponseModel(isSuccessfull: false, message: 'Base URL not set in preferences', body: null);
      }

      final url = '$base/ReceiptRePrint/$refNumber/${user.staffId}/$deviceId';

      print('🔄 Fetching receipt for reprint...');
      print('📄 URL: $url');
      print('🆔 Ref Number: $refNumber');
      print('👤 Staff ID: ${user.staffId}');
      print('🏪 Terminal: $deviceId');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add authorization headers if needed
          // 'Authorization': 'Bearer $token',
        },
      );

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // ✅ Check error code
        if (responseData['error'] != null && responseData['error']['ErrorCode'] != 0) {
          final errorMsg = responseData['error']['ErrorMsg'] ?? 'Unknown error occurred';
          print('❌ API Error: $errorMsg');
          return ResponseModel(isSuccessfull: false, message: errorMsg, body: null);
        }

        // ✅ Success when ErrorCode == 0
        print('✅ Receipt data fetched successfully');
        return ResponseModel(isSuccessfull: true, message: 'Receipt data fetched successfully', body: responseData);
      } else if (response.statusCode == 404) {
        print('❌ Receipt not found');
        return ResponseModel(
          isSuccessfull: false,
          message: 'Receipt not found. Please check the reference number.',
          body: null,
        );
      } else {
        print('❌ Failed to fetch receipt: ${response.statusCode}');
        return ResponseModel(
          isSuccessfull: false,
          message: 'Failed to fetch receipt: ${response.statusCode}',
          body: null,
        );
      }
    } on SocketException catch (_) {
      print('❌ No Internet Connectivity for reprint');
      return ResponseModel(isSuccessfull: false, message: 'No Internet Connectivity', body: null);
    } catch (e) {
      print('❌ Error fetching receipt: $e');
      return ResponseModel(isSuccessfull: false, message: 'Error: ${e.toString()}', body: null);
    }
  }
}
