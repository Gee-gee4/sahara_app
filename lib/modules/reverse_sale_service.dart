// lib/services/reverse_sale_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/helpers/ref_generator.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class ReverseSaleService {
  static const String baseUrl = 'https://cmb.saharafcs.com/api';

  static Future<Map<String, dynamic>> reverseTransaction({
    required String originalRefNumber,
    required StaffListModel user,
  }) async {
    try {
      // Generate new reference number for the reversal
      final newRefNumber = await RefGenerator.generate();
      final deviceId = await getSavedOrFetchDeviceId();
      
      final url = '$baseUrl/ReverseTransaction/$originalRefNumber/${user.staffId}/$deviceId/$newRefNumber';
      
      print('🔄 Reversing transaction...');
      print('📄 Original Ref: $originalRefNumber');
      print('🆕 New Ref: $newRefNumber');
      print('👤 Staff ID: ${user.staffId}');
      print('🏪 Terminal: $deviceId');
      print('🌐 URL: $url');

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
        
        // Check if the reversal was successful
        final error = responseData['error'];
        if (error != null && error['ErrorCode'] == 0) {
          print('✅ Transaction reversed successfully');
          return {
            'success': true,
            'data': responseData,
            'newRefNumber': newRefNumber,
            'originalRefNumber': originalRefNumber,
          };
        } else {
          final errorMsg = error?['ErrorMsg'] ?? 'Unknown error occurred';
          print('❌ Reversal failed: $errorMsg');
          return {
            'success': false,
            'error': errorMsg,
          };
        }
      } else if (response.statusCode == 404) {
        print('❌ Transaction not found');
        return {
          'success': false,
          'error': 'Transaction not found. Please check the reference number.',
        };
      } else {
        print('❌ Failed to reverse transaction: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Failed to reverse transaction: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('❌ Error reversing transaction: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}