// lib/services/reprint_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class ReprintService {
  static const String baseUrl = 'https://cmb.saharafcs.com/api';

  static Future<Map<String, dynamic>> getReceiptForReprint({
    required String refNumber,
    required StaffListModel user,
  }) async {
    try {
      final deviceId = await getSavedOrFetchDeviceId();
      final url = '$baseUrl/ReceiptRePrint/$refNumber/${user.staffId}/$deviceId';
      
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
        
        // Check if the response contains receipt data
        if (responseData != null) {
          print('✅ Receipt data fetched successfully');
          return {
            'success': true,
            'data': responseData,
          };
        } else {
          print('❌ No receipt data found');
          return {
            'success': false,
            'error': 'No receipt found with the provided reference number',
          };
        }
      } else if (response.statusCode == 404) {
        print('❌ Receipt not found');
        return {
          'success': false,
          'error': 'Receipt not found. Please check the reference number.',
        };
      } else {
        print('❌ Failed to fetch receipt: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Failed to fetch receipt: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('❌ Error fetching receipt: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}