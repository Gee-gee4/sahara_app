// lib/services/reprint_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class ReprintService {
  static Future<String?> get baseUrl async {
    final url = await apiUrl(); // this is the function you already wrote
    if (url == null) return null;
    return '$url/api';
  }

  static Future<Map<String, dynamic>> getReceiptForReprint({
    required String refNumber,
    required StaffListModel user,
  }) async {
    try {
      final deviceId = await getSavedOrFetchDeviceId();

      final base = await baseUrl; // 👈 fetch from SharedPreferences
      if (base == null) {
        return {'success': false, 'error': 'Base URL not set in preferences'};
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
          print('❌ API Error: ${responseData['error']['ErrorMsg']}');
          return {'success': false, 'error': responseData['error']['ErrorMsg'] ?? 'Unknown error occurred'};
        }

        // ✅ Success when ErrorCode == 0
        print('✅ Receipt data fetched successfully');
        return {'success': true, 'data': responseData};
      } else if (response.statusCode == 404) {
        print('❌ Receipt not found');
        return {'success': false, 'error': 'Receipt not found. Please check the reference number.'};
      } else {
        print('❌ Failed to fetch receipt: ${response.statusCode}');
        return {'success': false, 'error': 'Failed to fetch receipt: ${response.statusCode}', 'details': response.body};
      }
    } catch (e) {
      print('❌ Error fetching receipt: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
