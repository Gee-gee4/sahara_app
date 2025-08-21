// lib/services/reverse_topup_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/helpers/ref_generator.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class ReverseTopUpService {
  static Future<String?> get baseUrl async {
    final url = await apiUrl(); // already implemented
    if (url == null) return null;
    return '$url/api';
  }

  static Future<Map<String, dynamic>> reverseTopUp({
    required String originalRefNumber,
    required StaffListModel user,
  }) async {
    try {
      final newRefNumber = await RefGenerator.generate();
      final deviceId = await getSavedOrFetchDeviceId();
      final base = await baseUrl;

      if (base == null) {
        return {'success': false, 'error': 'Base URL not set in preferences'};
      }

      final url = '$base/ReverseTopupTransaction/$originalRefNumber/${user.staffId}/$deviceId/$newRefNumber';

      print('🔄 Reversing top-up...');
      print('📄 Original Ref: $originalRefNumber');
      print('🆕 New Ref: $newRefNumber');
      print('👤 Staff ID: ${user.staffId}');
      print('🏪 Terminal: $deviceId');
      print('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );

      print('📡 API Status: ${response.statusCode}');
      print('📡 API Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final error = responseData['error'];
        if (error != null && error['ErrorCode'] == 0) {
          print('✅ Reverse top-up successful');
          return {
            'success': true,
            'data': responseData,
            'newRefNumber': newRefNumber,
            'originalRefNumber': originalRefNumber,
          };
        } else {
          final errorMsg = error?['ErrorMsg'] ?? 'Failed! Check if the receipt Id is correct';
          print('❌ Reverse top-up failed: $errorMsg');
          return {'success': false, 'error': errorMsg};
        }
      } else {
        return {
          'success': false,
          'error': 'Failed: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('❌ Network error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
