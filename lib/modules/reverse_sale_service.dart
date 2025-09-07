// lib/services/reverse_sale_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sahara_app/helpers/device_id_helper.dart';
import 'package:sahara_app/helpers/ref_generator.dart';
import 'package:sahara_app/helpers/response_model.dart';
import 'package:sahara_app/helpers/shared_prefs_helper.dart';
import 'package:sahara_app/models/staff_list_model.dart';

class ReverseSaleService {
  static Future<String?> get baseUrl async {
    final url = await apiUrl();
    if (url == null) return null;
    return '$url/api';
  }

  static Future<ResponseModel<Map<String, dynamic>?>> reverseTransaction({
    required String originalRefNumber,
    required StaffListModel user,
  }) async {
    try {
      // Generate new reference number for the reversal
      final newRefNumber = await RefGenerator.generate();
      final deviceId = await getSavedOrFetchDeviceId();
      final base = await baseUrl; //fetch from SharedPreferences
      if (base == null) {
        return ResponseModel(isSuccessfull: false, message: 'Base URL not set in preferences', body: null);
      }

      final url = '$base/ReverseTransaction/$originalRefNumber/${user.staffId}/$deviceId/$newRefNumber';

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
          return ResponseModel(
            isSuccessfull: true,
            message: 'Transaction reversed successfully',
            body: {'data': responseData, 'newRefNumber': newRefNumber, 'originalRefNumber': originalRefNumber},
          );
        } else {
          final errorMsg = error?['ErrorMsg'] ?? 'Unknown error occurred';
          print('❌ Reversal failed: $errorMsg');
          return ResponseModel(isSuccessfull: false, message: errorMsg, body: null);
        }
      } else if (response.statusCode == 404) {
        print('❌ Transaction not found');
        return ResponseModel(
          isSuccessfull: false,
          message: 'Transaction not found. Please check the reference number.',
          body: null,
        );
      } else {
        print('❌ Failed to reverse transaction: ${response.statusCode}');
        return ResponseModel(
          isSuccessfull: false,
          message: 'Failed to reverse transaction: ${response.statusCode}',
          body: null,
        );
      }
    } on SocketException catch (_) {
      print('❌ No Internet Connectivity for reverse transaction');
      return ResponseModel(isSuccessfull: false, message: 'No Internet Connectivity', body: null);
    } catch (e) {
      print('❌ Error reversing transaction: $e');
      return ResponseModel(isSuccessfull: false, message: 'Error: ${e.toString()}', body: null);
    }
  }
}
